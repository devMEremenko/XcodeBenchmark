/*
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import Security
// Ensure that we import the correct dependency for both SPM and CocoaPods since
// the latter doesn't define separate Clang modules for subspecs
#if SWIFT_PACKAGE
import AppAuthCore
import GTMSessionFetcherCore
#else
import AppAuth
import GTMSessionFetcher
#endif

/// A helper providing a concrete implementation for saving and loading auth data to the keychain.
@objc(GTMKeychainStore)
public final class KeychainStore: NSObject, AuthSessionStore {
  /// The helper wrapping keychain access.
  @objc public let keychainHelper: KeychainHelper
  /// The last used `NSKeyedArchiver` used in tests to ensure that the class name mapping worked.
  private(set) var lastUsedKeyedArchiver: NSKeyedArchiver?
  /// The last used `NSKeyedUnarchiver` used in tests to ensure that the class name mapping worked.
  private(set) var lastUsedKeyedUnarchiver: NSKeyedUnarchiver?
  /// The name for the item to save in, retrieve, or remove from the keychain.
  @objc public var itemName: String
  /// Attributes that configure the behavior of the keychain.
  @objc public var keychainAttributes: Set<KeychainAttribute>

  /// An initializer for testing to create an instance of this keychain wrapper with a given helper.
  ///
  /// - Parameters:
  ///   - itemName: The `String` name for the credential to store in the keychain.
  ///   - keychainAttributes: A `Set` of `KeychainAttribute` to use with the keychain.
  @objc public convenience init(
    itemName: String,
    keychainAttributes: Set<KeychainAttribute>
  ) {
    let keychain = KeychainWrapper(keychainAttributes: keychainAttributes)
    self.init(
      itemName: itemName,
      keychainAttributes: keychainAttributes,
      keychainHelper: keychain
    )
  }

  /// An initializer for testing to create an instance of this keychain wrapper with a given helper.
  ///
  /// - Parameters:
  ///   - itemName: The `String` name for the credential to store in the keychain.
  ///   - keychainHelper: An instance conforming to `KeychainHelper`.
  /// - Note: The `KeychainHelper`'s `keychainAttributes` are used if present.
  @objc public convenience init(itemName: String, keychainHelper: KeychainHelper) {
    self.init(
      itemName: itemName,
      keychainAttributes: keychainHelper.keychainAttributes,
      keychainHelper: keychainHelper
    )
  }

  /// An initializer for testing to create an instance of this keychain wrapper with a given helper.
  ///
  /// - Parameters:
  ///   - itemName: The `String` name for the credential to store in the keychain.
  ///   - keychainAttributes: A `Set` of `KeychainAttribute` to use with the keychain.
  ///   - keychainHelper: An instance conforming to `KeychainHelper`.
  @objc public init(
    itemName: String,
    keychainAttributes: Set<KeychainAttribute>,
    keychainHelper: KeychainHelper
  ) {
    self.itemName = itemName
    self.keychainAttributes = keychainAttributes
    self.keychainHelper = keychainHelper

    super.init()
  }

  // MARK: - AuthSessionStore Conformance

  /// An initializer for to create an instance of this keychain wrapper.
  ///
  /// - Parameters:
  ///   - itemName: The `String` name for the credential to store in the keychain.
  @objc public convenience init(itemName: String) {
    self.init(itemName: itemName, keychainHelper: KeychainWrapper())
  }

  @objc(saveAuthSession:error:)
  public func save(authSession: AuthSession) throws {
    try save(authSession: authSession, withItemName: itemName)
  }

  /// Saves the provided `AuthSession` using the provided item name.
  ///
  /// - Parameters:
  ///   - authSession: An instance of `AuthSession` to save.
  ///   - itemName: A `String` name to use for the save that is different than the name given during
  ///     initialization.
  /// - Throws: Any error that may arise during the save.
  @objc(saveAuthSession:withItemName:error:)
  public func save(authSession: AuthSession, withItemName itemName: String) throws {
    let authSessionData = try authSessionData(fromAuthSession: authSession)

    var maybeAccessibility: CFString? = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
    // On macOS, we must use `kSecUseDataProtectionKeychain` if using `kSecAttrAccessible`
    // (https://developer.apple.com/documentation/security/ksecattraccessible?language=objc)
#if os(macOS)
      if !keychainAttributes.contains(.useDataProtectionKeychain) {
        maybeAccessibility = nil
      }
#endif
    }

    try keychainHelper.setPassword(
      data: authSessionData,
      forService: itemName,
      accessibility: maybeAccessibility
    )
  }

  private func authSessionData(
    fromAuthSession authSession: AuthSession
  ) throws -> Data {
    let keyedArchiver: NSKeyedArchiver
    if #available(iOS 11, macOS 10.13, tvOS 11.0, watchOS 4.0, *) {
      keyedArchiver = NSKeyedArchiver(requiringSecureCoding: true)
    } else {
      keyedArchiver = NSKeyedArchiver()
    }

    // The previous name for `AuthSession` was `GTMAppAuthFetcherAuthorization`. To allow legacy
    // versions of this library to unarchive and archive instances of `AuthSession` from new
    // versions of this library, we will archive `AuthSession` using the legacy name.
    keyedArchiver.setClassName(AuthSession.legacyArchiveName, for: AuthSession.self)
    lastUsedKeyedArchiver = keyedArchiver

    keyedArchiver.encode(authSession, forKey: NSKeyedArchiveRootObjectKey)
    keyedArchiver.finishEncoding()
    return keyedArchiver.encodedData
  }

  /// Removes the stored `AuthSession` matching the provided item name.
  ///
  /// - Parameters:
  ///   - itemName: A `String` name to use for the removal different than what was given during
  ///     initialization.
  /// - Throws: Any error that may arise during the removal.
  @objc public func removeAuthSession(withItemName itemName: String) throws {
    try keychainHelper.removePassword(forService: itemName)
  }

  @objc public func removeAuthSession() throws {
    try keychainHelper.removePassword(forService: itemName)
  }

  private func keyedUnarchiver(forData data: Data) throws -> NSKeyedUnarchiver {
    let keyedUnarchiver: NSKeyedUnarchiver
    if #available(iOS 11.0, macOS 10.13, watchOS 4.0, tvOS 11.0, *) {
      keyedUnarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
      keyedUnarchiver.requiresSecureCoding = true
    } else {
      keyedUnarchiver = NSKeyedUnarchiver(forReadingWith: data)
      keyedUnarchiver.requiresSecureCoding = false
    }
    // The previous name for `AuthSession` was `GTMAppAuthFetcherAuthorization` and so unarchiving
    // requires mapping the name previous instances were archived under to the new name.
    keyedUnarchiver.setClass(AuthSession.self, forClassName: AuthSession.legacyArchiveName)
    lastUsedKeyedUnarchiver = keyedUnarchiver

    return keyedUnarchiver
  }

  /// Retrieves the stored `AuthSession` matching the provided item name.
  ///
  /// - Parameters:
  ///   - itemName: A `String` name for the item to retrieve different than what was given during
  ///     initialization.
  /// - Throws: Any error that may arise during the retrieval.
  @objc public func retrieveAuthSession(withItemName itemName: String) throws -> AuthSession {
    let passwordData = try keychainHelper.passwordData(forService: itemName)

    let keyedUnarchiver = try keyedUnarchiver(forData: passwordData)
    guard let auth = keyedUnarchiver.decodeObject(
      of: AuthSession.self,
      forKey: NSKeyedArchiveRootObjectKey
    ) else {
      throw Error.failedToConvertKeychainDataToAuthSession(itemName: itemName)
    }
    return auth
  }

  @objc public func retrieveAuthSession() throws -> AuthSession {
    let passwordData = try keychainHelper.passwordData(forService: itemName)

    let keyedUnarchiver = try keyedUnarchiver(forData: passwordData)
    guard let auth = keyedUnarchiver.decodeObject(
      of: AuthSession.self,
      forKey: NSKeyedArchiveRootObjectKey
    ) else {
      throw Error.failedToConvertKeychainDataToAuthSession(itemName: itemName)
    }
    return auth
  }

  /// Attempts to create an `AuthSession` from stored data in GTMOAuth2 format.
  ///
  /// - Parameters:
  ///   - tokenURL: The OAuth token endpoint URL.
  ///   - redirectURI: The OAuth redirect URI used when obtaining the original authorization.
  ///   - clientID: The OAuth client ID.
  ///   - clientSecret: The OAuth client secret.
  /// - Returns: An `AuthSession` object.
  /// - Throws: Any error arising from the `AuthSession` creation.
  @objc public func retrieveAuthSessionInGTMOAuth2Format(
    tokenURL: URL,
    redirectURI: String,
    clientID: String,
    clientSecret: String?
  ) throws -> AuthSession {
    let password = try keychainHelper.password(forService: itemName)
    let authSession = try GTMOAuth2Compatibility.authSession(
      forPersistenceString: password,
      tokenURL: tokenURL,
      redirectURI: redirectURI,
      clientID: clientID,
      clientSecret: clientSecret
    )
    return authSession
  }

  /// Attempts to create a `AuthSession` from data stored in a GTMOAuth2 format.
  ///
  /// Uses Google OAuth provider information.
  ///
  /// - Parameters:
  ///   - clientID: The OAuth client id.
  ///   - clientSecret: The OAuth client secret.
  /// - Returns: An `AuthSession` object, or nil.
  /// - Throws: Any error arising from the `AuthSession` creation.
  @objc public func retrieveAuthSessionForGoogleInGTMOAuth2Format(
    clientID: String,
    clientSecret: String
  ) throws -> AuthSession {
    return try retrieveAuthSessionInGTMOAuth2Format(
      tokenURL: GTMOAuth2Compatibility.googleTokenURL,
      redirectURI: GTMOAuth2Compatibility.nativeClientRedirectURI,
      clientID: clientID,
      clientSecret: clientSecret
    )
  }

  /// Saves the `AuthSession` in a GTMOAuth2 compatible manner.
  ///
  /// - Parameters:
  ///   - authSession: The `AuthSession` to save.
  /// - Throws: Any error that may arise during the retrieval.
  @objc public func saveWithGTMOAuth2Format(
    forAuthSession authSession: AuthSession
  ) throws {
    guard let persistence = GTMOAuth2Compatibility
        .persistenceResponseString(forAuthSession: authSession) else {
      throw KeychainStore.Error.failedToCreateResponseStringFromAuthSession(authSession)
    }

    if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
    // On macOS, we must use `kSecUseDataProtectionKeychain` if using `kSecAttrAccessible`
    // (https://developer.apple.com/documentation/security/ksecattraccessible?language=objc)
#if os(macOS)
      if !keychainAttributes.contains(.useDataProtectionKeychain) {
        try keychainHelper.setPassword(persistence, forService: itemName)
        return
      }
#endif
    }

    try keychainHelper.setPassword(
      persistence,
      forService: itemName,
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
  }
}

// MARK: - Keychain Errors

public extension KeychainStore {
  /// Errors that may arise while saving, reading, and removing passwords from the Keychain.
  enum Error: Swift.Error, Equatable, CustomNSError {
    case unhandled(status: OSStatus)
    case passwordNotFound(forItemName: String)
    /// Error thrown when there is no name for the item in the keychain.
    case noService
    case unexpectedPasswordData(forItemName: String)
    case failedToCreateResponseStringFromAuthSession(AuthSession)
    case failedToConvertRedirectURItoURL(String)
    case failedToConvertAuthSessionToData
    case failedToConvertKeychainDataToAuthSession(itemName: String)
    case failedToDeletePassword(forItemName: String)
    case failedToDeletePasswordBecauseItemNotFound(itemName: String)
    case failedToSetPassword(forItemName: String)

    public static var errorDomain: String {
      "GTMAppAuthKeychainErrorDomain"
    }

    public var errorUserInfo: [String : Any] {
      switch self {
      case .unhandled(status: let status):
        return ["status": status]
      case .passwordNotFound(let itemName):
        return ["itemName": itemName]
      case .noService:
        return [:]
      case .unexpectedPasswordData(let itemName):
        return ["itemName": itemName]
      case .failedToCreateResponseStringFromAuthSession(let authSession):
        return ["authSession": authSession]
      case .failedToConvertRedirectURItoURL(let redirectURI):
        return ["redirectURI": redirectURI]
      case .failedToConvertAuthSessionToData:
        return [:]
      case .failedToConvertKeychainDataToAuthSession(itemName: let itemName):
        return ["itemName": itemName]
      case .failedToDeletePassword(let itemName):
        return ["itemName": itemName]
      case .failedToDeletePasswordBecauseItemNotFound(itemName: let itemName):
        return ["itemName": itemName]
      case .failedToSetPassword(forItemName: let itemName):
        return ["itemName": itemName]
      }
    }

    public var errorCode: Int {
      return ErrorCode(keychainStoreError: self).rawValue
    }
  }

  /// Error codes associated with cases from `KeychainStore.Error`.
  ///
  /// The cases for this enumeration are backed by integer raw values and are used to fill out the
  /// `errorCode` for the `NSError` representation of `KeychainStore.Error`.
  @objc(GTMKeychainStoreErrorCode)
  enum ErrorCode: Int {
    case unhandled
    case passwordNotFound
    case noService
    case unexpectedPasswordData
    case failedToCreateResponseStringFromAuthSession
    case failedToConvertRedirectURItoURL
    case failedToConvertAuthSessionToData
    case failedToConvertKeychainDataToAuthSession
    case failedToDeletePassword
    case failedToDeletePasswordBecauseItemNotFound
    case failedToSetPassword

    init(keychainStoreError: KeychainStore.Error) {
      switch keychainStoreError {
      case .unhandled:
        self = .unhandled
      case .passwordNotFound:
        self = .passwordNotFound
      case .noService:
        self = .noService
      case .unexpectedPasswordData:
        self = .unexpectedPasswordData
      case .failedToCreateResponseStringFromAuthSession:
        self = .failedToCreateResponseStringFromAuthSession
      case .failedToConvertRedirectURItoURL:
        self = .failedToConvertRedirectURItoURL
      case .failedToConvertAuthSessionToData:
        self = .failedToConvertAuthSessionToData
      case .failedToConvertKeychainDataToAuthSession:
        self = .failedToConvertKeychainDataToAuthSession
      case .failedToDeletePassword:
        self = .failedToDeletePassword
      case .failedToDeletePasswordBecauseItemNotFound:
        self = .failedToDeletePasswordBecauseItemNotFound
      case .failedToSetPassword:
        self = .failedToSetPassword
      }
    }
  }
}


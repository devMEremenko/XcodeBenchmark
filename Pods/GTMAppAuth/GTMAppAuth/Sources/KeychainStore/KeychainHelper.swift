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

/// A protocol defining the helper API for interacting with the Keychain.
@objc(GTMKeychainHelper)
public protocol KeychainHelper {
  var accountName: String { get }
  var keychainAttributes: Set<KeychainAttribute> { get }
  init(keychainAttributes: Set<KeychainAttribute>)
  func keychainQuery(forService service: String) -> [String: Any]
  func password(forService service: String) throws -> String
  func passwordData(forService service: String) throws -> Data
  func removePassword(forService service: String) throws
  func setPassword(_ password: String, forService service: String) throws
  func setPassword(_ password: String, forService service: String, accessibility: CFTypeRef) throws
  func setPassword(data: Data, forService service: String, accessibility: CFTypeRef?) throws
}

/// An internally scoped keychain helper.
final class KeychainWrapper: KeychainHelper {
  let accountName = "OAuth"
  let keychainAttributes: Set<KeychainAttribute>

  init(keychainAttributes: Set<KeychainAttribute> = []) {
    self.keychainAttributes = keychainAttributes
  }

  func keychainQuery(forService service: String) -> [String: Any] {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String : accountName,
      kSecAttrService as String: service,
    ]

    keychainAttributes.forEach { configuration in
      switch configuration.attribute {
      case .useDataProtectionKeychain:
        query[configuration.attribute.keyName] = kCFBooleanTrue
      case .accessGroup(let name):
        query[configuration.attribute.keyName] = name
      }
    }

    return query
  }

  func password(forService service: String) throws -> String {
    let passwordData = try passwordData(forService: service)
    guard let result = String(data: passwordData, encoding: .utf8) else {
      throw KeychainStore.Error.unexpectedPasswordData(forItemName: service)
    }
    return result
  }

  func passwordData(forService service: String) throws -> Data {
    guard !service.isEmpty else { throw KeychainStore.Error.noService }

    var passwordItem: AnyObject?
    var keychainQuery = keychainQuery(forService: service)
    keychainQuery[kSecReturnData as String] = true
    keychainQuery[kSecMatchLimit as String] = kSecMatchLimitOne
    let status = SecItemCopyMatching(keychainQuery as CFDictionary, &passwordItem)

    guard status != errSecItemNotFound else {
      throw KeychainStore.Error.passwordNotFound(forItemName: service)
    }

    guard status == errSecSuccess else { throw KeychainStore.Error.unhandled(status: status) }

    guard let result = passwordItem as? Data else {
      throw KeychainStore.Error.unexpectedPasswordData(forItemName: service)
    }

    return result
  }

  func removePassword(forService service: String) throws {
    guard !service.isEmpty else { throw KeychainStore.Error.noService }
    let keychainQuery = keychainQuery(forService: service)
    let status = SecItemDelete(keychainQuery as CFDictionary)

    guard status != errSecItemNotFound else {
      throw KeychainStore.Error.failedToDeletePasswordBecauseItemNotFound(itemName: service)
    }
    guard status == noErr else {
      throw KeychainStore.Error.failedToDeletePassword(forItemName: service)
    }
  }
  
  func setPassword(_ password: String, forService service: String) throws {
    let passwordData = Data(password.utf8)
    try setPassword(data: passwordData, forService: service, accessibility: nil)
  }

  func setPassword(
    _ password: String,
    forService service: String,
    accessibility: CFTypeRef
  ) throws {
    let passwordData = Data(password.utf8)
    try setPassword(data: passwordData, forService: service, accessibility: accessibility)
  }

  func setPassword(data: Data, forService service: String, accessibility: CFTypeRef?) throws {
    guard !service.isEmpty else { throw KeychainStore.Error.noService }
    do {
      try removePassword(forService: service)
    } catch KeychainStore.Error.failedToDeletePasswordBecauseItemNotFound {
      // Don't throw; password doesn't exist since the password is being saved for the first time
    } catch {
      // throw here since this is some other error
      throw error
    }
    guard !data.isEmpty else { return }
    var keychainQuery = keychainQuery(forService: service)
    keychainQuery[kSecValueData as String] = data

    if let accessibility = accessibility {
      keychainQuery[kSecAttrAccessible as String] = accessibility
    }

    let status = SecItemAdd(keychainQuery as CFDictionary, nil)
    guard status == noErr else {
      throw KeychainStore.Error.failedToSetPassword(forItemName: service)
    }
  }
}

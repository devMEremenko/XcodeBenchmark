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
// Ensure that we import the correct dependency for both SPM and CocoaPods since
// the latter doesn't define separate Clang modules for subspecs
#if SWIFT_PACKAGE
import AppAuthCore
import GTMSessionFetcherCore
#else
import AppAuth
import GTMSessionFetcher
#endif

// Standard OAuth keys
let oauth2AccessTokenKey = "access_token"
let oauth2RefreshTokenKey = "refresh_token"
let oauth2ScopeKey = "scope"
let oauth2ErrorKey = "error"
let oauth2TokenTypeKey = "token_type"
let oauth2ExpiresInKey = "expires_in"
let oauth2CodeKey = "code"
let oauth2AssertionKey = "assertion"
let oauth2RefreshScopeKey = "refreshScope"

// URI indicating an installed app is signing in. This is described at
//
// https://developers.google.com/identity/protocols/OAuth2InstalledApp#formingtheurl
//
let oobString = "urn:ietf:wg:oauth:2.0:oob"

/// Class to support serialization and deserialization of `AuthSession` in the format used by
/// GTMOAuth2.
///
/// The methods of this class are capable of serializing and deserializing auth objects in a way
/// compatible with the serialization in `GTMOAuth2ViewControllerTouch` and
/// `GTMOAuth2WindowController` in GTMOAuth2.
@objc(GTMOAuth2Compatibility)
public final class GTMOAuth2Compatibility: NSObject {

  @available(*, unavailable)
  override init() {
    super.init()
  }

  // MARK: - GTMOAuth2 Utilities

  /// Encodes the given `AuthSession` in a GTMOAuth2 compatible persistence string using URL param
  /// key/value encoding.
  ///
  /// - Parameters:
  ///   - authSession: The `AuthSession` to serialize in GTMOAuth2 format.
  /// - Returns: A `String?` representing the GTMOAuth2 persistence representation of the
  ///   authorization object.
  @objc(persistenceResponseStringForAuthSession:)
  public static func persistenceResponseString(forAuthSession authSession: AuthSession) -> String? {
    // TODO: (mdmathias) Write a test for this method that ensures nil is returned.
    let refreshToken = authSession.authState.refreshToken
    let accessToken = authSession.authState.lastTokenResponse?.accessToken

    let dict = [
      oauth2RefreshTokenKey: refreshToken,
      oauth2AccessTokenKey: accessToken,
      AuthSession.serviceProviderKey: authSession.serviceProvider,
      AuthSession.userIDKey: authSession.userID,
      AuthSession.userEmailKey: authSession.userEmail,
      AuthSession.userEmailIsVerifiedKey: authSession._userEmailIsVerified,
      oauth2ScopeKey: authSession.authState.scope
    ]

    let responseString = dict
      .sorted { $0.key < $1.key }
      .compactMap { (key, _) -> String? in
        guard let val = dict[key] as? String,
              let encodedKey = encodedOAuthValue(forOriginalString: key),
              let encodedValue = encodedOAuthValue(forOriginalString: val) else {
          return nil
        }
        return String(format: "%@=%@", arguments: [encodedKey, encodedValue])
      }
      .joined(separator: "&")

    return responseString.isEmpty ? nil : responseString
  }

  // MARK: - Encoded OAuth Value

  private static func encodedOAuthValue(
    forOriginalString originalString: String
  ) -> String? {
    // For parameters, we'll explicitly leave spaces unescaped now, and replace them with +'s
    let forceEscape = "!*'();:@&=+$,/?%#[]"
    let escapeCharacters = CharacterSet(charactersIn: forceEscape)
    let urlQueryCharacters = CharacterSet.urlQueryAllowed.symmetricDifference(escapeCharacters)
    return originalString.addingPercentEncoding(withAllowedCharacters: urlQueryCharacters)
  }

  private static var googleAuthorizationURL = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
  static let googleTokenURL = URL(string: "https://www.googleapis.com/oauth2/v4/token")!
  static var googleRevocationURL = URL(string: "https://accounts.google.com/o/oauth2/revoke")!
  static var googleUserInfoURL = URL(string: "https://www.googleapis.com/oauth2/v3/userinfo")!
  static var nativeClientRedirectURI: String {
    return oobString
  }

  static func dictionary(
    fromKeychainPassword keychainPassword: String
  ) -> [String: String] {
    let keyValueTuples: [(String, String)] = keychainPassword
      .components(separatedBy: "&")
      .compactMap {
        let equalComps = $0.components(separatedBy: "=")
        guard let key = equalComps.first,
              let percentsRemovedKey = key.removingPercentEncoding,
              let value = equalComps.last,
              let percentsRemovedValue = value.removingPercentEncoding else {
          return nil
        }
        return (percentsRemovedKey, percentsRemovedValue)
      }
    let passwordDictionary = Dictionary(uniqueKeysWithValues: keyValueTuples)
    return passwordDictionary
  }

  /// Creates an `AuthSession` from the provided persistence string.
  /// - Parameters:
  ///   - persistenceString: The `String` representing the `AuthSession` to create.
  ///   - tokenURL: The `URL` to use when creating the `AuthSession`.
  ///   - redirectURI: The `String` URI to use for the `AuthSession`.
  ///   - clientID: The `String` client ID for the `AuthSession`.
  ///   - clientSecret: The optional `String` for the `AuthSession`.
  /// - Throws: `KeychainStore.Error.failedToConvertRedirectURItoURL` if `redirectURI` cannot be
  ///   converted to a `URL`.
  /// - Returns: An instance of `AuthSession` if successful.
  @objc static public func authSession(
    forPersistenceString persistenceString: String,
    tokenURL: URL,
    redirectURI: String,
    clientID: String,
    clientSecret: String?
  ) throws -> AuthSession {
    let persistenceDictionary = GTMOAuth2Compatibility.dictionary(
      fromKeychainPassword: persistenceString
    )
    guard let redirectURL = URL(string: redirectURI) else {
      throw KeychainStore.Error.failedToConvertRedirectURItoURL(redirectURI)
    }

    let authConfig = OIDServiceConfiguration(
      authorizationEndpoint: tokenURL,
      tokenEndpoint: tokenURL
    )

    let authRequest = OIDAuthorizationRequest(
      configuration: authConfig,
      clientId: clientID,
      clientSecret: clientSecret,
      scope: persistenceDictionary[oauth2ScopeKey],
      redirectURL: redirectURL,
      responseType: OIDResponseTypeCode,
      state: nil,
      nonce: nil,
      codeVerifier: nil,
      codeChallenge: nil,
      codeChallengeMethod: nil,
      additionalParameters: nil
    )

    let authResponse = OIDAuthorizationResponse(
      request: authRequest,
      parameters: persistenceDictionary as [String: NSString]
    )
    var additionalParameters = persistenceDictionary
    additionalParameters.removeValue(forKey: oauth2ScopeKey)
    additionalParameters.removeValue(forKey: oauth2RefreshTokenKey)

    let tokenRequest = OIDTokenRequest(
      configuration: authConfig,
      grantType: "token",
      authorizationCode: nil,
      redirectURL: redirectURL,
      clientID: clientID,
      clientSecret: clientSecret,
      scope: persistenceDictionary[oauth2ScopeKey],
      refreshToken: persistenceDictionary[oauth2RefreshTokenKey],
      codeVerifier: nil,
      additionalParameters: additionalParameters
    )
    let tokenResponse = OIDTokenResponse(
      request: tokenRequest,
      parameters: persistenceDictionary as [String: NSString]
    )

    let authState = OIDAuthState(authorizationResponse: authResponse, tokenResponse: tokenResponse)
    // We're not serializing the token expiry date, so the first refresh needs to be forced.
    authState.setNeedsTokenRefresh()

    let authSession = AuthSession(
      authState: authState,
      serviceProvider: persistenceDictionary[AuthSession.serviceProviderKey],
      userID: persistenceDictionary[AuthSession.userIDKey],
      userEmail: persistenceDictionary[AuthSession.userEmailKey],
      userEmailIsVerified: persistenceDictionary[AuthSession.userEmailIsVerifiedKey]
    )
    return authSession
  }
}

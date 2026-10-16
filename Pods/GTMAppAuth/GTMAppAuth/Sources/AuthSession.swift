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

/// An implementation of the `GTMFetcherAuthorizationProtocol` protocol for the AppAuth library.
///
/// Enables you to use AppAuth with the GTM Session Fetcher library.
@objc(GTMAuthSession)
public final class AuthSession: NSObject, GTMSessionFetcherAuthorizer, NSSecureCoding {
  /// The legacy name for this type used while archiving and unarchiving an instance.
  static let legacyArchiveName = "GTMAppAuthFetcherAuthorization"

  /// The AppAuth authentication state.
  @objc public let authState: OIDAuthState

  /// Service identifier, for example "Google"; not used for authentication.
  ///
  /// The provider name is just for allowing stored authorization to be associated with the
  /// authorizing service.
  @objc public let serviceProvider: String?

  /// User ID from the ID Token.
  ///
  /// Never send this value to your backend as an authentication token, rather send an ID Token and
  /// validate it.
  @objc public let userID: String?

  /// The user email.
  @objc public let userEmail: String?

  /// The verified string used in the `userEmailIsVerified` computed property.
  ///
  /// If the result is false, then the email address is listed with the account on the server, but
  /// the address has not been confirmed as belonging to the owner of the account.
  let _userEmailIsVerified: String?

  /// Email verified status; not used for authentication.
  @objc public var userEmailIsVerified: Bool {
    guard let isVerified = _userEmailIsVerified else {
      return false
    }
    return (isVerified as NSString).boolValue
  }

  /// For development only, allow authorization of non-SSL requests, allowing transmission of the
  /// bearer token unencrypted.
  @objc public var shouldAuthorizeAllRequests = false

  /// Delegate of the `AuthSession`.
  @objc public weak var delegate: AuthSessionDelegate?

  /// The fetcher service.
  @objc public weak var fetcherService: GTMSessionFetcherServiceProtocol? = nil

  private let serialAuthArgsQueue = DispatchQueue(label: "com.google.gtmappauth")
  private var authorizationArgs = [AuthorizationArguments]()

  /// Creates a new `AuthSession` using the given `OIDAuthState` from AppAuth.
  ///
  /// - Parameters:
  ///   - authState: The authorization state.
  @objc(initWithAuthState:)
  convenience public init(authState: OIDAuthState) {
    self.init(
      authState: authState,
      serviceProvider: nil,
      userID: nil,
      userEmail: nil,
      userEmailIsVerified: nil
    )
  }

  /// Creates a new `AuthSession` using the given `OIDAuthState` from AppAuth.
  ///
  /// - Parameters:
  ///   - authState: The authorization state.
  ///   - serviceProvider: An optional string to describe the service.
  ///   - userID: An optional string of the user ID.
  ///   - userEmail: An optional string of the user's email address.
  ///   - userEmailIsVerified: An optional string representation of a boolean to indicate
  ///     that the email address has been verified. Pass "true" or "false".
  @objc public init(
    authState: OIDAuthState,
    serviceProvider: String? = nil,
    userID: String? = nil,
    userEmail: String? = nil,
    userEmailIsVerified: String? = nil
  ) {
    self.authState = authState
    self.serviceProvider = serviceProvider
    if let idToken = authState.lastTokenResponse?.idToken ??
        authState.lastAuthorizationResponse.idToken,
       let claims = OIDIDToken(
        idTokenString: idToken
       )?.claims as? [String: Any] {
      self.userID = claims["sub"] as? String ?? userID
      self.userEmail = claims["email"] as? String ?? userEmail
      self._userEmailIsVerified = claims["email_verified"] as? String ?? userEmailIsVerified
    } else {
      self.userID = userID
      self.userEmail = userEmail
      self._userEmailIsVerified = userEmailIsVerified
    }
    super.init()
  }

  // MARK: - Secure Coding
  @objc public static let supportsSecureCoding = true

  @objc public func encode(with coder: NSCoder) {
    coder.encode(authState, forKey: AuthSession.authStateKey)
    coder.encode(serviceProvider, forKey: AuthSession.serviceProviderKey)
    coder.encode(userID, forKey: AuthSession.userIDKey)
    coder.encode(userEmail, forKey: AuthSession.userEmailKey)
    coder.encode(_userEmailIsVerified, forKey: AuthSession.userEmailIsVerifiedKey)
  }

  @objc public required convenience init?(coder: NSCoder) {
    guard let authState = coder.decodeObject(
      of: OIDAuthState.self,
      forKey: AuthSession.authStateKey
    ) else {
      return nil
    }
    let serviceProvider = coder.decodeObject(
      of: NSString.self,
      forKey: AuthSession.serviceProviderKey
    ) as String?
    let userID = coder.decodeObject(
      of: NSString.self,
      forKey: AuthSession.userIDKey
    ) as String?
    let userEmail = coder.decodeObject(
      of: NSString.self,
      forKey: AuthSession.userEmailKey
    ) as String?
    let _userEmailIsVerified = coder.decodeObject(
      of: NSString.self,
      forKey: AuthSession.userEmailIsVerifiedKey
    ) as String?

    self.init(
      authState: authState,
      serviceProvider: serviceProvider,
      userID: userID,
      userEmail: userEmail,
      userEmailIsVerified: _userEmailIsVerified
    )
  }

  // MARK: - Authorizing Requests (GTMSessionFetcherAuthorizer)

  /// Adds an authorization header to the given request, using the authorization state. Refreshes
  /// the access token if needed.
  ///
  /// - Parameters:
  ///   - request: The request to authorize.
  ///   - handler: The block that is called after authorizing the request is attempted.  If `error`
  ///     is non-nil, the authorization failed.  Errors in the domain `OIDOAuthTokenErrorDomain`
  ///     indicate that the authorization itself is invalid, and will need to be re-obtained from
  ///     the user.  `AuthSession.Error`s indicate other unrecoverable errors. Errors in other
  ///     domains may indicate a transitive error condition such as a network error, and typically
  ///     you do not need to reauthenticate the user on such errors.
  ///
  /// The completion handler is scheduled on the main thread, unless the `callbackQueue` property is
  /// set on the `fetcherService` in which case the handler is scheduled on that queue.
  @objc(authorizeRequest:completionHandler:)
  public func authorizeRequest(
    _ request: NSMutableURLRequest?,
    completionHandler handler: @escaping (Swift.Error?) -> Void
  ) {
    guard let request = request else { return }
    let arguments = AuthorizationArguments(
      request: request,
      callbackStyle: .completion(handler)
    )
    authorizeRequest(withArguments: arguments)
  }

  /// Adds an authorization header to the given request, using the authorization state. Refreshes
  /// the access token if needed.
  ///
  /// - Parameters:
  ///   - request: The request to authorize.
  ///   - delegate: The delegate to receive the callback.
  ///   - selector: The `Selector` to call upon the provided `delegate`.
  @objc(authorizeRequest:delegate:didFinishSelector:)
  public func authorizeRequest(
    _ request: NSMutableURLRequest?,
    delegate: Any,
    didFinish selector: Selector
  ) {
    guard let request = request else { return }
    let arguments = AuthorizationArguments(
      request: request,
      callbackStyle: .delegate(delegate, selector)
    )
    authorizeRequest(withArguments: arguments)
  }

  private func authorizeRequest(withArguments args: AuthorizationArguments) {
    serialAuthArgsQueue.sync {
      authorizationArgs.append(args)
    }
    let additionalRefreshParameters = delegate?.additionalTokenRefreshParameters?(
      forAuthSession: self
    )
    let authStateAction = {
      (accessToken: String?, idToken: String?, error: Swift.Error?) in
      self.serialAuthArgsQueue.sync { [weak self] in
        guard let self = self else { return }
        for var queuedArgs in self.authorizationArgs {
          if let error = error {
            // Give `queuedArgs` most recent error from AppAuth
            queuedArgs.error = error
          }
          self.authorizeRequestImmediately(args: queuedArgs, accessToken: accessToken)
        }
        self.authorizationArgs.removeAll()
      }
    }
    authState.performAction(
      freshTokens: authStateAction,
      additionalRefreshParameters: additionalRefreshParameters
    )
  }

  private func authorizeRequestImmediately(args: AuthorizationArguments, accessToken: String?) {
    var args = args
    let request = args.request
    let requestURL = request.url
    let scheme = requestURL?.scheme
    let isAuthorizableRequest = requestURL == nil
    || scheme?.caseInsensitiveCompare("https") == .orderedSame
    || requestURL?.isFileURL ?? false
    || shouldAuthorizeAllRequests
    if !isAuthorizableRequest {
#if DEBUG
      print(
  """
  Request (\(request)) is not https, a local file, or nil. It may be insecure.
  """
      )
#endif
    }
    authorizeRequestControlFlow: if isAuthorizableRequest,
       let accessToken = accessToken,
       !accessToken.isEmpty {
      request.setValue(
        "Bearer \(accessToken)",
        forHTTPHeaderField: "Authorization"
      )
      // `request` is authorized even if previous refreshes produced an error
      args.error = nil
    } else if args.error != nil {
      // Keep error received from AppAuth
      break authorizeRequestControlFlow
    } else if accessToken?.isEmpty ?? true {
      args.error = Error.accessTokenEmptyForRequest(request as URLRequest)
    } else {
      args.error = Error.cannotAuthorizeRequest(request as URLRequest)
    }
    let callbackQueue = fetcherService?.callbackQueue ?? DispatchQueue.main

    let callback: () -> Void = {
      callbackQueue.async {
        switch args.callbackStyle {
        case .completion(let callback):
          self.invokeCompletionCallback(with: callback, error: args.error)
        case .delegate(let delegate, let selector):
          self.invokeCallback(
            withDelegate: delegate,
            selector: selector,
            request: request,
            error: args.error
          )
        }
      }
    }

    if let error = args.error, let delegate = self.delegate, delegate.updateError != nil {
      // Use updated error if exists; otherwise, use whatever is already in `args.error`
      delegate.updateError?(forAuthSession: self, originalError: error) { updatedError in
        args.error = updatedError ?? error
        callback()
      }
    } else {
      callback()
    }
  }

  private func invokeCallback(
    withDelegate delegate: Any,
    selector: Selector,
    request: NSMutableURLRequest,
    error: Swift.Error?
  ) {
    guard let delegate = delegate as? NSObject, delegate.responds(to: selector) else {
      return
    }
    let authorization = self
    let methodImpl = delegate.method(for: selector)
    typealias DelegateCallback = @convention(c) (
      NSObject,
      Selector,
      AuthSession,
      NSMutableURLRequest,
      NSError?
    ) -> Void
    let authorizeRequest: DelegateCallback = unsafeBitCast(
      methodImpl,
      to: DelegateCallback.self
    )
    authorizeRequest(
      delegate,
      selector,
      authorization,
      request,
      error as NSError?
    )
  }

  private func invokeCompletionCallback(
    with handler: (Swift.Error?) -> Void,
    error: Swift.Error?
  ) {
    handler(error)
  }

  // MARK: - Stopping Authorization

  /// Stops authorization for all pending requests.
  @objc public func stopAuthorization() {
    serialAuthArgsQueue.sync {
      authorizationArgs.removeAll()
    }
  }

  /// Stops authorization for the provided `URLRequest` if it is queued for authorization.
  @objc public func stopAuthorization(for request: URLRequest) {
    serialAuthArgsQueue.sync {
      guard let index = authorizationArgs.firstIndex(where: { (authorizationArg: AuthorizationArguments) in
        authorizationArg.request as URLRequest == request
      }) else {
        return
      }
      authorizationArgs.remove(at: index)
    }
  }

  /// Returns `true` if the provided `URLRequest` is currently in the process of, or is in the queue
  /// for, authorization.
  @objc public func isAuthorizingRequest(_ request: URLRequest) -> Bool {
    var argsWithMatchingRequest: AuthorizationArguments?
    serialAuthArgsQueue.sync {
      argsWithMatchingRequest = authorizationArgs.first { args in
        args.request as URLRequest == request
      }
    }
    return argsWithMatchingRequest != nil
  }

  /// Returns `true` if the provided `URLRequest` has the "Authorization" header field.
  @objc public func isAuthorizedRequest(_ request: URLRequest) -> Bool {
    guard let authField = request.value(
      forHTTPHeaderField: "Authorization"
    ) else {
      return false
    }
    return !authField.isEmpty
  }

  /// Returns `true` if the authorization state is currently valid.
  ///
  /// This doesn't guarantee that a request will get a valid authorization, as the authorization
  /// state could become invalid on the next token refresh.
  @objc public var canAuthorize: Bool {
    return authState.isAuthorized
  }

  /// Whether or not this authorization is prime for refresh.
  ///
  /// - Returns: `false` if the `OIDAuthState`'s `refreshToken` is nil. `true` otherwise.
  ///
  /// If `true`, calling this method will `setNeedsTokenRefresh()` on the `OIDAuthState` instance
  /// property.
  @objc public func primeForRefresh() -> Bool {
    guard authState.refreshToken == nil else {
      return false
    }
    authState.setNeedsTokenRefresh()
    return true
  }

  /// Convenience method to return an @c OIDServiceConfiguration for Google.
  ///
  /// - Returns: An `OIDServiceConfiguration` object setup with Google OAuth endpoints.
  @objc public static func configurationForGoogle() -> OIDServiceConfiguration {
    let authzEndpoint = URL(
      string: "https://accounts.google.com/o/oauth2/v2/auth"
    )!
    let tokenEndpoint = URL(
      string: "https://www.googleapis.com/oauth2/v4/token"
    )!
    let configuration = OIDServiceConfiguration(
      authorizationEndpoint: authzEndpoint,
      tokenEndpoint: tokenEndpoint
    )
    return configuration
  }
}

private struct AuthorizationArguments {
  let request: NSMutableURLRequest
  let callbackStyle: CallbackStyle
  var error: Swift.Error?
}

extension AuthorizationArguments {
  enum CallbackStyle {
    case completion((Swift.Error?) -> Void)
    case delegate(Any, Selector)
  }
}

public extension AuthSession {
  // MARK: - Keys

  static let authStateKey = "authState"
  static let serviceProviderKey = "serviceProvider"
  static let userIDKey = "userID"
  static let userEmailKey = "userEmail"
  static let userEmailIsVerifiedKey = "userEmailIsVerified"

  // MARK: - Errors

  /// Errors that may arise while authorizing a request.
  enum Error: Swift.Error, Equatable, CustomNSError {
    case cannotAuthorizeRequest(URLRequest)
    case accessTokenEmptyForRequest(URLRequest)

    public static let errorDomain: String = "GTMAuthSessionErrorDomain"

    public var errorUserInfo: [String : Any] {
      switch self {
      case .cannotAuthorizeRequest(let request):
        return ["request": request]
      case .accessTokenEmptyForRequest(let request):
        return ["request": request]
      }
    }

    public var errorCode: Int {
      return ErrorCode(error: self).rawValue
    }
  }

  /// Error codes associated with cases from `AuthSession.Error`.
  ///
  /// The cases for this enumeration are backed by integer raw values and are used to fill out the
  /// `errorCode` for the `NSError` representation of `AuthSession.Error`.
  @objc(GTMAuthSessionErrorCode)
  enum ErrorCode: Int {
    case cannotAuthorizeRequest
    case accessTokenEmptyForRequest

    init(error: AuthSession.Error) {
      switch error {
      case .cannotAuthorizeRequest:
        self = .cannotAuthorizeRequest
      case .accessTokenEmptyForRequest:
        self = .accessTokenEmptyForRequest
      }
    }
  }
}

/*
 * Copyright 2023 Google LLC
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

/// Methods defining the `AuthSession`'s delegate.
@objc(GTMAuthSessionDelegate)
public protocol AuthSessionDelegate {
  /// Used to supply additional parameters on token refresh.
  ///
  /// - Parameters:
  ///   - authSession: The `AuthSession` needing additional token refresh parameters.
  /// - Returns: An optional `[String: String]` supplying the additional token refresh parameters.
  @objc optional func additionalTokenRefreshParameters(
    forAuthSession authSession: AuthSession
  ) -> [String: String]?

  /// A method notifying the delegate that the authorization request failed.
  ///
  /// Use this method to examine the error behind the failed authorization request and supply a
  /// customized error created asynchronously that specifies whatever context is needed.
  ///
  /// - Parameters:
  ///   - authSession: The `AuthSession` whose authorization request failed.
  ///   - originalError: The original `Error` associated with the failure.
  ///   - completion: An escaping closure to pass back the updated error.
  @objc optional func updateError(
    forAuthSession authSession: AuthSession,
    originalError: Error,
    completion: @escaping (Error?) -> Void
  )
}

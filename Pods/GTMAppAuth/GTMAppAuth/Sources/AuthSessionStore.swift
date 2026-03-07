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

/// Represents the operations needed to provide `AuthSession` storage.
@objc(GTMAuthSessionStore)
public protocol AuthSessionStore {
  /// Saves the provided `AuthSession`.
  ///
  /// - Parameter authSession: An instance of `AuthSession` to save.
  /// - Throws: Any error that may arise during the save.
  @objc(saveAuthSession:error:)
  func save(authSession: AuthSession) throws

  /// Removes the stored `AuthSession`.
  ///
  /// - Throws: Any error that may arise during the removal.
  @objc(removeAuthSessionWithError:)
  func removeAuthSession() throws

  /// Retrieves the stored `AuthSession`.
  ///
  /// - Throws: Any error that may arise during the retrieval.
  @objc(retrieveAuthSessionWithError:)
  func retrieveAuthSession() throws -> AuthSession
}

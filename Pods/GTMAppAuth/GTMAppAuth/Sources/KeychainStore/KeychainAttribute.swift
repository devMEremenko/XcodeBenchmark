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

/// The Keychain attribute used to configure the way the keychain stores your items.
@objc(GTMKeychainAttribute)
public final class KeychainAttribute: NSObject {
  /// An enumeratiion listing the various attributes used to configure the Keychain.
  public enum Attribute {
    /// Indicates whether to treat macOS keychain items like iOS keychain items.
    ///
    /// This attribute will set `kSecUseDataProtectionKeychain` as true in the Keychain query.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    case useDataProtectionKeychain
    /// The `String` name for the access group to use in the Keychain query.
    case accessGroup(String)

    /// A `String` representation of the attribute.
    public var keyName: String {
      switch self {
      case .useDataProtectionKeychain:
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
          return kSecUseDataProtectionKeychain as String
        } else {
          fatalError("`KeychainAttribute.Attribute.useDataProtectionKeychain is only available on macOS 10.15 and greater")
        }
      case .accessGroup:
        return kSecAttrAccessGroup as String
      }
    }
  }

  /// The set `Attribute` given upon initialization.
  public let attribute: Attribute

  /// Creates an instance of `KeychainAttribute`.
  /// - Parameters:
  ///   - attribute: An instance of `KeychainAttribute.Attribute` used to configure Keychain
  ///       queries.
  public init(attribute: Attribute) {
    self.attribute = attribute
  }

  /// Creates an instance of `KeychainAttribute` whose attribute is set to
  /// `.useDataProtectionKeychain`.
  /// - Returns: An instance of `KeychainAttribute`.
  @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
  @objc public static let useDataProtectionKeychain = KeychainAttribute(
    attribute: .useDataProtectionKeychain
  )

  /// Creates an instance of `KeychainAttribute` whose attribute is set to `.accessGroup`.
  /// - Parameters:
  ///   - name: The `String` name for the access group.
  /// - Returns: An instance of `KeychainAttribute`.
  @objc public static func keychainAccessGroup(name: String) -> KeychainAttribute {
    return KeychainAttribute(attribute: .accessGroup(name))
  }
}

[![Version](https://img.shields.io/cocoapods/v/GTMAppAuth.svg?style=flat)](https://cocoapods.org/pods/GTMAppAuth)
[![Platform](https://img.shields.io/cocoapods/p/GTMAppAuth.svg?style=flat)](https://cocoapods.org/pods/GTMAppAuth)
[![License](https://img.shields.io/cocoapods/l/GTMAppAuth.svg?style=flat)](https://cocoapods.org/pods/GTMAppAuth)
[![tests](https://github.com/google/GTMAppAuth/actions/workflows/tests.yml/badge.svg?event=push)](https://github.com/google/GTMAppAuth/actions/workflows/tests.yml)

# GTMAppAuth for Apple Platforms

GTMAppAuth enables you to use [AppAuth](https://github.com/openid/AppAuth-iOS)
with the
[Google Toolbox for Mac - Session Fetcher](https://github.com/google/gtm-session-fetcher)
and
[Google APIs Client Library for Objective-C For REST](https://github.com/google/google-api-objectivec-client-for-rest)
libraries on iOS, macOS, tvOS, and watchOS by providing an implementation of
[`GTMFetcherAuthorizationProtocol`](https://github.com/google/gtm-session-fetcher/blob/2a3b5264108e80d62003b770ff02eb7364ff1365/Source/GTMSessionFetcher.h#L660)
for authorizing requests with AppAuth.

GTMAppAuth is an alternative authorizer to [GTMOAuth2](https://github.com/google/gtm-oauth2)
. The key differentiator is the use of the user's default browser for the
authorization, which is more secure, more usable (the user's session can be
reused) and follows modern OAuth [best practices for native apps](https://datatracker.ietf.org/doc/html/rfc8252).
Compatibility methods for GTMOAuth2 are offered allowing you to migrate
from GTMOAuth2 to GTMAppAuth preserving previously serialized authorizations
(so users shouldn't need to re-authenticate).

## Setup

If you use [CocoaPods](https://guides.cocoapods.org/using/getting-started.html),
simply add:

    pod 'GTMAppAuth'

To your `Podfile` and run `pod install`.

## Usage

### Configuration

To configure GTMAppAuth with the OAuth endpoints for Google, you can use the
convenience method:

```objc
OIDServiceConfiguration *configuration = [GTMAuthSession configurationForGoogle];
```

Alternatively, you can configure GTMAppAuth by specifying the endpoints
directly:

```objc
NSURL *authorizationEndpoint =
    [NSURL URLWithString:@"https://accounts.google.com/o/oauth2/v2/auth"];
NSURL *tokenEndpoint =
    [NSURL URLWithString:@"https://www.googleapis.com/oauth2/v4/token"];

OIDServiceConfiguration *configuration =
    [[OIDServiceConfiguration alloc]
        initWithAuthorizationEndpoint:authorizationEndpoint
                        tokenEndpoint:tokenEndpoint];

// perform the auth request...
```

Or through discovery:

```objc
NSURL *issuer = [NSURL URLWithString:@"https://accounts.google.com"];

[OIDAuthorizationService discoverServiceConfigurationForIssuer:issuer
    completion:^(OIDServiceConfiguration *_Nullable configuration,
                 NSError *_Nullable error) {
  if (!configuration) {
    NSLog(@"Error retrieving discovery document: %@",
          [error localizedDescription]);
    return;
  }

  // perform the auth request...
}];
```

### Authorizing

First, you need to have a way for your UIApplicationDelegate to continue the
authorization flow session from the incoming redirect URI. Typically you could
store the in-progress OIDAuthorizationFlowSession instance in a property:

```objc
// property of the app's UIApplicationDelegate
@property(nonatomic, nullable)
    id<OIDExternalUserAgentSession> currentAuthorizationFlow;
```

And in a location accessible by all controllers that need authorization, a
property to store the authorization state:

```objc
// property of the containing class
@property(nonatomic, nullable) GTMAuthSession *authSession;
```

Then, initiate the authorization request. By using the
`authStateByPresentingAuthorizationRequest` method, the OAuth token
exchange will be performed automatically, and everything will be protected with
PKCE (if the server supports it).

```objc
// builds authentication request
OIDAuthorizationRequest *request =
    [[OIDAuthorizationRequest alloc] initWithConfiguration:configuration
                                                  clientId:kClientID
                                              clientSecret:kClientSecret
                                                    scopes:@[OIDScopeOpenID, OIDScopeProfile]
                                               redirectURL:redirectURI
                                              responseType:OIDResponseTypeCode
                                      additionalParameters:nil];
// performs authentication request
self.appDelegate.currentAuthorizationFlow =
    [OIDAuthState authStateByPresentingAuthorizationRequest:request
        callback:^(OIDAuthState *_Nullable authState,
                   NSError *_Nullable error) {
  if (authState) {
    // Creates a GTMAuthSession from the OIDAuthState.
    self.authSession = [[GTMAuthSession alloc] initWithAuthState:authState];
    NSLog(@"Got authorization tokens. Access token: %@",
          authState.lastTokenResponse.accessToken);
  } else {
    NSLog(@"Authorization error: %@", [error localizedDescription]);
    self.authSession = nil;
  }
}];
```

### Handling the Redirect

The authorization response URL is returned to the app via the platform-specific
application delegate method, so you need to pipe this through to the current
authorization session (created in the previous session).

#### macOS Custom URI Scheme Redirect Example

```objc
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // Other app initialization code ...

  // Register for GetURL events.
  NSAppleEventManager *appleEventManager =
      [NSAppleEventManager sharedAppleEventManager];
  [appleEventManager setEventHandler:self
                         andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                       forEventClass:kInternetEventClass
                          andEventID:kAEGetURL];
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event
           withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
  NSString *URLString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
  NSURL *URL = [NSURL URLWithString:URLString];
  [_currentAuthorizationFlow resumeExternalUserAgentFlowWithURL:URL];
}
```

#### iOS Custom URI Scheme Redirect Example

```objc
- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<NSString *, id> *)options {
  // Sends the URL to the current authorization flow (if any) which will
  // process it if it relates to an authorization response.
  if ([_currentAuthorizationFlow resumeExternalUserAgentFlowWithURL:url]) {
    _currentAuthorizationFlow = nil;
    return YES;
  }

  // Your additional URL handling (if any) goes here.

  return NO;
}
```

### Making API Calls

The goal of GTMAppAuth is to enable you to authorize HTTP requests with fresh
tokens following the Session Fetcher pattern, which you can do like so:

```objc
// Creates a GTMSessionFetcherService with the authorization.
// Normally you would save this service object and re-use it for all REST API calls.
GTMSessionFetcherService *fetcherService = [[GTMSessionFetcherService alloc] init];
fetcherService.authorizer = self.authSession;

// Creates a fetcher for the API call.
NSURL *userinfoEndpoint = [NSURL URLWithString:@"https://www.googleapis.com/oauth2/v3/userinfo"];
GTMSessionFetcher *fetcher = [fetcherService fetcherWithURL:userinfoEndpoint];
[fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
  // Checks for an error.
  if (error) {
    // OIDOAuthTokenErrorDomain indicates an issue with the authorization.
    if ([error.domain isEqual:OIDOAuthTokenErrorDomain]) {
      self.authSession = nil;
      NSLog(@"Authorization error during token refresh, clearing state. %@",
            error);
    // Other errors are assumed transient.
    } else {
      NSLog(@"Transient error during token refresh. %@", error);
    }
    return;
  }

  // Parses the JSON response.
  NSError *jsonError = nil;
  id jsonDictionaryOrArray =
      [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

  // JSON error.
  if (jsonError) {
    NSLog(@"JSON decoding error %@", jsonError);
    return;
  }

  // Success response!
  NSLog(@"Success: %@", jsonDictionaryOrArray);
}];
```

### Saving to the Keychain

You can easily save `GTMAuthSession` instances to the Keychain using the `GTMKeychainStore` class.

```objc
// Create a GIDKeychainStore instance, intializing it with the Keychain item name `kKeychainItemName`
// which will be used when saving, retrieving, and removing `GTMAuthSession` instances.
GIDKeychainStore *keychainStore = [[GIDKeychainStore alloc] initWithItemName:kKeychainItemName];
    
NSError *error;

// Save to the Keychain
[keychainStore saveAuthSession:self.authSession error:&error];
if (error) {
  // Handle error
}

// Retrieve from the Keychain
self.authSession = [keychainStore retrieveAuthSessionWithError:&error];
if (error) {
  // Handle error
}

// Remove from the Keychain
[keychainStore removeAuthSessionWithError:&error];
if (error) {
  // Handle error
}
```

#### Keychain Storage

With `GTMKeychainStore`, by default, `GTMAuthSession` instances are stored using Keychain items of the
[`kSecClassGenericPassword`](https://developer.apple.com/documentation/security/ksecclassgenericpassword?language=objc)
class with a [`kSecAttrAccount`](https://developer.apple.com/documentation/security/ksecattraccount?language=objc)
value of "OAuth" and a developer supplied value for [`kSecAttrService`](https://developer.apple.com/documentation/security/ksecattrservice?language=objc).
For this use of generic password items, the combination of account and service
values acts as the
[primary key](https://developer.apple.com/documentation/security/1542001-security_framework_result_codes/errsecduplicateitem?language=objc)
of the Keychain items.  The
[`kSecAttrAccessible`](https://developer.apple.com/documentation/security/ksecattraccessible?language=objc)
key is set to
[`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`](https://developer.apple.com/documentation/security/ksecattraccessibleafterfirstunlockthisdeviceonly?language=objc)
in order to allow background access after initial device unlock following a
restart.  A [keyed archive](https://developer.apple.com/documentation/foundation/nskeyedarchiver?language=objc)
representation of the relevant `GTMAuthSession` instance is supplied as the value for
[`kSecValueData`](https://developer.apple.com/documentation/security/ksecvaluedata?language=objc)
and this is encrypted and stored by
[Keychain Services](https://developer.apple.com/documentation/security/keychain_services?language=objc).

For macOS, two Keychain storage options are available: the traditional file-based Keychain storage
which uses access control lists and the more modern [data protection keychain storage](https://developer.apple.com/documentation/security/ksecusedataprotectionkeychain?language=objc)
which uses Keychain access control groups. By default, GTMAppAuth uses the file-based Keychain storage on macOS.  You may opt
into using data protection keychain storage by including the `GTMKeychainAttribute.useDataProtectionKeychain` attribute
in the `keychainAttributes` parameter of `initWithItemName:keychainAttributes:` when initializing `GTMKeychainStore`.
Note that Keychain items stored via one storage type will not be available via the other and macOS apps that choose
to use the data protection Keychain will need to be signed in order for Keychain operations to succeed.

### Implementing Your Own Storage

If you'd like to use a backing store other than the Keychain to save your `GTMAuthSession`
instances, you can create your own `GTMAuthSessionStore` conformance.  Use `GTMKeychainStore` as an
example of how to do this.

#### GTMOAuth2 Compatibility

To assist the migration from GTMOAuth2 to GTMAppAuth, GTMOAuth2-compatible Keychain methods are provided in `GTMKeychainStore`.

```objc
GTMKeychainStore keychainStore = [[GTMKeychainStore alloc] initWithItemName:kKeychainItemName];

// Retrieve from the Keychain
NSError *error;
GTMAuthSession *authSession =
    [keychainStore retrieveAuthSessionForGoogleInGTMOAuth2FormatWithClientID:clientID
                                                                clientSecret:clientSecret
                                                                       error:&error];

// Remove from the Keychain
[keychainStore removeAuthSessionWithError:&error];
```

You can also save to GTMOAuth2 format, though this is discouraged (you
should save in GTMAppAuth format as described above).

```objc
// Save to the Keychain
[keychainStore saveWithGTMOAuth2FormatForAuthSession:authSession error:&error];
```

## Included Samples

Try out one of the included sample apps under [Examples](Examples). In the
apps folder run `pod install`, then open the resulting `xcworkspace` file.

Be sure to follow the instructions in
[Example-iOS/README.md](Examples/Example-iOS/README.md) or
[Example-macOS/README.md](Examples/Example-macOS/README.md) to configure
your own OAuth client ID for use with the example.

## Differences with GTMOAuth2

### Authorization Method

GTMAppAuth uses the browser to present the authorization request, while
GTMOAuth2 uses an embedded web-view. Migrating to GTMAppAuth will require you
to change how you authorize the user. Follow the instructions above to get the
authorization.  You can then create a `GTMAuthSession` object with its
`initWithAuthState:` initializer.  Once you have a `GTMAuthSession` you can
continue to make REST calls as before.

### Error Handling

GTMAppAuth's error handling is also different. There are no notifications,
instead you need to inspect NSError in the callback. If the error domain is
`OIDOAuthTokenErrorDomain`, it indicates an authorization error, you should
clear your authorization state and consider prompting the user to authorize
again.  Other errors are generally considered transient, meaning that you should
retry the request after a delay.

### Serialization

The serialization format is different between GTMOAuth2 and GTMAppAuth, though
we have methods to help you migrate from one to the other without losing any
data.

## Migrating from GTMOAuth2

### OAuth Client Registration

Typically, GTMOAuth2 clients are registered with Google as type "Other". Instead, Apple clients should be registered with the type "iOS".

If you're migrating an Apple client in the *same project as your existing client*,
[register a new iOS client](https://console.developers.google.com/apis/credentials?project=_)
to be used with GTMAppAuth.

### Changing your Authorization Flows

Both GTMOAuth2 and GTMAppAuth support the `GTMFetcherAuthorizationProtocol`
allowing you to use the authorization with the session fetcher.  Where you
previously had a property like `GTMOAuth2Authentication *authorization` change the
type to reference the protocol instead, i.e.:
`id<GTMFetcherAuthorizationProtocol> authorization`.  This allows you to switch
the authorization implementation under the hood to GTMAppAuth.

Then, follow the instructions above to replace authorization request
(where you ask the user to grant access) with the GTMAppAuth approach. If you
created a new OAuth client, use that for these requests.

### Serialization & Migrating Existing Grants

GTMAppAuth has a new data format and APIs for serialization. Unlike
GTMOAuth2, GTMAppAuth serializes the configuration and history of the
authorization, including the client id, and a record of the authorization
request that resulted in the authorization grant.

The client ID used for GTMAppAuth is [different](#oauth-client-registration) to
the one used for GTMOAuth2. In order to keep track of the different client ids
used for new and old grants, it's recommended to migrate to the new
serialization format, which will store that for you. 
[GTMOAuth2-compatible serialization](#gtmoauth2-compatibility) is
also offered, but not fully supported.

Change how you serialize your `authorization` object by using `GTMAuthSession` and `GTMKeychainStore` as follows:

```objc
// Create an auth session from AppAuth's auth state object
GTMAuthSession *authSession = [[GTMAuthSession alloc] initWithAuthState:authState];

// Create a keychain store
GTMKeychainStore keychainStore = [[GTMKeychainStore alloc] initWithItemName:kNewKeychainName];

// Serialize to Keychain
NSError *error;
[keychainStore saveAuthSession:authSession error:&error];
```

Be sure to use a *new* name for the keychain. Don't reuse your old one!

For deserializing, we can preserve all existing grants (so users who authorized
your app in GTMOAuth2 don't have to authorize it again). Remember that when
deserializing the *old* data you need to use your *old* keychain name, and
the old client id and client secret (if those changed), and that when 
serializing to the *new* format, use the *new* keychain name.
Once again, pay particular care to use the old details when deserializing the
GTMOAuth2 keychain, and the new details for all other GTMAppAuth calls.

Keychain migration example:

```objc
// Create a keychain store
GTMKeychainStore keychainStore = [[GTMKeychainStore alloc] initWithItemName:kNewKeychainName];

// Attempt to deserialize from Keychain in GTMAppAuth format.
NSError *error;
GTMAuthSesion *authSession =
    [keychainStore retrieveAuthSessionWithError:&error];

// If no data found in the new format, try to deserialize data from GTMOAuth2
if (!authSession) {
  // Tries to load the data serialized by GTMOAuth2 using old keychain name.
  // If you created a new client id, be sure to use the *previous* client id and secret here.
  GTMKeychainStore oldKeychainStore = [[GTMKeychainStore alloc] initWithItemName:kPreviousKeychainName];
  authSession =
      [oldKeychainStore retrieveAuthSessionInGTMOAuth2FormatWithClientID:kPreviousClientID
                                                            clientSecret:kPreviousClientSecret
                                                                   error:&error];
  if (authSession) {
    // Remove previously stored GTMOAuth2-formatted data.
    [oldKeychainStore removeAuthSessionWithError:&error];
    // Serialize to Keychain in GTMAppAuth format.
    [keychainStore saveAuthSession:authSession error:&error];
  }
}
```

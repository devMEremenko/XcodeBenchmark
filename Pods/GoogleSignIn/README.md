[![Version](https://img.shields.io/cocoapods/v/GoogleSignIn.svg?style=flat)](https://cocoapods.org/pods/GoogleSignIn)
[![Platform](https://img.shields.io/cocoapods/p/GoogleSignIn.svg?style=flat)](https://cocoapods.org/pods/GoogleSignIn)
[![License](https://img.shields.io/cocoapods/l/GoogleSignIn.svg?style=flat)](https://cocoapods.org/pods/GoogleSignIn)
[![unit_tests](https://github.com/google/GoogleSignIn-iOS/actions/workflows/unit_tests.yml/badge.svg?branch=main)](https://github.com/google/GoogleSignIn-iOS/actions/workflows/unit_tests.yml)
[![integration_tests](https://github.com/google/GoogleSignIn-iOS/actions/workflows/integration_tests.yml/badge.svg?branch=main)](https://github.com/google/GoogleSignIn-iOS/actions/workflows/integration_tests.yml)

# Google Sign-In for iOS and macOS

Get users into your apps quickly and securely, using a registration system they
already use and trust—their Google account.

Visit [our developer site](https://developers.google.com/identity/sign-in/ios/)
for integration instructions, documentation, support information, and terms of
service.

## Getting Started

Try either the [Objective-C](Samples/ObjC) or [Swift](Samples/Swift) sample app.
For example, to demo the Objective-C sample project, you have three options:

1. Using [CocoaPods](https://cocoapods.org/)'s `try` method:

```
pod try GoogleSignIn
```

Note, this will default to providing you with the Objective-C sample app.

2. Using CocoaPod's `install` method:

```
git clone https://github.com/google/GoogleSignIn-iOS
cd GoogleSignIn-iOS/Samples/ObjC/SignInSample/
pod install
open SignInSampleForPod.xcworkspace
```

3. Using [Swift Package Manager](https://swift.org/package-manager/):

```
git clone https://github.com/google/GoogleSignIn-iOS
open GoogleSignIn-iOS/Samples/ObjC/SignInSample/SignInSample.xcodeproj
```

If you would like to see a Swift example, take a look at 
[Samples/Swift/DaysUntilBirthday](Samples/Swift/DaysUntilBirthday).

* Add Google Sign-In to your own app by following our
[getting started guides](https://developers.google.com/identity/sign-in/ios/start-integrating).
* Take a look at the
[API reference](https://developers.google.com/identity/sign-in/ios/api/).

## Google Sign-In on macOS

Google Sign-In allows your users to sign-in to your native macOS app using their Google account
and default browser.  When building for macOS, the `signInWithConfiguration:` and `addScopes:`
methods take a `presentingWindow:` parameter in place of `presentingViewController:`.  Note that
in order for your macOS app to store credientials via the Keychain on macOS, you will need to
[sign your app](https://developer.apple.com/support/code-signing/).

### Mac Catalyst

Google Sign-In also supports iOS apps that are built for macOS via
[Mac Catalyst](https://developer.apple.com/mac-catalyst/).  In order for your Mac Catalyst app
to store credientials via the Keychain on macOS, you will need to
[sign your app](https://developer.apple.com/support/code-signing/).

## Using the Google Sign-In Button

There are several ways to add a 'Sign in with Google' button to your app, which
path you choose will depend on your UI framework and target platform.

### SwiftUI (iOS and macOS)

Creating a 'Sign in with Google' button in SwiftUI can be as simple as this:

```
GoogleSignInButton {
  GIDSignIn.sharedInstance.signIn(withPresenting: yourViewController) { signInResult, error in
      // check `error`; do something with `signInResult`
  }
}
```

This example takes advantage of the initializer's [default argument for the
view model](GoogleSignInSwift/Sources/GoogleSignInButton.swift#L39).
The default arguments for the view model will use the light scheme, the
standard button style, and the normal button state.
You can supply an instance of [`GoogleSignInButtonViewModel`](GoogleSignInSwift/Sources/GoogleSignInButtonViewModel.swift)
with different values for these properties to customize the button.
[This convenience initializer](GoogleSignInSwift/Sources/GoogleSignInButton.swift#L56) 
provides parameters that you can use to set these values as needed.

### UIKit (iOS)

If you are not using SwiftUI to build your user interfaces, you can either
create `GIDSignInButton` programmatically, or in a Xib/Storyboard. 
If you are writing programmatic UI code, it will look something like this:

`let button = GIDSignInButton(frame: CGRect(<YOUR_RECT>))`

### AppKit (macOS)

Given that `GIDSignInButton` is implemented as a subclass of `UIControl`, it
will not be available on macOS. 
You can instead use the SwiftUI Google sign-in button.
Doing so will require that you wrap the SwiftUI button in a hosting view so
that it will be available for use in AppKit.

```
let signInButton = GoogleSignInButton {
  GIDSignIn.sharedInstance.signIn(withPresenting: yourViewController) { signInResult, error in
      // check `error`; do something with `signInResult`
  }
}
let hostedButton = NSHostingView(rootView: signInButton)
```

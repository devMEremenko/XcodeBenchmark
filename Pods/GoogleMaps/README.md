# Google Maps SDK for iOS

This pod contains the Google Maps SDK for iOS, supporting both Objective-C and
Swift.

Use the [Google Maps SDK for iOS](https://developers.google.com/maps/documentation/ios-sdk/)
to enrich your app with interactive maps and immersive Street View panoramas,
and add your own custom elements such as markers, windows and polylines.

# Installation

1. Before you can use the Google Maps SDK for iOS, follow these [setup instructions](https://developers.google.com/maps/documentation/ios-sdk/cloud-setup) to set up a project and get an API key. You will need to add the API key to your code in order to build your app with the Maps SDK for iOS.

1. To integrate Google Maps SDK for iOS into your Xcode project using CocoaPods,
specify it in your `Podfile`, for example:

    ```
    source 'https://github.com/CocoaPods/Specs.git'
    platform :ios, '14.0'
    target 'YOUR_APPLICATION_TARGET_NAME_HERE' do
      pod 'GoogleMaps', '7.1.0'
    end
    ```

    Then, run the following command:

    ```
    $ pod install
    ```

1. Follow additional steps in the ["Set up an Xcode project"](https://developers.google.com/maps/documentation/ios-sdk/config) guide to add your API key to your project, import classes, and add a map.

# Resources

*   *Guides*: Read the [documentation](https://developers.google.com/maps/documentation/ios-sdk/) for full use of the SDK.
*   *Tutorial videos*: Watch code walkthroughs and useful tips on our [YouTube channel](https://www.youtube.com/playlist?list=PL2rFahu9sLJ3Rob1Vb5O4qX4U8-0FeXqJ).
*   *Code samples*: In order to try out our demo app, use:

    ```
    $ pod try GoogleMaps
    ```

    and follow the instructions on our [samples documentation](https://developers.google.com/maps/documentation/ios-sdk/code-samples).

*   *Support*: Ask the community or get help from Google using the links on the Maps SDK for iOS [support page](https://developers.google.com/maps/documentation/ios-sdk/support).

*   *Report issues*: Use our issue tracker to [file a bug](https://issuetracker.google.com/issues/new?component=188833&template=789005)
    or a [feature request](https://issuetracker.google.com/issues/new?component=188833&template=787421).

# License and Terms of Service

By using the Google Maps SDK for iOS you accept Google's Terms of Service and
Policies. Pay attention particularly to the following aspects:

*   Depending on your app and use case, you may be required to display
    attribution. Read more about [attribution requirements](https://developers.google.com/maps/documentation/ios-sdk/intro#attribution_requirements).
*   Be sure to understand [usage and billing](https://developers.google.com/maps/documentation/ios-sdk/usage-and-billing) information related to use of the Maps SDK for iOS.
*   The [Terms of Service](https://developers.google.com/maps/terms) are a
    comprehensive description of the legal contract that you enter with Google
    by using the Google Maps SDK for iOS.

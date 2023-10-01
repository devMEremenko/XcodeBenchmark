# Google Places SDK for iOS

**NOTE:** This pod is the official pod for the Google Places SDK for iOS.
Previously this pod was used by another developer, his content has been moved to
[Swift Google Maps API](https://github.com/honghaoz/Swift-Google-Maps-API) on
GitHub.

This pod contains the Google Places SDK for iOS, supporting both Swift and Objective-C.

Use the [Google Places SDK for iOS]
(https://developers.google.com/maps/documentation/places/ios-sdk) to build location-aware apps that respond contextually to the local businesses and other places near the user's device. Included features:

* Current Place returns a list of places where the user’s device is last known to be located along with an indication of the relative likelihood for each place.
* Place Autocomplete automatically fills in the name and/or address of a place as users type.
* Place Photos returns high-quality images of a place.
* Place Details return and display more detailed information about a place.

# Installation

1. Before you can use the Google Places SDK for iOS, follow these [setup instructions](https://developers.google.com/maps/documentation/places/ios-sdk/cloud-setup) to set up a project and get an API key. You will need to add the API key to your code in order to build your app with the Places SDK for iOS.

1. To integrate Google Places SDK for iOS into your Xcode project using CocoaPods,
specify it in your `Podfile`, for example:

    ```
    source 'https://github.com/CocoaPods/Specs.git'
    platform :ios, '14.0'
    target 'YOUR_APPLICATION_TARGET_NAME_HERE' do
      pod 'GooglePlaces', '7.1.0'
    end
    ```

    Then, run the following command:

    ```
    $ pod install
    ```

1. Follow additional steps in the ["Set up an Xcode project"](https://developers.google.com/maps/documentation/places/ios-sdk/config) guide to add your API key to your project, import classes, and add a map.

# Resources

*   *Guides*: Read the [documentation](https://developers.google.com/maps/documentation/places/ios-sdk) for full use of the SDK.
*   *Tutorial videos*: Watch code walkthroughs and useful tips on our [YouTube channel](https://www.youtube.com/playlist?list=PL2rFahu9sLJ3Rob1Vb5O4qX4U8-0FeXqJ).
*   *Code samples*: In order to try out our demo app, use:

    ```
    $ pod try GooglePlaces
    ```

    and follow the instructions on our [samples documentation](https://developers.google.com/maps/documentation/places/ios-sdk/code-samples).

*   *Support*: Ask the community or get help from Google using the links on the Places SDK for iOS [support page](https://developers.google.com/maps/documentation/places/ios-sdk/support).

*   *Report issues*: Use our issue tracker to [file a bug](https://issuetracker.google.com/issues/new?component=188842&template=788908)
    or a [feature request](https://issuetracker.google.com/issues/new?component=188842&template=788212).

# License and Terms of Service

By using the Google Places SDK for iOS you accept Google's Terms of Service and
Policies. Pay attention particularly to the following aspects:

*   Depending on your app and use case, you may be required to display
    attribution. Read more about [attribution requirements](https://developers.google.com/maps/documentation/places/ios-sdk/attributions).
*   Be sure to understand [usage and billing](https://developers.google.com/maps/documentation/places/ios-sdk/usage-and-billing) information related to use of the Maps SDK for iOS.
*   The [Terms of Service](https://developers.google.com/maps/terms) are a
    comprehensive description of the legal contract that you enter with Google
    by using the Google Places SDK for iOS.

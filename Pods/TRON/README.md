

<p align="center">
  <img src="https://github.com/MLSDev/TRON/raw/main/TRON.png" />
</p>

![CI](https://github.com/MLSDev/TRON/workflows/CI/badge.svg)
[![codecov.io](https://codecov.io/github/MLSDev/TRON/coverage.svg?branch=main)](https://codecov.io/github/MLSDev/TRON?branch=main)
![CocoaPod platform](https://cocoapod-badges.herokuapp.com/p/TRON/badge.svg)
![CocoaPod version](https://cocoapod-badges.herokuapp.com/v/TRON/badge.svg)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Packagist](https://img.shields.io/packagist/l/doctrine/orm.svg)]()

TRON is a lightweight network abstraction layer, built on top of [Alamofire](https://github.com/Alamofire/Alamofire). It can be used to dramatically simplify interacting with RESTful JSON web-services.

## Features

- [x] Generic, protocol-based implementation
- [x] Built-in response and error parsing
- [x] Support for any custom mapper ([SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) implementation provided). Defaults to `Codable` protocol.
- [x] Support for upload tasks
- [x] Support for download tasks and resuming downloads
- [x] Robust plugin system
- [x] Stubbing of network requests
- [x] Modular architecture
- [x] Support for iOS/Mac OS X/tvOS/watchOS/Linux
- [x] Support for CocoaPods/Swift Package Manager
- [x] RxSwift extension
- [x] [Complete documentation](https://mlsdev.github.io/TRON/)

## Overview

We designed TRON to be simple to use and also very easy to customize. After initial setup, using TRON is very straightforward:

```swift
let request: APIRequest<User,APIError> = tron.codable.request("me")
request.perform(withSuccess: { user in
  print("Received User: \(user)")
}, failure: { error in
  print("User request failed, parsed error: \(error)")
})
```

## Requirements

- Xcode 10 and higher
- Swift 4 and higher
- iOS 10 / macOS 10.12 / tvOS 10.0 / watchOS 3.0

## Installation

### Swift Package Manager(requires Xcode 11)

* Add package into Project settings -> Swift Packages

TRON framework includes Codable implementation. To use SwiftyJSON, `import TRONSwiftyJSON` framework. To use RxSwift wrapper, `import RxTRON`.

### CocoaPods

```ruby
pod 'TRON', '~> 5.3.0'
```

Only Core subspec, without SwiftyJSON dependency:

```ruby
pod 'TRON/Core', '~> 5.3.0'
```

RxSwift extension for TRON:

```ruby
pod 'TRON/RxSwift', '~> 5.3.0'
```

## Migration Guides

- [TRON 5.0 Migration Guide](https://github.com/MLSDev/TRON/blob/main/Guides/5.0%20Migration%20Guide.md)
- [TRON 4.0 Migration Guide](https://github.com/MLSDev/TRON/blob/main/Guides/4.0%20Migration%20Guide.md)

## Project status

`TRON` is under active development by MLSDev Inc. Pull requests are welcome!

## Request building

`TRON` object serves as initial configurator for `APIRequest`, setting all base values and configuring to use with baseURL.

```swift
let tron = TRON(baseURL: "https://api.myapp.com/")
```

You need to keep strong reference to `TRON` object, because it holds Alamofire.Manager, that is running all requests.

### URLBuildable

`URLBuildable` protocol is used to convert relative path to URL, that will be used by request.

```swift
public protocol URLBuildable {
    func url(forPath path: String) -> URL
}
```

By default, `TRON` uses `URLBuilder` class, that simply appends relative path to base URL, which is sufficient in most cases. You can customize url building process globally by changing `urlBuilder` property on `TRON` or locally, for a single request by modifying `urlBuilder` property on `APIRequest`.

## Sending requests

To send `APIRequest`, call `perform(withSuccess:failure:)` method on `APIRequest`:

```swift
let alamofireRequest = request.perform(withSuccess: { result in }, failure: { error in})
```

Alternatively, you can use `performCollectingTimeline(withCompletion:)` method that contains `Alamofire.Response` inside completion closure:

```swift
request.performCollectingTimeline(withCompletion: { response in
    print(response.timeline)
    print(response.result)
})
```

In both cases, you can additionally chain `Alamofire.Request` methods, if you need:

```swift
request.perform(withSuccess: { result in }, failure: { error in }).progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
    print(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
}
```

## Response parsing

Generic `APIRequest` implementation allows us to define expected response type before request is even sent. On top of `Alamofire` `DataResponseSerializerProtocol`, we are adding one additional protocol for error-handling.

```swift
public protocol DataResponseSerializerProtocol {
    associatedtype SerializedObject

    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> Self.SerializedObject
}

public protocol ErrorSerializable: Error {
    init?(serializedObject: Any?, request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?)
}
```

### Codable

Parsing models using Swift4 `Codable` protocol is simple, implement `Codable` protocol:

```swift
struct User: Codable {
  let name : String
  let id: Int
}
```

And send a request:

```swift
let request: APIRequest<User,APIError> = tron.codable.request("me")
request.perform(withSuccess: { user in
  print("Received user: \(user.name) with id: \(user.id)")
})
```

It's possible to customize decoders for both model and error parsing:

```swift
let userDecoder = JSONDecoder()

let request : APIRequest<User,APIError> = tron.codable(modelDecoder: userDecoder).request("me")
```

### JSONDecodable

`TRON` provides `JSONDecodable` protocol, that allows us to parse models using [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON):

```swift
public protocol JSONDecodable {
    init(json: JSON) throws
}
```

To parse your response from the server using `SwiftyJSON`, all you need to do is to create `JSONDecodable` conforming type, for example:

```swift
class User: JSONDecodable {
  let name : String
  let id: Int

  required init(json: JSON) {
    name = json["name"].stringValue
    id = json["id"].intValue
  }
}
```

And send a request:

```swift
let request: APIRequest<User,MyAppError> = tron.swiftyJSON.request("me")
request.perform(withSuccess: { user in
  print("Received user: \(user.name) with id: \(user.id)")
})
```

There are also default implementations of `JSONDecodable` protocol for Swift built-in types like String, Int, Float, Double and Bool, so you can easily do something like this:

```swift
let request : APIRequest<String,APIError> = tron.swiftyJSON.request("status")
request.perform(withSuccess: { status in
    print("Server status: \(status)") //
})
```

You can also use `Alamofire.Empty` struct in cases where you don't care about actual response.

Some concepts for response serialization, including array response serializer, are described in [Container Types Parsing document](https://github.com/MLSDev/TRON/blob/main/Docs/ContainerTypesParsing.md)

It's possible to customize `JSONSerialization.ReadingOptions`, that are used by `SwiftyJSON.JSON` object while parsing data of the response:

```swift
let request : APIRequest<String, APIError> = tron.swiftyJSON(readingOptions: .allowFragments).request("status")
```

## RxSwift

```swift
let request : APIRequest<Foo, APIError> = tron.codable.request("foo")
_ = request.rxResult().subscribe(onNext: { result in
    print(result)
})
```

```swift
let multipartRequest : UploadAPIRequest<Foo,APIError> = tron.codable.uploadMultipart("foo", formData: { _ in })
multipartRequest.rxResult().subscribe(onNext: { result in
    print(result)
})
```

### Error handling

`TRON` includes built-in parsing for errors. `APIError` is an implementation of `ErrorSerializable` protocol, that includes several useful properties, that can be fetched from unsuccessful request:

```swift
request.perform(withSuccess: { response in }, failure: { error in
    print(error.request) // Original URLRequest
    print(error.response) // HTTPURLResponse
    print(error.data) // Data of response
    print(error.fileURL) // Downloaded file url, if this was a download request
    print(error.error) // Error from Foundation Loading system
    print(error.serializedObject) // Object that was serialized from network response
  })
```

## CRUD

```swift
struct Users
{
    static let tron = TRON(baseURL: "https://api.myapp.com")

    static func create() -> APIRequest<User,APIError> {
      return tron.codable.request("users").post()
    }

    static func read(id: Int) -> APIRequest<User, APIError> {
        return tron.codable.request("users/\(id)")
    }

    static func update(id: Int, parameters: [String:Any]) -> APIRequest<User, APIError> {
      return tron.codable.request("users/\(id)").put().parameters(parameters)
    }

    static func delete(id: Int) -> APIRequest<User,APIError> {
      return tron.codable.request("users/\(id)").delete()
    }
}
```

Using these requests is really simple:

```swift
Users.read(56).perform(withSuccess: { user in
  print("received user id 56 with name: \(user.name)")
})
```

It can be also nice to introduce namespacing to your API:

```swift
enum API {}
extension API {
  enum Users {
    // ...
  }
}
```

This way you can call your API methods like so:

```swift
API.Users.delete(56).perform(withSuccess: { user in
  print("user \(user) deleted")
})
```

## Stubbing

Stubbing is built right into `APIRequest` itself. All you need to stub a successful request is to set apiStub property and turn stubbingEnabled on:

```swift
API.Users.get(56)
         .stub(with: APIStub(data: User.fixture().asData))
         .perform(withSuccess: { stubbedUser in
           print("received stubbed User model: \(stubbedUser)")
})
```

Stubbing can be enabled globally on `TRON` object or locally for a single `APIRequest`. Stubbing unsuccessful requests is easy as well:

```swift
API.Users.get(56)
         .stub(with: APIStub(error: CustomError()))
         .perform(withSuccess: { _ in },
                  failure: { error in
  print("received stubbed api error")
})
```

You can also optionally delay stubbing time:

```swift
request.apiStub.stubDelay = 1.5
```

## Upload

* From file:

```swift
let request = tron.codable.upload("photo", fromFileAt: fileUrl)
```

* Data:

```swift
let request = tron.codable.upload("photo", data: data)
```

* Stream:

```swift
let request = tron.codable.upload("photo", fromStream: stream)
```

* Multipart-form data:

```swift
let request: UploadAPIRequest<EmptyResponse,MyAppError> = tron.codable.uploadMultipart("form") { formData in
    formData.append(data, withName: "cat", mimeType: "image/jpeg")
}
request.perform(withSuccess: { result in
    print("form sent successfully")
})
```

## Download

```swift
let responseSerializer = TRONDownloadResponseSerializer { _,_, url,_ in url }
let request: DownloadAPIRequest<URL?, APIError> = tron.download("file",
                                                                to: destination,
                                                                responseSerializer: responseSerializer)
```

## Plugins

`TRON` includes plugin system, that allows reacting to most of request events.

Plugins can be used globally, on `TRON` instance itself, or locally, on concrete `APIRequest`. Keep in mind, that plugins that are added to `TRON` instance, will be called for each request. There are some really cool use-cases for global and local plugins.

By default, no plugins are used, however two plugins are implemented as a part of `TRON` framework.

### NetworkActivityPlugin

`NetworkActivityPlugin` serves to monitor requests and control network activity indicator in iPhone status bar. This plugin assumes you have only one `TRON` instance in your application.

```swift
let tron = TRON(baseURL: "https://api.myapp.com", plugins: [NetworkActivityPlugin()])
```

### NetworkLoggerPlugin

`NetworkLoggerPlugin` is used to log responses to console in readable format. By default, it prints only failed requests, skipping requests that were successful.

### Local plugins

There are some very cool concepts for local plugins, some of them are described in dedicated [PluginConcepts](Docs/PluginConcepts.md) page.

## Alternatives

We are dedicated to building best possible tool for interacting with RESTful web-services. However, we understand, that every tool has it's purpose, and therefore it's always useful to know, what other tools can be used to achieve the same goal.

`TRON` was heavily inspired by [Moya framework](https://github.com/Moya/Moya) and LevelUPSDK, which is no longer available in open-source.

## License

`TRON` is released under the MIT license. See LICENSE for details.

## About MLSDev

[<img src="https://github.com/MLSDev/development-standards/raw/master/mlsdev-logo.png" alt="MLSDev.com">][mlsdev]

`TRON` is maintained by [MLSDev, Inc.][mlsdev] We specialize in providing all-in-one solution in mobile and web development. Our team follows Lean principles and works according to agile methodologies to deliver the best results reducing the budget for development and its timeline.

Find out more [here][mlsdev] and don't hesitate to [contact us][contact]!

[mlsdev]: https://mlsdev.com
[contact]: https://mlsdev.com/contact-us

# Interop Libraries for Google SDKs on Apple Platforms

This repository is for internal Google use only.

This repository contains interfaces (Objective-C or Swift Protocols) that allow Google SDKs, for
Apple platforms, to reliably interoperate with one another via weak dependencies. These interfaces
enable Google SDKs to depend on the features of another Google SDK while optionally installing the
dependent SDK only if specified by the client.

## Versioning

The major version of this SDK should always be 100. When a new interface is added, the minor version
should be incremented. Clients should always enable minor version updates from the required minimum
required minor version, `100.x`, e.g.:
- Swift Package Manager: `"100.x" ..< "101.0"`
- CocoaPods: `'~100.x'`

If a breaking change is ever required, it should be done by renaming the library to a new name in
this repo.

## Contributing

See [Contributing](CONTRIBUTING.md) for more information on contributing to the project.

## License

The contents of this repository is licensed under the
[Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

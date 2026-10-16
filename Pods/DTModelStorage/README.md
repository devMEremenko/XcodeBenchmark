![CI](https://github.com/DenTelezhkin/DTModelStorage/workflows/CI/badge.svg)
[![codecov.io](http://codecov.io/github/DenTelezhkin/DTModelStorage/coverage.svg?branch=main)](http://codecov.io/github/DenTelezhkin/DTModelStorage?branch=main)
[![CocoaPods compatible](https://img.shields.io/cocoapods/v/DTModelStorage.svg)](https://cocoapods.org/pods/DTModelStorage)
[![Platform](https://img.shields.io/cocoapods/p/DTModelStorage.svg?style=flat)](https://dentelezhkin.github.io/DTModelStorage)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Packagist](https://img.shields.io/packagist/l/doctrine/orm.svg)]()

DTModelStorage
==============

 Because this project main goal is to provide storage classes and mapping/event functionality for DTCollectionViewManager and DTTableViewManager, you should probably first read, why those two frameworks exist in the first place. This is described, for example, in [Why](https://github.com/DenTelezhkin/DTCollectionViewManager/blob/master/Documentation/Why.md) document of DTCollectionViewManager.

 Requirements
 ============

 * Xcode 13+
 * Swift 5.3+
 * iOS 11+ / tvOS 11+ / macCatalyst 13+

Installation
============

### Swift Package Manager

 * Add package into Project settings -> Swift Packages

### [CocoaPods](https://cocoapods.org):

    pod 'DTModelStorage'

## Storage classes

The goal of storage classes is to provide datasource models for UITableView/UICollectionView. Let's take UITableView, for example. It's datasource methods mostly relates on following:

* sections
* items in sections
* section headers and footers / supplementary views

`Storage` protocol builds upon those elements to define common interface for all storage classes. `SupplementaryStorage` protocol extends `Storage` to provide methods on supplementary models / headers/ footers.

Here are five `Storage` implementations provided by `DTModelStorage` and links to detailed documentation on them:

* [Memory storage](Documentation/Memory%20storage.md)
* [Single section storage](Documentation/Single%20section%20diffable%20storage.md)
* [Storage for diffable datasources](Documentation/Diffable%20datasource%20storage.md) ( iOS 13 / tvOS 13 and higher )
* [CoreData storage](Documentation/CoreData%20storage.md)
* [Realm storage](Documentation/Realm%20storage.md)

Please note, that all five storages support the same interface for handling supplementary models - supplementary providers. You can read more about them in [dedicated document](Documentation/Supplementary%20providers.md).

## ViewModelMapping and EventReaction

`ViewModelMapping` and `EventReaction` classes are a part of mapping system between data models and reusable views. You can read about how they are used and why in [DTCollectionViewManager Mapping document](https://github.com/DenTelezhkin/DTCollectionViewManager/blob/master/Documentation/Mapping.md) as well as [DTCollectionViewManager Events document](https://github.com/DenTelezhkin/DTCollectionViewManager/blob/master/Documentation/Events.md)

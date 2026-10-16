![CI](https://github.com/DenTelezhkin/DTTableViewManager/workflows/CI/badge.svg)
[![codecov.io](http://codecov.io/github/DenTelezhkin/DTTableViewManager/coverage.svg?branch=main)](http://codecov.io/github/DenTelezhkin/DTTableViewManager?branch=main)
![CocoaPod platform](https://cocoapod-badges.herokuapp.com/p/DTTableViewManager/badge.svg)
![CocoaPod version](https://cocoapod-badges.herokuapp.com/v/DTTableViewManager/badge.svg)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Packagist](https://img.shields.io/packagist/l/doctrine/orm.svg)]()

DTTableViewManager
================
## Features

- [x] Powerful mapping system between data models and cells, headers and footers
- [x] Automatic datasource and interface synchronization.
- [x] Flexible Memory/CoreData/Realm/diffable datasource storage options
- [x] Powerful compile-time safe events system, that covers all of UITableView delegate methods
- [x] Views created from code, XIB, or storyboard, automatic registration and dequeue
- [x] Can be used with UITableViewController, or UIViewController with UITableView
- [x] Unified syntax with [DTCollectionViewManager](https://github.com/DenTelezhkin/DTCollectionViewManager)
- [x] Support for SwiftUI - backed cells in iOS 13+ / tvOS 13+ / macCatalyst 13+
- [x] [Complete documentation](Documentation)
- [x] [API Reference](https://dentelezhkin.github.io/DTTableViewManager/)

## Requirements

* Xcode 13+
* iOS 11.0+ / tvOS 11.0+ / macCatalyst 13.0+
* Swift 5.3+

> If you need Xcode 11 support or Swift 4...Swift 5.2, or iOS 8...iOS 10 support, you can use 7.x releases.

## Installation

### Swift Package Manager

Add package into Xcode Project settings -> Swift Packages

### [CocoaPods](http://www.cocoapods.org):

    pod 'DTTableViewManager', '~> 11.0.0-beta.1'

## Quick start

Let's say you have an array of Posts you want to display in UITableView. To quickly show them using DTTableViewManager, here's what you need to do:

1. Create UITableViewCell subclass, let's say PostCell and adopt `ModelTransfer` protocol:

```swift
class PostCell : UITableViewCell, ModelTransfer {
    func update(with model: Post) {
        // Fill your cell with actual data
    }
}
```

2. In your view controller:

```swift
class PostsViewController: UITableViewController, DTTableViewManageable {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register PostCell to be used with this controller's table view
        manager.register(PostCell.self)

        // Populate datasource
        manager.memoryStorage.setItems(posts)
    }
}    
```

Make sure your UITableView outlet is wired to your class (or use UITableViewController subclass). If you have a PostCell.xib file, it will be automatically used for dequeueing PostCell.

3. That's it! It's that easy!

Of course, cool stuff does not stop there, framework supports all datasource and delegate methods as closures, conditional mappings and much much more! Choose what interests you in the next section of readme.

## Burning questions

###### Starter pack

* **[Why do I need this library?](Documentation/Why.md)**
* [How data models are mapped to cells?](Documentation/Mapping.md)
* [Can I show SwiftUI views in UITableViewCells?](Documentation/SwiftUI.md)
* [Can I use unsubclassed UITableViewCell or UITableViewHeaderFooterView?](Documentation/Mapping.md#without-modeltransfer)
* [How can I register views to dequeue from code/xib/storyboard?](Documentation/Registration.md)
* [How can I use the same cells differently in different places?](Documentation/Conditional%20mappings.md)
* [What datasource options do I have?(e.g. memory/CoreData/Realm/diffable datasources)](Documentation/Datasources.md)
* [How can I implement datasource/delegate methods from `UITableView`?](Documentation/Events.md)

###### Advanced

* [SwiftUI-backed cells](Documentation/SwiftUI.md)
* [Can I implement delegate methods instead of using DTTableViewManager event closures?](Documentation/Events.md#can-i-still-use-delegate-methods)
* [How can I react to and customize UITableView updates?](Documentation/TableViewUpdater.md)
* [What can be additionally configured when using DTTableViewManager with UITableView?](Documentation/TableViewConfiguration)
* [What if something goes wrong?](Documentation/Anomalies.md)

## Sample code and documentation

* [DTTableViewManager sample code](Example)
* [Documentation](Documentation)
* [Sample code for Drag&Drop integration](https://github.com/DenTelezhkin/DTDragAndDropExample)

## Thanks

* [Alexey Belkevich](https://github.com/belkevich) for providing initial implementation of CellFactory.
* [Michael Fey](https://github.com/MrRooni) for providing insight into NSFetchedResultsController updates done right.
* [Nickolay Sheika](https://github.com/hawk-ukr) for great feedback, that helped shaping 3.0 release and future direction of the library.
* [Artem Antihevich](https://github.com/sinarionn) for great discussions about Swift generics and type capturing.

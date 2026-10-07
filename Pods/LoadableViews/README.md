![CI](https://github.com/MLSDev/LoadableViews/workflows/CI/badge.svg)
[![codecov.io](http://codecov.io/github/MLSDev/LoadableViews/coverage.svg?branch=main)](http://codecov.io/github/MLSDev/LoadableViews?branch=main)
[![Platform](https://img.shields.io/cocoapods/p/LoadableViews.svg?style=flat)](https://mlsdev.github.io/LoadableViews)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/LoadableViews.svg)](https://img.shields.io/cocoapods/v/LoadableViews.svg)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Packagist](https://img.shields.io/packagist/l/doctrine/orm.svg)]()

# LoadableViews

Easiest way to load view classes into another XIB or storyboard.

![WTFCat](wtf_cat_designable.png)

## Basic setup

* Subclass your view from `LoadableView`
* Create a xib file, set File's Owner class to your class
* Link outlets as usual

## Usage

* Drop UIView to your XIB or storyboard
* Set it's class to your class name

Your view is automatically loaded to different xib!

## IBInspectable && IBDesignable

IBInspectables automatically render themselves if your view is IBDesignable. Usually Interface Builder is not able to automatically figure out that your view is IBDesignable, so you need to add this attribute to your view subclass:

```swift
  @IBDesignable class WTFCatView: LoadableView
```

## UI classes supported

- [x] UIView - `LoadableView`
- [x] UITableViewCell - `LoadableTableViewCell`
- [x] UICollectionViewCell - `LoadableCollectionViewCell`
- [x] UICollectionReusableView - `LoadableCollectionReusableView`
- [x] UITextField - `LoadableTextField`
- [x] NSView - `LoadableView` using `AppKit`

To use loading from xibs, for example for UICollectionViewCells, drop UIView instead of UICollectionViewCell in InterfaceBuilder, and follow basic setup. Then, on your storyboard, set a class of your cell, and it will be automatically updated.

## Customization

Change xib name

```swift
class CustomView : LoadableView {
  override var nibName : String {
    return "MyCustomXibName"
  }
}
```

Change view container

```swift
  class CustomViewWithLoadableContainerView : LoadableView {
    override var nibContainerView : UIView {
      return containerView
    }
  }
```

## Making your custom views loadable

* Adopt `NibLoadableProtocol` on your custom `UIView` or `NSView` subclass.
* Override `nibName` and `nibContainerView` properties, if necessary.
* Call `setupNib` method in both `init(frame:)` and `init(coder:)` methods.

## Known issues

* `IBDesignable` attribute is not recognized when it's inside framework due to bundle paths, which is why in current version you need to add `IBDesignable` attribute to your views manually.
* `UITableViewCell` and therefore `LoadableTableViewCell` cannot be made `IBDesignable`, because InterfaceBuilder uses `initWithFrame(_:)` method to render views: [radar](http://www.openradar.me/19901337), [stack overflow](http://stackoverflow.com/questions/26197582/is-there-a-way-for-interface-builder-to-render-ibdesignable-views-which-dont-ov)
* `UIScrollView` subclasses such as `UITextView` don't behave well with loadable views being inserted, which is why `UITextView` loadable subclass is not included in current release, but may be implemented in the future.

## Requirements

* iOS 8+
* tvOS 9.0+
* macOS 10.12+
* Swift 5 / 4.0 / 3.2

## Installation

#### CocoaPods

```ruby
  pod 'LoadableViews'
```

## License

`LoadableViews` is released under the MIT license. See LICENSE for details.

## About MLSDev

[<img src="https://github.com/MLSDev/development-standards/raw/master/mlsdev-logo.png" alt="MLSDev.com">][mlsdev]

`LoadableViews` are maintained by MLSDev, Inc. We specialize in providing all-in-one solution in mobile and web development. Our team follows Lean principles and works according to agile methodologies to deliver the best results reducing the budget for development and its timeline.

Find out more [here][mlsdev] and don't hesitate to [contact us][contact]!

[mlsdev]: https://mlsdev.com
[contact]: https://mlsdev.com/contact-us

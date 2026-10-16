// Copyright 2020 Google LLC. All rights reserved.
//
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
// file except in compliance with the License. You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
// ANY KIND, either express or implied. See the License for the specific language governing
// permissions and limitations under the License.

import GooglePlaces
import UIKit

struct AttributedPhoto {
  var image: UIImage
  var attributions: NSAttributedString
}

/// Represents a place photo, along with the attributions which are required to be displayed along
/// with it.
private class ImageAndAttributionView: UIView {
  private let margin: CGFloat = 30
  private let textViewHeight: CGFloat = 50

  lazy var imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 10
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  lazy var attributionView: UITextView = {
    let textView = UITextView()
    textView.delegate = self
    textView.isScrollEnabled = false
    textView.translatesAutoresizingMaskIntoConstraints = false
    return textView
  }()

  init(attributedPhoto: AttributedPhoto) {
    super.init(frame: .zero)
    addSubview(imageView)
    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: topAnchor, constant: margin),
      imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
      imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
    ])
    addSubview(attributionView)
    NSLayoutConstraint.activate([
      attributionView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: margin),
      attributionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margin),
      attributionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
      attributionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
      attributionView.heightAnchor.constraint(equalToConstant: textViewHeight),
    ])
    imageView.image = attributedPhoto.image
    attributionView.attributedText = attributedPhoto.attributions
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension ImageAndAttributionView: UITextViewDelegate {
  // Make links clickable.
  func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange)
    -> Bool
  {
    return true
  }
}

/// A horizontally-paging scroll view that displays a list of photo images and their attributions.
@objc(PagingPhotoView)
class PagingPhotoView: UIScrollView {
  private var pageViews: [ImageAndAttributionView] = []

  private var contentView = UIView()

  public var shouldRedraw = false

  func updatePhotos(_ photoList: [AttributedPhoto]) {
    // Reset state of pageViews and contentView
    pageViews = []
    contentView.removeFromSuperview()
    contentView = UIView()

    isPagingEnabled = true

    addSubview(contentView)

    // Generate page views, then add them to the scroll view's content view.
    for (index, photo) in photoList.enumerated() {
      let pageView = ImageAndAttributionView(attributedPhoto: photo)
      pageView.frame = CGRect(
        x: CGFloat(index) * frame.size.width, y: 0, width: frame.size.width,
        height: frame.size.height)
      pageViews.append(pageView)
      contentView.addSubview(pageView)
    }

    contentView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      contentView.topAnchor.constraint(equalTo: topAnchor),
      contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
      contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
      contentView.widthAnchor.constraint(
        equalToConstant: bounds.width * CGFloat(pageViews.count)),
      contentView.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    guard shouldRedraw else { return }

    shouldRedraw = false

    // Update `ImageAndAttributionView` frame after rotation.
    for (index, photoView) in pageViews.enumerated() {
      photoView.frame = CGRect(
        x: CGFloat(index) * frame.size.width, y: 0, width: frame.size.width,
        height: frame.size.height)
    }

    // Update contentSize.
    let originWidth = contentSize.width
    contentSize = CGSize(
      width: CGFloat(pageViews.count) * frame.size.width, height: frame.size.height)
    // Re-adjust the content offset to ensure the photos are aligned properly horizontally.
    if contentSize.width != 0 {
      let scrollOffset = (CGFloat)(round((contentOffset.x / originWidth) * 10) / 10)
      contentOffset = CGPoint(x: scrollOffset * contentSize.width, y: 0)
    }
  }
}

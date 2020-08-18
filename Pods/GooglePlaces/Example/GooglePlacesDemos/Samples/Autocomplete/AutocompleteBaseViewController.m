/*
 * Copyright 2016 Google LLC. All rights reserved.
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
 * file except in compliance with the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "GooglePlacesDemos/Samples/Autocomplete/AutocompleteBaseViewController.h"

#import "GooglePlacesDemos/Samples/PagingPhotoView.h"

@implementation AutocompleteBaseViewController {
  PagingPhotoView *_photoView;
  UIButton *_photoButton;
  UITextView *_textView;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  // Configure a background color.
  self.view.backgroundColor = [UIColor whiteColor];

  // Configure the UI. Tell our superclass we want a button and a result view below that.
  _photoButton =
      [self createButton:@selector(showPhotosButtonTapped)
                   title:NSLocalizedString(@"Demo.Title.Photos", @"Button title for 'Photos'")];

  // Create a text view.
  _textView = [[UITextView alloc] init];
  _textView.editable = NO;
  _textView.translatesAutoresizingMaskIntoConstraints = NO;
  [self addResultTextView];

  // Configure the photo view where we are going to display the loaded photos.
  _photoView = [[PagingPhotoView alloc] initWithFrame:self.view.bounds];
  _photoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.view addSubview:_photoView];

  // Reset the various views to their initial states.
  [self resetViews];
}

- (UIButton *)createShowAutocompleteButton:(SEL)selector {
  return [self createButton:selector
                      title:NSLocalizedString(@"Demo.Content.Autocomplete.ShowWidgetButton",
                                              @"Button title for 'show autocomplete widget'")];
}

- (NSString *)openStatusTextFromPlace:(GMSPlace *)place {
  GMSPlaceOpenStatus openStatus = [place isOpen];
  switch (openStatus) {
    case GMSPlaceOpenStatusOpen:
      return @"Open";
    case GMSPlaceOpenStatusClosed:
      return @"Closed";
    case GMSPlaceOpenStatusUnknown:
      return @"Unknown";
  }
}

- (void)autocompleteDidSelectPlace:(GMSPlace *)place {
  NSMutableAttributedString *text =
      [[NSMutableAttributedString alloc] initWithString:[place description]];
  [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"\nPlace status: "]];
  NSString *openStatusText = [self openStatusTextFromPlace:place];
  [text appendAttributedString:[[NSAttributedString alloc] initWithString:openStatusText]];
  NSAttributedString *attributions = place.attributions;
  if (attributions) {
    NSAttributedString *doubleReturn = [[NSAttributedString alloc] initWithString:@"\n\n"];
    [text appendAttributedString:doubleReturn];
    [text appendAttributedString:attributions];
  }
  _textView.attributedText = text;
  [_textView setIsAccessibilityElement:YES];
  [_textView setHidden:NO];

  // Show the photo button be start disabled until the photos have loaded.
  [_photoButton setIsAccessibilityElement:YES];
  [_photoButton setHidden:NO];
  [_photoButton setEnabled:NO];
  if (place.photos.count > 0) {
    [self preloadPhotoList:place.photos];
  }
}

- (void)autocompleteDidFail:(NSError *)error {
  NSString *formatString =
      NSLocalizedString(@"Demo.Content.Autocomplete.FailedErrorMessage",
                        @"Format string for 'autocomplete failed with error' message");
  _textView.text = [NSString stringWithFormat:formatString, error];
}

- (void)autocompleteDidCancel {
  _textView.text = NSLocalizedString(@"Demo.Content.Autocomplete.WasCanceledMessage",
                                     @"String for 'autocomplete canceled message'");
}

- (void)showCustomMessageInResultPane:(NSString *)message {
  _textView.text = message;
}

- (void)resetViews {
  _photoView.photoList = @[];
  [_textView setText:@""];
  [_textView setIsAccessibilityElement:NO];
  [_textView setHidden:NO];
  [_photoButton setIsAccessibilityElement:NO];
  [_photoButton setHidden:YES];
  [_photoView setHidden:YES];
}

#pragma mark - Private

- (void)addResultTextView {
  NSAssert(_textView.superview == nil, @"%s should not be called twice", sel_getName(_cmd));
  [self.view addSubview:_textView];

  // Check to see if we can use readableContentGuide from iOS 9+
  if ([self.view respondsToSelector:@selector(readableContentGuide)]) {
    // Position it horizontally so it fills the readableContentGuide. Use the new anchor-based
    // system because we know this code will only run on iOS 9+.
    [self.view.readableContentGuide.leadingAnchor constraintEqualToAnchor:_textView.leadingAnchor]
        .active = YES;
    [self.view.readableContentGuide.trailingAnchor constraintEqualToAnchor:_textView.trailingAnchor]
        .active = YES;
    // Set the textContainerInset to 0 because the readableContentGuide is already handling the
    // inset.
    _textView.textContainerInset = UIEdgeInsetsZero;
  } else {
    // Position it horizontally so it fills the parent.
    [self.view
        addConstraints:[NSLayoutConstraint
                           constraintsWithVisualFormat:@"H:|-(0)-[_textView]-(0)-|"
                                               options:0
                                               metrics:nil
                                                 views:NSDictionaryOfVariableBindings(_textView)]];
  }

  // If we have a view place it below that.
  [self.view addConstraints:[NSLayoutConstraint
                                constraintsWithVisualFormat:@"V:[_photoButton]-[_textView]-(0)-|"
                                                    options:0
                                                    metrics:nil
                                                      views:NSDictionaryOfVariableBindings(
                                                                _photoButton, _textView)]];
}

- (UIButton *)createButton:(SEL)selector title:(NSString *)title {
  // Create a button to show the autocomplete widget.
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  [button setTitle:title forState:UIControlStateNormal];
  [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:button];
  // Position the button from the top of the view.
  [NSLayoutConstraint constraintWithItem:button
                               attribute:NSLayoutAttributeTop
                               relatedBy:NSLayoutRelationEqual
                                  toItem:self.topLayoutGuide
                               attribute:NSLayoutAttributeBottom
                              multiplier:1
                                constant:8]
      .active = YES;
  // Centre it horizontally.
  [NSLayoutConstraint constraintWithItem:button
                               attribute:NSLayoutAttributeCenterX
                               relatedBy:NSLayoutRelationEqual
                                  toItem:self.view
                               attribute:NSLayoutAttributeCenterX
                              multiplier:1
                                constant:0]
      .active = YES;

  return button;
}

- (void)showPhotosButtonTapped {
  [_textView setIsAccessibilityElement:NO];
  [_textView setHidden:YES];
  [_photoButton setIsAccessibilityElement:NO];
  [_photoButton setHidden:YES];
  [_photoView setHidden:NO];
}

// Preload the photos to be displayed.
- (void)preloadPhotoList:(NSArray<GMSPlacePhotoMetadata *> *)photos {
  __block NSMutableArray *attributedPhotos = [NSMutableArray array];
  __block NSInteger photoRequestsInFlight = photos.count;
  for (GMSPlacePhotoMetadata *photo in photos) {
    [[GMSPlacesClient sharedClient] loadPlacePhoto:photo
                                          callback:^(UIImage *photoImage, NSError *error) {
                                            photoRequestsInFlight--;
                                            if (photoImage == nil) {
                                              NSLog(@"Photo request failed with error: %@", error);
                                            } else {
                                              AttributedPhoto *attributedPhoto =
                                                  [[AttributedPhoto alloc] init];
                                              attributedPhoto.image = photoImage;
                                              attributedPhoto.attributions = photo.attributions;
                                              [attributedPhotos addObject:attributedPhoto];
                                            }

                                            if (photoRequestsInFlight == 0) {
                                              _photoView.photoList = attributedPhotos;
                                              [_photoButton setEnabled:YES];
                                            }
                                          }];
  }
}

@end

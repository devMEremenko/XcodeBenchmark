// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <TargetConditionals.h>

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignInButton.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

#import "GoogleSignIn/Sources/GIDScopes.h"
#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Sources/GIDSignInStrings.h"
#import "GoogleSignIn/Sources/GIDSignIn_Private.h"
#import "GoogleSignIn/Sources/NSBundle+GID3PAdditions.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Constants

// Standard accessibility identifier.
static NSString *const kAccessibilityIdentifier = @"GIDSignInButton";

// The name of the font for button text.
static NSString *const kFontNameRobotoBold = @"Roboto-Bold";

// Button text font size.
static const CGFloat kFontSize = 14;

#pragma mark - Icon Constants

// The name of the image for the Google "G"
static NSString *const kGoogleImageName = @"google";

// Keys used for NSCoding.
static NSString *const kStyleKey = @"style";
static NSString *const kColorSchemeKey = @"color_scheme";
static NSString *const kButtonState = @"state";

#pragma mark - Sizing Constants

// The corner radius of the button
static const int kCornerRadius = 2;

// The standard height of the sign in button.
static const int kButtonHeight = 48;

// The width of the icon part of the button in points.
static const int kIconWidth = 40;

// Left and right text padding.
static const int kTextPadding = 14;

// The icon (UIImage)'s frame.
static const CGRect kIconFrame = { {9, 10}, {29, 30} };

#pragma mark - Appearance Constants

static const CGFloat kBorderWidth = 4;

static const CGFloat kHaloShadowAlpha = 12.0 / 100.0;
static const CGFloat kHaloShadowBlur = 2;

static const CGFloat kDropShadowAlpha = 24.0 / 100.0;
static const CGFloat kDropShadowBlur = 2;
static const CGFloat kDropShadowYOffset = 2;

static const CGFloat kDisabledIconAlpha = 40.0 / 100.0;

#pragma mark - Colors

// All colors in hex RGBA format (0xRRGGBBAA)

static const NSUInteger kColorGoogleBlue = 0x4285f4ff;
static const NSUInteger kColorGoogleDarkBlue = 0x3367d6ff;

static const NSUInteger kColorWhite = 0xffffffff;
static const NSUInteger kColorLightestGrey = 0x00000014;
static const NSUInteger kColorLightGrey = 0xeeeeeeff;
static const NSUInteger kColorDisabledGrey = 0x00000066;
static const NSUInteger kColorDarkestGrey = 0x00000089;

static NSUInteger kColors[12] = {
  // |Background|, |Foreground|,

  kColorGoogleBlue, kColorWhite,              // Dark Google Normal
  kColorLightestGrey, kColorDisabledGrey,     // Dark Google Disabled
  kColorGoogleDarkBlue, kColorWhite,          // Dark Google Pressed

  kColorWhite, kColorDarkestGrey,             // Light Google Normal
  kColorLightestGrey, kColorDisabledGrey,     // Light Google Disabled
  kColorLightGrey, kColorDarkestGrey,         // Light Google Pressed

};

// The state of the button:
typedef NS_ENUM(NSUInteger, GIDSignInButtonState) {
  kGIDSignInButtonStateNormal = 0,
  kGIDSignInButtonStateDisabled = 1,
  kGIDSignInButtonStatePressed = 2,
};
static NSUInteger const kNumGIDSignInButtonStates = 3;

// Used to lookup specific colors from the kColors table:
typedef NS_ENUM(NSUInteger, GIDSignInButtonStyleColor) {
  kGIDSignInButtonStyleColorBackground = 0,
  kGIDSignInButtonStyleColorForeground = 1,
};
static NSUInteger const kNumGIDSignInButtonStyleColors = 2;

// This method just pulls the correct value out of the kColors table and returns it as a UIColor.
static UIColor *colorForStyleState(GIDSignInButtonColorScheme style,
                                        GIDSignInButtonState state,
                                        GIDSignInButtonStyleColor color) {
  NSUInteger stateWidth = kNumGIDSignInButtonStyleColors;
  NSUInteger styleWidth = kNumGIDSignInButtonStates * stateWidth;
  NSUInteger index = (style * styleWidth) + (state * stateWidth) + color;
  NSUInteger colorValue = kColors[index];
  return [UIColor colorWithRed:(CGFloat)(((colorValue & 0xff000000) >> 24) / 255.0f) \
                         green:(CGFloat)(((colorValue & 0x00ff0000) >> 16) / 255.0f) \
                          blue:(CGFloat)(((colorValue & 0x0000ff00) >> 8) / 255.0f) \
                         alpha:(CGFloat)(((colorValue & 0x000000ff) >> 0) / 255.0f)];
}

#pragma mark - UIImage Category Forward Declaration

@interface UIImage (GIDAdditions_Private)

- (UIImage *)gid_imageWithBlendMode:(CGBlendMode)blendMode color:(UIColor *)color;

@end

#pragma mark - GIDSignInButton Private Properties

@interface GIDSignInButton ()

// The state (normal, pressed, disabled) of the button.
@property(nonatomic, assign) GIDSignInButtonState buttonState;

@end

#pragma mark -

@implementation GIDSignInButton {
  UIImageView *_icon;
}

#pragma mark - Object lifecycle

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self sharedInit];
  }
  return self;
}

- (void)sharedInit {
  self.clipsToBounds = YES;
  self.backgroundColor = [UIColor clearColor];

  // Accessibility settings:
  self.isAccessibilityElement = YES;
  self.accessibilityTraits = UIAccessibilityTraitButton;
  self.accessibilityIdentifier = kAccessibilityIdentifier;

  // Default style settings.
  _style = kGIDSignInButtonStyleStandard;
  _colorScheme = kGIDSignInButtonColorSchemeLight;
  _buttonState = kGIDSignInButtonStateNormal;

  // Icon for branding image:
  _icon = [[UIImageView alloc] initWithFrame:kIconFrame];
  _icon.contentMode = UIViewContentModeCenter;
  _icon.userInteractionEnabled = NO;
  [self addSubview:_icon];

  // Load font for "Sign in with Google" text
  [NSBundle gid_registerFonts];

  // Setup normal/highlighted state transitions:
  [self addTarget:self
                action:@selector(setNeedsDisplay)
      forControlEvents:UIControlEventAllTouchEvents];
  [self addTarget:self
                action:@selector(switchToPressed)
      forControlEvents:UIControlEventTouchDown |
                       UIControlEventTouchDragInside |
                       UIControlEventTouchDragEnter];
  [self addTarget:self
                action:@selector(switchToNormal)
      forControlEvents:UIControlEventTouchDragExit |
                       UIControlEventTouchDragOutside |
                       UIControlEventTouchCancel |
                       UIControlEventTouchUpInside];

  // Update the icon, etc.
  [self updateUI];
}

#pragma mark - NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self sharedInit];
    if ([aDecoder containsValueForKey:kStyleKey]) {
      _style = [aDecoder decodeIntegerForKey:kStyleKey];
    }
    if ([aDecoder containsValueForKey:kColorSchemeKey]) {
      _colorScheme = [aDecoder decodeIntegerForKey:kColorSchemeKey];
    }
    if ([aDecoder containsValueForKey:kButtonState]) {
      _buttonState = [aDecoder decodeIntegerForKey:kButtonState];
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeInteger:_style forKey:kStyleKey];
  [aCoder encodeInteger:_colorScheme forKey:kColorSchemeKey];
  [aCoder encodeInteger:_buttonState forKey:kButtonState];
}

#pragma mark - UI

- (void)updateUI {
  // Reload the icon.
  [self loadIcon];

  // Set a useful accessibility label here even if we're not showing text.
  // Get localized button text from bundle.
  self.accessibilityLabel = [self buttonText];

  // Force constrain frame sizes:
  [self setFrame:self.frame];

  [self setNeedsUpdateConstraints];
  [self setNeedsDisplay];
}

- (void)loadIcon {
  NSString *resourceName = kGoogleImageName;
  NSBundle *gidBundle = [NSBundle gid_frameworkBundle];
  NSString *resourcePath = [gidBundle pathForResource:resourceName ofType:@"png"];
  UIImage *image = [UIImage imageWithContentsOfFile:resourcePath];

  if (_buttonState == kGIDSignInButtonStateDisabled) {
    _icon.image = [image gid_imageWithBlendMode:kCGBlendModeMultiply
                                          color:[UIColor colorWithWhite:0
                                                                  alpha:kDisabledIconAlpha]];
  } else {
    _icon.image = image;
  }
}

#pragma mark - State Transitions

- (void)switchToPressed {
  [self setButtonState:kGIDSignInButtonStatePressed];
}

- (void)switchToNormal {
  [self setButtonState:kGIDSignInButtonStateNormal];
}

- (void)switchToDisabled {
  [self setButtonState:kGIDSignInButtonStateDisabled];
}

#pragma mark - Properties

- (void)setStyle:(GIDSignInButtonStyle)style {
  if (style == _style) {
    return;
  }
  _style = style;
  [self updateUI];
}

- (void)setColorScheme:(GIDSignInButtonColorScheme)colorScheme {
  if (colorScheme == _colorScheme) {
    return;
  }
  _colorScheme = colorScheme;
  [self updateUI];
}

- (void)setEnabled:(BOOL)enabled {
  if (enabled == self.enabled) {
    return;
  }
  [super setEnabled:enabled];
  if (enabled) {
    [self switchToNormal];
  } else {
    [self switchToDisabled];
  }
  [self updateUI];
}

- (void)setButtonState:(GIDSignInButtonState)buttonState {
  if (buttonState == _buttonState) {
    return;
  }
  _buttonState = buttonState;
  [self setNeedsDisplay];
}

- (void)setFrame:(CGRect)frame {
  // Constrain the frame size to sizes we want.
  frame.size = [self sizeThatFits:frame.size];
  if (CGRectEqualToRect(frame, self.frame)) {
    return;
  }
  [super setFrame:frame];
  [self setNeedsUpdateConstraints];
  [self setNeedsDisplay];
}

#pragma mark - Helpers

- (CGFloat)minWidth {
  if (_style == kGIDSignInButtonStyleIconOnly) {
    return kIconWidth + (kBorderWidth * 2);
  }
  NSString *text = [self buttonText];
  CGSize textSize = [[self class] textSize:text withFont:[[self class] buttonTextFont]];
  return ceil(kIconWidth + (kTextPadding * 2) + textSize.width + (kBorderWidth * 2));
}

- (BOOL)isConstraint:(NSLayoutConstraint *)constraintA
    equalToConstraint:(NSLayoutConstraint *)constraintB {
  return constraintA.priority == constraintB.priority &&
      constraintA.firstItem == constraintB.firstItem &&
      constraintA.firstAttribute == constraintB.firstAttribute &&
      constraintA.relation == constraintB.relation &&
      constraintA.secondItem == constraintB.secondItem &&
      constraintA.secondAttribute == constraintB.secondAttribute &&
      constraintA.multiplier == constraintB.multiplier &&
      constraintA.constant == constraintB.constant;
}

#pragma mark - Overrides

- (CGSize)sizeThatFits:(CGSize)size {
  switch (_style) {
    case kGIDSignInButtonStyleIconOnly:
      return CGSizeMake([self minWidth], kButtonHeight);
    case kGIDSignInButtonStyleStandard:
    case kGIDSignInButtonStyleWide: {
      return CGSizeMake(MAX(size.width, [self minWidth]), kButtonHeight);
    }
  }
}

- (void)updateConstraints {
  NSLayoutRelation widthConstraintRelation;
  // For icon style, we want to ensure a fixed width
  if (_style == kGIDSignInButtonStyleIconOnly) {
    widthConstraintRelation = NSLayoutRelationEqual;
  } else {
    widthConstraintRelation = NSLayoutRelationGreaterThanOrEqual;
  }
  // Define a width constraint ensuring that we don't go below our minimum width
  NSLayoutConstraint *widthConstraint =
      [NSLayoutConstraint constraintWithItem:self
                                   attribute:NSLayoutAttributeWidth
                                   relatedBy:widthConstraintRelation
                                      toItem:nil
                                   attribute:NSLayoutAttributeNotAnAttribute
                                  multiplier:1.0
                                    constant:[self minWidth]];
  widthConstraint.identifier = @"buttonWidth - auto generated by GIDSignInButton";
  // Define a height constraint using our constant height
  NSLayoutConstraint *heightConstraint =
      [NSLayoutConstraint constraintWithItem:self
                                   attribute:NSLayoutAttributeHeight
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:nil
                                   attribute:NSLayoutAttributeNotAnAttribute
                                  multiplier:1.0
                                    constant:kButtonHeight];
  heightConstraint.identifier = @"buttonHeight - auto generated by GIDSignInButton";
  // By default, add our width and height constraints
  BOOL addWidthConstraint = YES;
  BOOL addHeightConstraint = YES;

  for (NSLayoutConstraint *constraint in self.constraints) {
    // If it is equivalent to our width or height constraint, don't add ours later
    if ([self isConstraint:constraint equalToConstraint:widthConstraint]) {
      addWidthConstraint = NO;
      continue;
    }
    if ([self isConstraint:constraint equalToConstraint:heightConstraint]) {
      addHeightConstraint = NO;
      continue;
    }
    if (constraint.firstItem == self) {
      // If it is a height constraint of any relation, remove it
      if (constraint.firstAttribute == NSLayoutAttributeHeight) {
        [self removeConstraint:constraint];
      }
      // If it is a width constraint of any relation, remove it if it will conflict with ours
      if (constraint.firstAttribute == NSLayoutAttributeWidth &&
          (constraint.constant < [self minWidth] || _style == kGIDSignInButtonStyleIconOnly)) {
        [self removeConstraint:constraint];
      }
    }
  }

  if (addWidthConstraint) {
    [self addConstraint:widthConstraint];
  }
  if (addHeightConstraint) {
    [self addConstraint:heightConstraint];
  }
  [super updateConstraints];
}

#pragma mark - Rendering

- (void)drawRect:(CGRect)rect {
  [super drawRect:rect];

  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextRetain(context);

  if (context == NULL) {
    return;
  }

  // Draw the button background
  [self drawButtonBackground:context];

  // Draw the text
  [self drawButtonText:context];

  CGContextRelease(context);
  context = NULL;
}

#pragma mark - Button Background Rendering

- (void)drawButtonBackground:(CGContextRef)context {
  CGContextSaveGState(context);

  // Normalize the coordinate system of our graphics context
  // (0,0) -----> +x
  // |
  // |
  // \/ +y
  CGContextScaleCTM(context, 1, -1);
  CGContextTranslateCTM(context, 0, -self.bounds.size.height);

  // Get the colors for the current state and configuration
  UIColor *background = colorForStyleState(_colorScheme,
                                           _buttonState,
                                           kGIDSignInButtonStyleColorBackground);

  // Create rounded rectangle for button background/outline
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathAddRoundedRect(path,
                       NULL,
                       CGRectInset(self.bounds, kBorderWidth, kBorderWidth),
                       kCornerRadius,
                       kCornerRadius);

  // Fill the background and apply halo shadow
  CGContextSaveGState(context);
  CGContextAddPath(context, path);
  CGContextSetFillColorWithColor(context, background.CGColor);
  // If we're not in the disabled state, we want a shadow
  if (_buttonState != kGIDSignInButtonStateDisabled) {
    // Draw halo shadow around button
    CGContextSetShadowWithColor(context,
                                CGSizeMake(0, 0),
                                kHaloShadowBlur,
                                [UIColor colorWithWhite:0 alpha:kHaloShadowAlpha].CGColor);
  }
  CGContextFillPath(context);
  CGContextRestoreGState(context);

  if (_buttonState != kGIDSignInButtonStateDisabled) {
    // Fill the background again to apply drop shadow
    CGContextSaveGState(context);
    CGContextAddPath(context, path);
    CGContextSetFillColorWithColor(context, background.CGColor);
    CGContextSetShadowWithColor(context,
                                CGSizeMake(0, kDropShadowYOffset),
                                kDropShadowBlur,
                                [UIColor colorWithWhite:0 alpha:kDropShadowAlpha].CGColor);
    CGContextFillPath(context);
    CGContextRestoreGState(context);
  }

  if (_colorScheme == kGIDSignInButtonColorSchemeDark &&
      _buttonState != kGIDSignInButtonStateDisabled) {
    // Create rounded rectangle container for the "G"
    CGMutablePathRef gContainerPath = CGPathCreateMutable();
    CGPathAddRoundedRect(gContainerPath,
                         NULL,
                         CGRectInset(CGRectMake(0, 0, kButtonHeight, kButtonHeight),
                                     kBorderWidth + 1,
                                     kBorderWidth + 1),
                         kCornerRadius,
                         kCornerRadius);
    CGContextAddPath(context, gContainerPath);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillPath(context);
    CGPathRelease(gContainerPath);
  }

  CGPathRelease(path);
  CGContextRestoreGState(context);
}

#pragma mark - Text Rendering

- (void)drawButtonText:(CGContextRef)context {
  if (_style == kGIDSignInButtonStyleIconOnly) {
    return;
  }

  NSString *text = self.accessibilityLabel;

  UIColor *foregroundColor = colorForStyleState(_colorScheme,
                                                _buttonState,
                                                kGIDSignInButtonStyleColorForeground);
  UIFont *font = [[self class] buttonTextFont];
  CGSize textSize = [[self class] textSize:text withFont:font];

  // Draw the button text at the right position with the right color.
  CGFloat textLeft = kIconWidth + kTextPadding;
  CGFloat textTop = round((self.bounds.size.height - textSize.height) / 2);

  [text drawAtPoint:CGPointMake(textLeft, textTop)
      withAttributes:@{ NSFontAttributeName : font,
                        NSForegroundColorAttributeName : foregroundColor }];
}

#pragma mark - Button Text Selection / Localization

- (NSString *)buttonText {
  switch (_style) {
    case kGIDSignInButtonStyleWide:
      return [GIDSignInStrings signInWithGoogleString];
    case kGIDSignInButtonStyleStandard:
    case kGIDSignInButtonStyleIconOnly:
      return [GIDSignInStrings signInString];
  }
}

+ (UIFont *)buttonTextFont {
  UIFont *font = [UIFont fontWithName:kFontNameRobotoBold size:kFontSize];
  if (!font) {
    font = [UIFont boldSystemFontOfSize:kFontSize];
  }
  return font;
}

+ (CGSize)textSize:(NSString *)text withFont:(UIFont *)font {
  return [text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                            options:0
                         attributes:@{ NSFontAttributeName : font }
                            context:nil].size;
}

@end

#pragma mark - UIImage GIDAdditions_Private Category

@implementation UIImage (GIDAdditions_Private)

- (UIImage *)gid_imageWithBlendMode:(CGBlendMode)blendMode color:(UIColor *)color {
  CGSize size = [self size];
  CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);

  UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetShouldAntialias(context, true);
  CGContextSetInterpolationQuality(context, kCGInterpolationHigh);

  CGContextScaleCTM(context, 1, -1);
  CGContextTranslateCTM(context, 0, -rect.size.height);

  CGContextClipToMask(context, rect, self.CGImage);
  CGContextDrawImage(context, rect, self.CGImage);

  CGContextSetBlendMode(context, blendMode);

  CGFloat alpha = 1.0;
  if (blendMode == kCGBlendModeMultiply) {
    CGFloat red, green, blue;
    BOOL success = [color getRed:&red green:&green blue:&blue alpha:&alpha];
    if (success) {
      color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
    } else {
      CGFloat grayscale;
      success = [color getWhite:&grayscale alpha:&alpha];
      if (success) {
        color = [UIColor colorWithWhite:grayscale alpha:1.0];
      }
    }
  }

  CGContextSetFillColorWithColor(context, color.CGColor);
  CGContextFillRect(context, rect);

  if (blendMode == kCGBlendModeMultiply && alpha != 1.0) {
    // Modulate by the alpha.
    color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:alpha];
    CGContextSetBlendMode(context, kCGBlendModeDestinationIn);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
  }

  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  if (self.capInsets.bottom > 0 || self.capInsets.top > 0 ||
      self.capInsets.left > 0 || self.capInsets.left > 0) {
    image = [image resizableImageWithCapInsets:self.capInsets];
  }

  return image;
}

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

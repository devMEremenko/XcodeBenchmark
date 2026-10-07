//
//  VKShareDialogController.m
//
//  Copyright (c) 2014 VK.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <SafariServices/SafariServices.h>

#import "VKShareDialogController.h"
#import "VKBundle.h"
#import "VKUtil.h"
#import "VKApi.h"
#import "VKSdk.h"
#import "VKHTTPClient.h"
#import "VKHTTPOperation.h"
#import "VKSharedTransitioningObject.h"


///----------------------------
/// @name Attachment cells
///----------------------------

@interface VKPhotoAttachmentCell : UICollectionViewCell
@property(nonatomic, strong) UIProgressView *progressView;
@property(nonatomic, strong) UIActivityIndicatorView *activity;
@property(nonatomic, strong) UIImageView *attachImageView;
@end

@implementation VKPhotoAttachmentCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    self.attachImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame))];
    self.attachImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:self.attachImageView];

    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(5, CGRectGetHeight(frame) - 20, CGRectGetWidth(frame) - 10, 10)];
    self.progressView.hidden = YES;
    [self.contentView addSubview:self.progressView];

    self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activity.frame = CGRectMake(roundf((frame.size.width - self.activity.frame.size.width) / 2),
            roundf((frame.size.height - self.activity.frame.size.height) / 2),
            self.activity.frame.size.width,
            self.activity.frame.size.height);
    self.activity.hidesWhenStopped = YES;
    [self addSubview:self.activity];

    return self;
}

- (void)setProgress:(CGFloat)progress {
    if (progress > 0) {
        self.activity.hidden = YES;
        self.progressView.hidden = NO;
        self.progressView.progress = progress;
    } else {
        self.activity.hidden = NO;
        [self.activity startAnimating];
    }
}

- (void)hideProgress {
    self.progressView.hidden = YES;
    [self.activity stopAnimating];
}

@end

@interface VKUploadingAttachment : VKObject
@property(nonatomic, assign) BOOL isDownloading;
@property(nonatomic, assign) CGSize attachSize;
@property(nonatomic, strong) NSString *attachmentString;
@property(nonatomic, strong) UIImage *preview;
@property(nonatomic, weak) VKRequest *uploadingRequest;
@end


@implementation VKUploadingAttachment
@end

///----------------------------
/// @name Privacy settings class
///----------------------------
@interface VKPostSettings : VKObject
@property(nonatomic, strong) NSNumber *friendsOnly;
@property(nonatomic, strong) NSNumber *exportTwitter;
@property(nonatomic, strong) NSNumber *exportFacebook;
@property(nonatomic, strong) NSNumber *exportLivejournal;
@end

@implementation VKPostSettings
@end

@interface VKShareSettingsController : UITableViewController
@property(nonatomic, strong) VKPostSettings *currentSettings;
@property(nonatomic, strong) NSArray *rows;

- (instancetype)initWithPostSettings:(VKPostSettings *)settings;
@end

@interface VKShareDialogControllerInternal : UIViewController <UITextViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, VKSdkDelegate, VKSdkUIDelegate>
@property(nonatomic, weak) VKShareDialogController *parent;
@property(nonatomic, readonly) UICollectionView *attachmentsScrollView;
@property(nonatomic, strong) UIBarButtonItem *sendButton;
@property(nonatomic, strong) NSMutableArray *attachmentsArray;
@property(nonatomic, strong) VKPostSettings *postSettings;
@property(nonatomic, assign) BOOL prepared;

@property(nonatomic, weak) id <VKSdkUIDelegate> oldDelegate;
@end

@interface VKHelperNavigationController : UINavigationController
@end

@class VKPlaceholderTextView;
@class VKLinkAttachView;

@interface VKShareDialogView : UIView <UITextViewDelegate>
@property(nonatomic, strong) UIView *notAuthorizedView;
@property(nonatomic, strong) UILabel *notAuthorizedLabel;
@property(nonatomic, strong) UIButton *notAuthorizedButton;
@property(nonatomic, strong) UIScrollView *contentScrollView;
@property(nonatomic, strong) UIButton *privacyButton;
@property(nonatomic, strong) UICollectionView *attachmentsCollection;
@property(nonatomic, strong) VKPlaceholderTextView *textView;
@property(nonatomic, strong) VKLinkAttachView *linkAttachView;
@property(nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@end

///-------------------------------
/// @name Presentation view controller for dialog
///-------------------------------

static const CGFloat ipadWidth = 500.f;
static const CGFloat ipadHeight = 500.f;

@interface VKShareDialogController ()
@property(nonatomic, strong, readonly) UINavigationController *internalNavigation;
@property(nonatomic, strong, readonly) VKSharedTransitioningObject *transitionDelegate;
@property(nonatomic, strong, readonly) VKShareDialogControllerInternal *targetShareDialog;
@property(nonatomic, copy, readwrite) NSString *postId;
@end

@implementation VKShareDialogController {

    UIBarStyle defaultBarStyle;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

+ (void)initialize {
    if ([self class] == [VKShareDialogController class]) {
        UINavigationBar <UIAppearanceContainer> *appearance = [UINavigationBar appearanceWhenContainedIn:[VKHelperNavigationController class], nil];
        appearance.barStyle = UIBarStyleDefault;

        [appearance setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        [appearance setShadowImage:nil];
        [appearance setTitleTextAttributes:nil];

        [[UIBarButtonItem appearanceWhenContainedIn:[VKHelperNavigationController class], nil] setTitleTextAttributes:nil forState:UIControlStateNormal];
        [[UIBarButtonItem appearanceWhenContainedIn:[VKHelperNavigationController class], nil] setTitleTextAttributes:nil forState:UIControlStateHighlighted];

        [[UIActivityIndicatorView appearanceWhenContainedIn:[VKHelperNavigationController class], nil] setColor:nil];
    }
}

#pragma clang diagnostic pop

- (instancetype)init {
    if (self = [super init]) {
        _internalNavigation = [[VKHelperNavigationController alloc] initWithRootViewController:_targetShareDialog = [VKShareDialogControllerInternal new]];

        _targetShareDialog.parent = self;

        [self addChildViewController:self.internalNavigation];

        _requestedScope = ([VKSdk accessToken] && [VKSdk accessToken].permissions.count > 0) ? [VKSdk accessToken].permissions : @[VK_PER_WALL, VK_PER_PHOTOS];
#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"
        if ([VKUtil isOperatingSystemAtLeastIOS7]) {
            _transitionDelegate = [VKSharedTransitioningObject new];
            self.modalPresentationStyle = UIModalPresentationCustom;
            self.transitioningDelegate = _transitionDelegate;
            self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        }
#pragma clang diagnostic pop
        if (VK_IS_DEVICE_IPAD) {
            self.modalPresentationStyle = UIModalPresentationFormSheet;
        }
    }
    return self;
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4f];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view.autoresizesSubviews = NO;

    if (VK_IS_DEVICE_IPAD) {
        self.view.backgroundColor = [UIColor clearColor];
    } else {
        self.internalNavigation.view.layer.cornerRadius = 10;
        self.internalNavigation.view.layer.masksToBounds = YES;
    }
    [self.internalNavigation beginAppearanceTransition:YES animated:NO];
    [self.view addSubview:self.internalNavigation.view];
    [self.internalNavigation endAppearanceTransition];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (VK_IS_DEVICE_IPAD) {
        self.view.superview.layer.cornerRadius = 10.0;
        self.view.superview.layer.masksToBounds = YES;
    }
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"

- (CGSize)preferredContentSize {
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom]) {
        return CGSizeMake(ipadWidth, ipadHeight);
    }
    return [super preferredContentSize];
}

#pragma clang diagnostic pop

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self rotateToInterfaceOrientation:orientation appear:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self rotateToInterfaceOrientation:UIApplication.sharedApplication.statusBarOrientation appear:NO];
    } completion:nil];
}

- (void)rotateToInterfaceOrientation:(UIInterfaceOrientation)orientation appear:(BOOL)onAppear {
    if (VK_IS_DEVICE_IPAD) {
        CGSize viewSize = self.view.frame.size;
        if ([VKUtil isOperatingSystemAtLeastIOS8]) {
            viewSize.width = ipadWidth;
            viewSize.height = ipadHeight;
        }
        self.internalNavigation.view.frame = CGRectMake(0, 0, viewSize.width, viewSize.height);
        return;
    }


    static const CGFloat landscapeWidthCoef = 0.8f;
    static const CGFloat landscapeHeightCoef = 0.8f;
    static const CGFloat portraitWidthCoef = 0.9f;
    static const CGFloat portraitHeightCoef = 0.7f;


    CGSize selfSize = self.view.frame.size;
    CGSize viewSize;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        viewSize = CGSizeMake(ipadWidth, ipadHeight);
    } else {
        if (![VKUtil isOperatingSystemAtLeastIOS8]) {
            if (!onAppear && !UIInterfaceOrientationIsPortrait(orientation)) {
                CGFloat w = selfSize.width;
                selfSize.width = selfSize.height;
                selfSize.height = w;
            }
            if (![VKUtil isOperatingSystemAtLeastIOS7]) {
                viewSize = selfSize;
            } else {
                if (UIInterfaceOrientationIsLandscape(orientation)) {
                    viewSize = CGSizeMake(roundf(selfSize.width * landscapeWidthCoef), roundf(selfSize.height * landscapeHeightCoef));
                } else {
                    viewSize = CGSizeMake(roundf(selfSize.width * portraitWidthCoef), roundf(selfSize.height * portraitHeightCoef));
                }
            }
        } else {
            if (UIInterfaceOrientationIsLandscape(orientation)) {
                viewSize = CGSizeMake(roundf(selfSize.width * landscapeWidthCoef), roundf(selfSize.height * landscapeHeightCoef));
            } else {
                viewSize = CGSizeMake(roundf(selfSize.width * portraitWidthCoef), roundf(selfSize.height * portraitHeightCoef));
            }
        }
    }
    if ([VKUtil isOperatingSystemAtLeastIOS8] || onAppear || UIInterfaceOrientationIsPortrait(orientation)) {
        self.internalNavigation.view.frame = CGRectMake(roundf((CGRectGetWidth(self.view.frame) - viewSize.width) / 2),
                roundf((CGRectGetHeight(self.view.frame) - viewSize.height) / 2),
                viewSize.width, viewSize.height);
    } else if (UIInterfaceOrientationIsLandscape(orientation)) {
        self.internalNavigation.view.frame = CGRectMake(roundf((CGRectGetHeight(self.view.frame) - viewSize.width) / 2),
                roundf((CGRectGetWidth(self.view.frame) - viewSize.height) / 2),
                viewSize.width, viewSize.height);
    }
    if (![VKUtil isOperatingSystemAtLeastIOS7]) {
        if (self.presentingViewController.modalPresentationStyle != UIModalPresentationCurrentContext) {
            CGRect frame;
            frame.origin = CGPointZero;
            frame.size = selfSize;
            self.internalNavigation.view.frame = frame;
            self.internalNavigation.view.layer.cornerRadius = 3;
        }
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([VKUtil isOperatingSystemAtLeastIOS7]) {
        self.internalNavigation.navigationBar.barTintColor = VK_COLOR;
        self.internalNavigation.navigationBar.tintColor = [UIColor whiteColor];
        self.internalNavigation.automaticallyAdjustsScrollViewInsets = NO;
    }

}

#pragma clang diagnostic pop

- (void)setUploadImages:(NSArray *)uploadImages {
    _uploadImages = [uploadImages filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        BOOL result = [evaluatedObject isKindOfClass:[VKUploadImage class]];
        if (!result) {
            NSLog(@"Object %@ not accepted, because it must subclass VKUploadImage", evaluatedObject);
        }
        return result;
    }]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UINavigationBar appearance].barStyle = defaultBarStyle;
}
@end


///----------------------------
/// @name Placeholder textview for comment field
///----------------------------
/**
* Author: Jason George;
* Source: http://stackoverflow.com/a/1704469/1271424
*/
@interface VKPlaceholderTextView : UITextView

@property(nonatomic, strong) NSString *placeholder;
@property(nonatomic, strong) UIColor *placeholderColor;
@property(nonatomic, strong) UILabel *placeholderLabel;

- (void)textChanged:(NSNotification *)notification;

@end

@implementation VKPlaceholderTextView

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    if (!self.placeholder) {
        [self setPlaceholder:@""];
    }

    if (!self.placeholderColor) {
        [self setPlaceholderColor:[UIColor lightGrayColor]];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:nil];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setPlaceholder:@""];
        [self setPlaceholderColor:[UIColor lightGrayColor]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:nil];
    }
    return self;
}

- (void)textChanged:(NSNotification *)notification {
    if (notification.object != self) return;
    if (!self.placeholder.length) {
        return;
    }
    [self.self.placeholderLabel setHidden:self.text.length != 0];
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self.placeholderLabel setHidden:self.text.length != 0];
}

- (void)setPlaceholder:(NSString *)placeholder {
    _placeholder = placeholder;
    if (placeholder.length) {
        if (self.placeholderLabel == nil) {
            UIEdgeInsets inset = self.contentInset;
#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"
            if ([VKUtil isOperatingSystemAtLeastIOS7]) {
                inset = self.textContainerInset;
            }
#pragma clang diagnostic pop
            self.placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset.left + 4, inset.top, self.bounds.size.width - inset.left - inset.right, 0)];
            self.placeholderLabel.font = self.font;
            self.placeholderLabel.hidden = YES;
            self.placeholderLabel.textColor = self.placeholderColor;
            self.placeholderLabel.lineBreakMode = NSLineBreakByWordWrapping;
            self.placeholderLabel.numberOfLines = 0;
            self.placeholderLabel.backgroundColor = [UIColor clearColor];
            [self addSubview:self.placeholderLabel];
        }

        self.placeholderLabel.text = placeholder;
        [self.placeholderLabel sizeToFit];
        [self sendSubviewToBack:self.placeholderLabel];
    }

    if (self.text.length == 0 && placeholder.length) {
        [self.placeholderLabel setHidden:NO];
    }
}

/**
* iOS 7 text view measurement.
* Author: tarmes;
* Source: http://stackoverflow.com/a/19047464/1271424
*/
- (CGFloat)measureHeightOfUITextView {
    UITextView *textView = self;
#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"
    if ([VKUtil isOperatingSystemAtLeastIOS7]) {
        CGRect frame = textView.bounds;

        // Take account of the padding added around the text.

        UIEdgeInsets textContainerInsets = textView.textContainerInset;
        UIEdgeInsets contentInsets = textView.contentInset;

        CGFloat leftRightPadding = textContainerInsets.left + textContainerInsets.right + textView.textContainer.lineFragmentPadding * 2 + contentInsets.left + contentInsets.right;
        CGFloat topBottomPadding = textContainerInsets.top + textContainerInsets.bottom + contentInsets.top + contentInsets.bottom;

        frame.size.width -= leftRightPadding;
        frame.size.height -= topBottomPadding;

        NSString *textToMeasure = textView.text.length ? textView.text : _placeholder;
        if ([textToMeasure hasSuffix:@"\n"]) {
            textToMeasure = [NSString stringWithFormat:@"%@-", textView.text];
        }

        // NSString class method: boundingRectWithSize:options:attributes:context is
        // available only on ios7.0 sdk.

        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];

        NSDictionary *attributes = @{NSFontAttributeName : textView.font, NSParagraphStyleAttributeName : paragraphStyle};

        CGRect size = [textToMeasure boundingRectWithSize:CGSizeMake(CGRectGetWidth(frame), MAXFLOAT)
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:attributes
                                                  context:nil];

        CGFloat measuredHeight = ceilf(CGRectGetHeight(size) + topBottomPadding);
        return measuredHeight;
    }
#pragma clang diagnostic pop
    else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
        if (self.text.length && textView.contentSize.height > 0) {
            return MAX(textView.contentSize.height + self.contentInset.top + self.contentInset.bottom, 36.0f);
        }
        return [self.placeholder sizeWithFont:self.font constrainedToSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height + self.contentInset.top + self.contentInset.bottom;
#endif
    }
    return 0;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (![VKUtil isOperatingSystemAtLeastIOS7]) {
        CGSize size = self.contentSize;
        size.width = size.width - self.contentInset.left - self.contentInset.right;
        [self setContentSize:size];
    }

}
@end

///----------------------------
/// @name Special kind of button for privacy settings
///----------------------------

@interface VKPrivacyButton : UIButton
@end

@implementation VKPrivacyButton
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    CGFloat separatorHeight = 1 / [UIScreen mainScreen].scale;
    UIView *topSeparatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, separatorHeight)];
    topSeparatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [topSeparatorView setBackgroundColor:[VKUtil colorWithRGB:0xc8cacc]];
    [self addSubview:topSeparatorView];
    [self setImage:VKImageNamed(@"Disclosure") forState:UIControlStateNormal];
    [self setBackgroundColor:[VKUtil colorWithRGB:0xfafbfc]];
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];

    if (highlighted) {
        self.backgroundColor = [VKUtil colorWithRGB:0xd9d9d9];
    }
    else {
        self.backgroundColor = [VKUtil colorWithRGB:0xfafbfc];
    }
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    CGRect frame = [super imageRectForContentRect:contentRect];
    frame.origin.x = CGRectGetMaxX(contentRect) - CGRectGetWidth(frame) - self.imageEdgeInsets.right + self.imageEdgeInsets.left;
    return frame;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
    CGRect frame = [super titleRectForContentRect:contentRect];
    frame.origin.x = CGRectGetMinX(frame) - CGRectGetWidth([self imageRectForContentRect:contentRect]);
    return frame;
}
@end

@interface VKLinkAttachView : UIView
@property(nonatomic, strong) UILabel *linkTitle;
@property(nonatomic, strong) UILabel *linkHost;
@end

@implementation VKLinkAttachView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    _linkTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 21)];
    _linkTitle.font = [UIFont systemFontOfSize:16];
    _linkTitle.textColor = [VKUtil colorWithRGB:0x4978ad];
    _linkTitle.backgroundColor = [UIColor clearColor];
    _linkTitle.numberOfLines = 1;
    [self addSubview:_linkTitle];

    _linkHost = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 21)];
    _linkHost.font = [UIFont systemFontOfSize:16];
    _linkHost.textColor = [VKUtil colorWithRGB:0x999999];
    _linkHost.backgroundColor = [UIColor clearColor];
    _linkHost.numberOfLines = 1;
    [self addSubview:_linkHost];

    self.backgroundColor = [UIColor clearColor];

    return self;
}

- (void)sizeToFit {
    [self.linkTitle sizeToFit];
    self.linkTitle.frame = CGRectMake(0, 0, self.frame.size.width, self.linkHost.frame.size.height);
    [self.linkHost sizeToFit];
    self.linkHost.frame = CGRectMake(0, CGRectGetMaxY(self.linkTitle.frame) + 2, self.frame.size.width, self.linkHost.frame.size.height);
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, CGRectGetMaxY(self.linkHost.frame));
}

- (void)setTargetLink:(VKShareLink *)targetLink {
    self.linkTitle.text = [targetLink.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.linkHost.text = [targetLink.link.host stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [self sizeToFit];
}
@end

///-------------------------------
/// @name View for internal share dialog controller
///-------------------------------
static const CGFloat kAttachmentsViewSize = 100.0f;

@implementation VKShareDialogView {
    CGFloat lastTextViewHeight;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.backgroundColor = [VKUtil colorWithRGB:0xfafbfc];
    {
        //View for authorizing, adds only when user is not authorized
        _notAuthorizedView = [[UIView alloc] initWithFrame:self.bounds];
        _notAuthorizedView.backgroundColor = [UIColor clearColor];
        _notAuthorizedView.backgroundColor = [VKUtil colorWithRGB:0xf2f2f5];
        _notAuthorizedView.autoresizingMask = UIViewAutoresizingNone;
        _notAuthorizedView.autoresizesSubviews = NO;

        _notAuthorizedLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, CGRectGetWidth(_notAuthorizedView.frame) - 20, 0)];
        _notAuthorizedLabel.text = VKLocalizedString(@"UserNotAuthorized");
        _notAuthorizedLabel.font = [UIFont systemFontOfSize:15];
        _notAuthorizedLabel.textColor = [VKUtil colorWithRGB:0x737980];
        _notAuthorizedLabel.textAlignment = NSTextAlignmentCenter;
        _notAuthorizedLabel.numberOfLines = 0;
        _notAuthorizedLabel.backgroundColor = [UIColor clearColor];
        [_notAuthorizedView addSubview:_notAuthorizedLabel];

        _notAuthorizedButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 0, 34)];
        [_notAuthorizedButton setTitle:VKLocalizedString(@"Enter") forState:UIControlStateNormal];
        [_notAuthorizedButton setContentEdgeInsets:UIEdgeInsetsMake(4, 15, 4, 15)];
        _notAuthorizedButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [_notAuthorizedView addSubview:_notAuthorizedButton];

        UIImage *buttonBg = VKImageNamed(@"BlueBtn");
        buttonBg = [buttonBg stretchableImageWithLeftCapWidth:(NSInteger) floorf(buttonBg.size.width / 2) topCapHeight:(NSInteger) floorf(buttonBg.size.height / 2)];
        [_notAuthorizedButton setBackgroundImage:buttonBg forState:UIControlStateNormal];

        buttonBg = VKImageNamed(@"BlueBtn_pressed");
        buttonBg = [buttonBg stretchableImageWithLeftCapWidth:(NSInteger) floorf(buttonBg.size.width / 2) topCapHeight:(NSInteger) floorf(buttonBg.size.height / 2)];
        [_notAuthorizedButton setBackgroundImage:buttonBg forState:UIControlStateHighlighted];
        
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicator.center = self.center;
        _activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
        _activityIndicator.hidesWhenStopped = YES;
        [self addSubview:_activityIndicator];
    }

    _contentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    _contentScrollView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
    _contentScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _contentScrollView.scrollIndicatorInsets = _contentScrollView.contentInset;
    [self addSubview:_contentScrollView];

    _privacyButton = [[VKPrivacyButton alloc] initWithFrame:CGRectMake(0, frame.size.height - 44, frame.size.width, 44)];
    _privacyButton.titleLabel.font = [UIFont systemFontOfSize:16];
    _privacyButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    _privacyButton.contentEdgeInsets = UIEdgeInsetsMake(0, 14, 0, 14);
    _privacyButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_privacyButton setTitle:VKLocalizedString(@"PostSettings") forState:UIControlStateNormal];
    [_privacyButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self addSubview:_privacyButton];

    _textView = [[VKPlaceholderTextView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 36)];

    _textView.backgroundColor = [UIColor clearColor];
    _textView.textColor = [UIColor blackColor];
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"
    if ([VKUtil isOperatingSystemAtLeastIOS7]) {
        _textView.textContainerInset = UIEdgeInsetsMake(12, 10, 12, 10);
        _textView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    } else {
        _textView.frame = CGRectMake(0, 0, frame.size.width - 20, 36);
        _textView.contentInset = UIEdgeInsetsMake(12, 10, 12, 0);
    }
#pragma clang diagnostic pop
    _textView.font = [UIFont systemFontOfSize:16.0f];
    _textView.delegate = self;
    _textView.textAlignment = NSTextAlignmentLeft;
    _textView.returnKeyType = UIReturnKeyDone;
    _textView.placeholder = VKLocalizedString(@"NewMessageText");
    [_contentScrollView addSubview:_textView];

    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 12;

    _attachmentsCollection = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, kAttachmentsViewSize) collectionViewLayout:layout];
    _attachmentsCollection.contentInset = UIEdgeInsetsMake(0, 16, 0, 16);
    _attachmentsCollection.backgroundColor = [UIColor clearColor];
    _attachmentsCollection.showsHorizontalScrollIndicator = NO;
    [_attachmentsCollection registerClass:[VKPhotoAttachmentCell class] forCellWithReuseIdentifier:@"VKPhotoAttachmentCell"];
    [_contentScrollView addSubview:_attachmentsCollection];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (self.notAuthorizedView.superview) {
        self.notAuthorizedView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
        CGSize notAuthorizedTextBoundingSize = CGSizeMake(CGRectGetWidth(self.notAuthorizedView.frame) - 20, CGFLOAT_MAX);
        CGSize notAuthorizedTextSize = CGSizeMake(0,0);
#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"
        if ([VKUtil isOperatingSystemAtLeastIOS7]) {
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
            paragraphStyle.alignment = NSTextAlignmentLeft;

            NSDictionary *attributes = @{NSFontAttributeName : self.notAuthorizedLabel.font,
                    NSParagraphStyleAttributeName : paragraphStyle};


            notAuthorizedTextSize = [self.notAuthorizedLabel.text boundingRectWithSize:notAuthorizedTextBoundingSize
                                                                               options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                                            attributes:attributes
                                                                               context:nil].size;

        } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
            notAuthorizedTextSize = [_notAuthorizedLabel.text sizeWithFont:_notAuthorizedLabel.font
                                                         constrainedToSize:notAuthorizedTextBoundingSize
                                                             lineBreakMode:NSLineBreakByWordWrapping];
#endif
        }
#pragma clang diagnostic pop

        [self.notAuthorizedButton sizeToFit];

        self.notAuthorizedLabel.frame = CGRectMake(
                10,
                roundf((CGRectGetHeight(self.notAuthorizedView.frame) - notAuthorizedTextSize.height - CGRectGetHeight(self.notAuthorizedButton.frame)) / 2),
                notAuthorizedTextBoundingSize.width,
                roundf(notAuthorizedTextSize.height));

        self.notAuthorizedButton.frame = CGRectMake(
                roundf(self.notAuthorizedLabel.center.x) - roundf(CGRectGetWidth(self.notAuthorizedButton.frame) / 2),
                CGRectGetMaxY(self.notAuthorizedLabel.frame) + roundf(CGRectGetHeight(self.notAuthorizedButton.frame) / 2),
                CGRectGetWidth(self.notAuthorizedButton.frame),
                CGRectGetHeight(self.notAuthorizedButton.frame));
    }
    //Workaround for iOS 6 - ignoring contentInset.right
    self.textView.frame = CGRectMake(0, 0, self.frame.size.width - (![VKUtil isOperatingSystemAtLeastIOS7] ? 20 : 0), [self.textView measureHeightOfUITextView]);
    [self positionSubviews];
}

- (void)positionSubviews {
    lastTextViewHeight = self.textView.frame.size.height;
    self.attachmentsCollection.frame = CGRectMake(0, lastTextViewHeight, self.frame.size.width, [self.attachmentsCollection numberOfItemsInSection:0] ? kAttachmentsViewSize : 0);
    if (self.linkAttachView) {
        self.linkAttachView.frame = CGRectMake(14, CGRectGetMaxY(self.attachmentsCollection.frame) + 5, self.frame.size.width - 20, 0);
        [self.linkAttachView sizeToFit];
    }

    self.contentScrollView.contentSize = CGSizeMake(self.frame.size.width, self.linkAttachView ? CGRectGetMaxY(self.linkAttachView.frame) : CGRectGetMaxY(self.attachmentsCollection.frame));
}

- (void)textViewDidChange:(UITextView *)textView {
    CGFloat newHeight = [self.textView measureHeightOfUITextView];
    if (fabs(newHeight - lastTextViewHeight) > 1) {
        textView.frame = CGRectMake(0, 0, self.frame.size.width - (![VKUtil isOperatingSystemAtLeastIOS7] ? 20 : 0), newHeight);
        [textView layoutIfNeeded];
        [UIView animateWithDuration:0.2 animations:^{
            [self positionSubviews];
        }];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView endEditing:YES];
    }
    return YES;
}

- (void)setShareLink:(VKShareLink *)link {
    self.linkAttachView = [[VKLinkAttachView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 0)];
    self.linkAttachView.targetLink = link;
    [self.contentScrollView addSubview:self.linkAttachView];
    [self setNeedsLayout];
}

@end

///-------------------------------
/// @name Internal view controller, root for share dialog navigation controller
///-------------------------------

@implementation VKShareDialogControllerInternal {
    dispatch_queue_t imageProcessingQueue;
}

- (void)dealloc {
    [[VKSdk instance] unregisterDelegate:self];
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"

- (instancetype)init {
    self = [super init];
    if ([VKUtil isOperatingSystemAtLeastIOS7]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    imageProcessingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    return self;
}

#pragma clang diagnostic pop

- (void)loadView {
    VKShareDialogView *view = [[VKShareDialogView alloc] initWithFrame:CGRectMake(0, 0, ipadWidth, ipadHeight)];
    view.attachmentsCollection.delegate = self;
    view.attachmentsCollection.dataSource = self;
    [view.notAuthorizedButton addTarget:self action:@selector(authorize:) forControlEvents:UIControlEventTouchUpInside];
    [view.privacyButton addTarget:self action:@selector(openSettings:) forControlEvents:UIControlEventTouchUpInside];

    self.view = view;
}

- (UICollectionView *)attachmentsScrollView {
    VKShareDialogView *view = (VKShareDialogView *) self.view;
    return view.attachmentsCollection;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImage *image = [VKBundle vkLibraryImageNamed:@"ic_vk_logo_nb"];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:image];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close:)];
    [[VKSdk instance] registerDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (self.oldDelegate) {
        [VKSdk instance].uiDelegate = self.oldDelegate;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.prepared) return;
    VKShareDialogView *view = (VKShareDialogView *) self.view;
    view.textView.hidden = YES;
    [view.activityIndicator startAnimating];
    [VKSdk wakeUpSession:self.parent.requestedScope completeBlock:^(VKAuthorizationState state, NSError *error) {
        [self setAuthorizationState:state];
    }];
}

- (void)setAuthorizationState:(VKAuthorizationState) state {
    VKShareDialogView *view = (VKShareDialogView *) self.view;
    
    [view.activityIndicator stopAnimating];
    switch (state) {
        case VKAuthorizationAuthorized: {
            [self prepare];
            
            [view.notAuthorizedView removeFromSuperview];
            view.textView.hidden = NO;
            view.textView.text = self.parent.text;
            [view textViewDidChange:view.textView];
            break;
        }
        case VKAuthorizationPending: {
            [view.notAuthorizedView removeFromSuperview];
            [view.activityIndicator startAnimating];
            view.textView.hidden = YES;
            break;
        }
        default: {
            VKShareDialogView *view = (VKShareDialogView *) self.view;
            [view addSubview:view.notAuthorizedView];
            if ([VKSdk accessToken]) {
                view.notAuthorizedLabel.text = VKLocalizedString(@"UserHasNoRequiredPermissions");
                view.textView.hidden = YES;
            }
            [view setNeedsDisplay];
            break;
        }
    }
}

- (void)prepare {

    self.postSettings = [VKPostSettings new];
    [self createAttachments];
    [[[VKApi users] get:@{VK_API_FIELDS : @"first_name_acc,can_post,sex,exports"}] executeWithResultBlock:^(VKResponse *response) {
        VKUser *user = [response.parsedModel firstObject];
        //Set this flags as @0 to show in the interface
        self.postSettings.friendsOnly = @0;
        if (user.exports.twitter) {
            self.postSettings.exportTwitter = @0;
        }
        if (user.exports.facebook) {
            self.postSettings.exportFacebook = @0;
        }
        if (user.exports.livejournal) {
            self.postSettings.exportLivejournal = @0;
        }
    }                                                                                          errorBlock:nil];
    self.prepared = YES;

}

- (NSArray *)rightBarButtonItems {
    if (!self.sendButton) {
        self.sendButton = [[UIBarButtonItem alloc] initWithTitle:VKLocalizedString(@"Done") style:UIBarButtonItemStyleDone target:self action:@selector(sendMessage:)];
    }
    return @[self.sendButton];
}

- (void)close:(id)sender {
    __strong typeof(self.parent) parent = self.parent;
    if (parent.completionHandler != NULL) {
        parent.completionHandler(parent, VKShareDialogControllerResultCancelled);
    }
    if (parent.dismissAutomatically) {
        [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)sendMessage:(id)sender {
    UITextView *textView = ((VKShareDialogView *) self.view).textView;
    textView.editable = NO;
    [textView endEditing:YES];
    self.navigationItem.rightBarButtonItems = nil;
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activity];
    [activity startAnimating];

    NSMutableArray *attachStrings = [NSMutableArray arrayWithCapacity:_attachmentsArray.count];
    for (VKUploadingAttachment *attach in _attachmentsArray) {
        if (!attach.attachmentString) {
            [self performSelector:@selector(sendMessage:) withObject:sender afterDelay:1.0f];
            return;
        }
        [attachStrings addObject:attach.attachmentString];
    }
    __strong typeof(self.parent) parent = self.parent;
    if (parent.shareLink) {
        [attachStrings addObject:[parent.shareLink.link absoluteString]];
    }

    VKRequest *post = [[VKApi wall] post:@{VK_API_MESSAGE : textView.text ?: @"",
            VK_API_ATTACHMENTS : [attachStrings componentsJoinedByString:@","]}];
    NSMutableArray *exports = [NSMutableArray new];
    if (self.postSettings.friendsOnly.boolValue) [post addExtraParameters:@{VK_API_FRIENDS_ONLY : @1}];
    if (self.postSettings.exportTwitter.boolValue) [exports addObject:@"twitter"];
    if (self.postSettings.exportFacebook.boolValue) [exports addObject:@"facebook"];
    if (self.postSettings.exportLivejournal.boolValue) [exports addObject:@"livejournal"];
    if (exports.count) [post addExtraParameters:@{VK_API_SERVICES : [exports componentsJoinedByString:@","]}];

    [post executeWithResultBlock:^(VKResponse *response) {
        NSNumber *post_id = VK_ENSURE_NUM(response.json[@"post_id"]);
        if (post_id) {
            parent.postId = [NSString stringWithFormat:@"%@_%@", [VKSdk accessToken].userId, post_id];
        }
        if (parent.completionHandler != NULL) {
            parent.completionHandler(parent, VKShareDialogControllerResultDone);
        }
        if (parent.dismissAutomatically) {
            [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }                 errorBlock:^(NSError *error) {
        self.navigationItem.rightBarButtonItem = nil;
        self.navigationItem.rightBarButtonItems = [self rightBarButtonItems];
        textView.editable = YES;
        [textView becomeFirstResponder];
        
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
        [[[UIAlertView alloc] initWithTitle:nil message:VKLocalizedString(@"ErrorWhilePosting") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
#else
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:VKLocalizedString(@"ErrorWhilePosting") preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
#endif
    }];
}

- (void)openSettings:(id)sender {
    VKShareSettingsController *vc = [[VKShareSettingsController alloc] initWithPostSettings:self.postSettings];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)authorize:(id)sender {
    self.oldDelegate = [VKSdk instance].uiDelegate;

    [VKSdk instance].uiDelegate = self;
    [VKSdk authorize:self.parent.requestedScope];
}

#pragma mark - VK SDK Delegate

- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError {
    VKCaptchaViewController *captcha = [VKCaptchaViewController captchaControllerWithError:captchaError];
    [self.navigationController presentViewController:captcha animated:YES completion:nil];
}

- (void)vkSdkShouldPresentViewController:(UIViewController *)controller {
    if ([SFSafariViewController class] && [controller isKindOfClass:[SFSafariViewController class]]) {
        [self.navigationController presentViewController:controller animated:YES completion:nil];
    } else if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *) controller;
        UIViewController *target = nav.viewControllers[0];
        nav.viewControllers = @[];
        [self.navigationController pushViewController:target animated:YES];
    } else {
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)vkSdkAccessAuthorizationFinishedWithResult:(VKAuthorizationResult *)result {
    [self setAuthorizationState:result.state];
}

- (void)vkSdkAuthorizationStateUpdatedWithResult:(VKAuthorizationResult *)result {
    [self setAuthorizationState:result.state];
}

- (void)vkSdkUserAuthorizationFailed {
    [self setAuthorizationState:VKAuthorizationError];
}

#pragma mark -Attachments

- (void)createAttachments {
    self.navigationItem.rightBarButtonItems = [self rightBarButtonItems];

    CGFloat maxHeight = kAttachmentsViewSize;
    self.attachmentsArray = [NSMutableArray new];
    VKShareDialogView *shareDialogView = (VKShareDialogView *) self.view;
    //Attach and upload images
    __strong typeof(self.parent) parent = self.parent;
    for (VKUploadImage *img in parent.uploadImages) {
        if (!(img.imageData || img.sourceImage)) continue;
        CGSize size = img.sourceImage.size;
        size = CGSizeMake(MAX(floorf(size.width * maxHeight / size.height), 50.f), maxHeight);
        VKUploadingAttachment *attach = [VKUploadingAttachment new];
        attach.attachSize = size;
        attach.preview = [img.sourceImage vks_roundCornersImage:0.0f resultSize:size];
        [self.attachmentsArray addObject:attach];

        VKRequest *uploadRequest = [VKApi uploadWallPhotoRequest:img.sourceImage parameters:img.parameters userId:0 groupId:0];

        [uploadRequest setCompleteBlock:^(VKResponse *res) {
            VKPhoto *photo = [res.parsedModel firstObject];
            attach.attachmentString = photo.attachmentString;
            attach.uploadingRequest = nil;
            [self.attachmentsScrollView reloadData];
            [shareDialogView setNeedsLayout];
        }];
        [uploadRequest setErrorBlock:^(NSError *error) {
            NSLog(@"Error: %@", error.vkError);
            [self removeAttachIfExists:attach];
            attach.uploadingRequest = nil;
            [self.attachmentsScrollView reloadData];
            [shareDialogView setNeedsLayout];
        }];
        [uploadRequest start];
        attach.uploadingRequest = uploadRequest;
    }

    if (parent.vkImages.count) {
        NSMutableDictionary *attachById = [NSMutableDictionary new];
        for (NSString *photo in parent.vkImages) {
            NSAssert([photo isKindOfClass:[NSString class]], @"vkImages must contains only string photo ids");
            if (attachById[photo]) continue;
            VKUploadingAttachment *attach = [VKUploadingAttachment new];
            attach.attachSize = CGSizeMake(kAttachmentsViewSize, kAttachmentsViewSize);
            attach.attachmentString = [@"photo" stringByAppendingString:photo];
            attach.isDownloading = YES;
            [self.attachmentsArray addObject:attach];
            attachById[photo] = attach;
        }

        VKRequest *req = [VKRequest requestWithMethod:@"photos.getById" parameters:@{@"photos" : [parent.vkImages componentsJoinedByString:@","], @"photo_sizes" : @1} modelClass:[VKPhotoArray class]];
        __weak typeof(self) wself = self;
        [req executeWithResultBlock:^(VKResponse *res) {
            __strong typeof(self) self = wself;
            VKPhotoArray *photos = res.parsedModel;
            NSArray *requiredSizes = @[@"p", @"q", @"m"];
            for (VKPhoto *photo in photos) {
                NSString *photoSrc = nil;
                for (NSString *type in requiredSizes) {
                    photoSrc = [photo.sizes photoSizeWithType:type].src;
                    if (photoSrc) break;
                }
                if (!photoSrc) {
                    continue;
                }
                
                NSString *photoId = [NSString stringWithFormat:@"%@_%@", photo.owner_id, photo.id];
                VKUploadingAttachment *attach = attachById[photoId];
                
                [attachById removeObjectForKey:photoId];
                
                VKHTTPOperation *imageLoad = [[VKHTTPOperation alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:photoSrc]]];
                [imageLoad setCompletionBlockWithSuccess:^(VKHTTPOperation *operation, id responseObject) {
                    UIImage *result = [UIImage imageWithData:operation.responseData];
                    result = [result vks_roundCornersImage:0 resultSize:CGSizeMake(kAttachmentsViewSize, kAttachmentsViewSize)];
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        attach.preview = result;
                        attach.isDownloading = NO;
                        NSInteger index = [self.attachmentsArray indexOfObject:attach];
                        [self.attachmentsScrollView performBatchUpdates:^{
                            [self.attachmentsScrollView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
                        }                                    completion:nil];
                        
                    });
                    
                }                                failure:^(VKHTTPOperation *operation, NSError *error) {
                    [self removeAttachIfExists:attach];
                    [self.attachmentsScrollView reloadData];
                }];
                imageLoad.successCallbackQueue = self->imageProcessingQueue;
                [[VKHTTPClient getClient] enqueueOperation:imageLoad];
            }
            [self.attachmentsScrollView performBatchUpdates:^{
                for (VKUploadingAttachment *attach in attachById.allValues) {
                    NSUInteger index = [self.attachmentsArray indexOfObject:attach];
                    if (index != NSNotFound) {
                        [self.attachmentsArray removeObjectAtIndex:index];
                        [self.attachmentsScrollView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
                    }
                }
            }                                    completion:nil];
            [self.attachmentsScrollView reloadData];
        } errorBlock:^(NSError *error) {
            NSLog(@"%@", error);
        }];
    }
    [self.attachmentsScrollView reloadData];
    [shareDialogView setNeedsLayout];

    if (parent.shareLink) {
        [shareDialogView setShareLink:parent.shareLink];
    }
}

#pragma mark - UICollectionView work

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.attachmentsArray.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    VKUploadingAttachment *object = self.attachmentsArray[(NSUInteger) indexPath.item];
    return object.attachSize;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    VKUploadingAttachment *attach = self.attachmentsArray[(NSUInteger) indexPath.item];
    VKPhotoAttachmentCell *cell = (VKPhotoAttachmentCell *) [collectionView dequeueReusableCellWithReuseIdentifier:@"VKPhotoAttachmentCell" forIndexPath:indexPath];

    cell.attachImageView.image = attach.preview;
    VKRequest *request = attach.uploadingRequest;

    __weak VKPhotoAttachmentCell *weakCell = cell;
    [request setProgressBlock:^(VKProgressType progressType, long long bytesLoaded, long long bytesTotal) {
        if (bytesTotal < 0) {
            return;
        }
        weakCell.progress = bytesLoaded * 1.0f / bytesTotal;
    }];
    if (attach.isDownloading) {
        cell.progress = -1;
    }
    if (!attach.isDownloading && !request) {
        [cell hideProgress];
    }

    return cell;
}

- (void)removeAttachIfExists:(VKUploadingAttachment *)attach {
    NSInteger index = [self.attachmentsArray indexOfObject:attach];
    if (index != NSNotFound) {
        [self.attachmentsArray removeObjectAtIndex:(NSUInteger) index];
        [self.attachmentsScrollView reloadData];
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    self.sendButton.enabled = YES;
    if (!textView.text.length && !self.attachmentsArray.count) {
        self.sendButton.enabled = NO;
    }
}
@end

static NSString *const SETTINGS_FRIENDS_ONLY = @"FriendsOnly";
static NSString *const SETTINGS_TWITTER = @"ExportTwitter";
static NSString *const SETTINGS_FACEBOOK = @"ExportFacebook";
static NSString *const SETTINGS_LIVEJOURNAL = @"ExportLivejournal";

@implementation VKShareSettingsController

- (instancetype)initWithPostSettings:(VKPostSettings *)settings {
    self = [super init];
    self.currentSettings = settings;
    NSMutableArray *newRows = [NSMutableArray new];
    if (self.currentSettings.friendsOnly)
        [newRows addObject:SETTINGS_FRIENDS_ONLY];
    if (self.currentSettings.exportTwitter)
        [newRows addObject:SETTINGS_TWITTER];
    if (self.currentSettings.exportFacebook)
        [newRows addObject:SETTINGS_FACEBOOK];
    if (self.currentSettings.exportLivejournal)
        [newRows addObject:SETTINGS_LIVEJOURNAL];
    self.rows = newRows;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [UIView new];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
    UISwitch *switchView;
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SwitchCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
        switchView.tintColor = VK_COLOR;
        switchView.onTintColor = VK_COLOR;

        cell.accessoryView = switchView;

        [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    } else {
        switchView = (UISwitch *) cell.accessoryView;
    }
    NSString *currentRow = self.rows[(NSUInteger) indexPath.row];
    if ([currentRow isEqual:SETTINGS_FRIENDS_ONLY]) {
        switchView.on = self.currentSettings.friendsOnly.boolValue;
    } else {
        if ([currentRow isEqual:SETTINGS_TWITTER]) {
            switchView.on = self.currentSettings.exportTwitter.boolValue;
        } else if ([currentRow isEqual:SETTINGS_FACEBOOK]) {
            switchView.on = self.currentSettings.exportFacebook.boolValue;
        } else if ([currentRow isEqual:SETTINGS_LIVEJOURNAL]) {
            switchView.on = self.currentSettings.exportLivejournal.boolValue;
        }
        switchView.enabled = !self.currentSettings.friendsOnly.boolValue;
    }
    cell.textLabel.text = VKLocalizedString(currentRow);
    switchView.tag = 100 + indexPath.row;

    return cell;
}

- (void)switchChanged:(UISwitch *)sender {
    NSString *currentRow = self.rows[(NSUInteger) (sender.tag - 100)];
    if ([currentRow isEqual:SETTINGS_FRIENDS_ONLY]) {
        self.currentSettings.friendsOnly = @(sender.on);
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.3];
    } else if ([currentRow isEqual:SETTINGS_TWITTER]) {
        self.currentSettings.exportTwitter = @(sender.on);
    } else if ([currentRow isEqual:SETTINGS_FACEBOOK]) {
        self.currentSettings.exportFacebook = @(sender.on);
    } else if ([currentRow isEqual:SETTINGS_LIVEJOURNAL]) {
        self.currentSettings.exportLivejournal = @(sender.on);
    }
}

@end


@implementation VKShareLink

- (instancetype)initWithTitle:(NSString *)title link:(NSURL *)link {
    self = [super init];
    self.title = title ?: VKLocalizedString(@"Link");
    self.link = link;
    return self;
}

@end

@implementation VKHelperNavigationController
@end


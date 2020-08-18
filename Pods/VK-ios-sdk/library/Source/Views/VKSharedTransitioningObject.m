//
// Created by Roman Truba on 24.02.15.
// Copyright (c) 2015 VK. All rights reserved.
//

#import "VKSharedTransitioningObject.h"
#import "VKUtil.h"

@interface AnimatedTransitioning : NSObject <UIViewControllerAnimatedTransitioning>
@property(nonatomic, assign) BOOL isPresenting;
@end


@implementation VKSharedTransitioningObject
- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    if ([VKUtil isOperatingSystemAtLeastIOS8] || VK_IS_DEVICE_IPAD) return nil;
    AnimatedTransitioning *controller = [[AnimatedTransitioning alloc] init];
    controller.isPresenting = YES;
    return controller;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    if ([VKUtil isOperatingSystemAtLeastIOS8] || VK_IS_DEVICE_IPAD) return nil;
    AnimatedTransitioning *controller = [[AnimatedTransitioning alloc] init];
    return controller;
}

- (id <UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id <UIViewControllerAnimatedTransitioning>)animator {
    return nil;
}

- (id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator {
    return nil;
}
@end

///-------------------------------
/// @name Animated transition for iOS 7 semi-transparent view
///-------------------------------
@implementation AnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.25f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {

    UIView *inView = [transitionContext containerView];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];

    [inView addSubview:toVC.view];
    if (!self.isPresenting) {
        [inView addSubview:fromVC.view];
    }

    CGRect finalFrame = [transitionContext finalFrameForViewController:toVC];
    if (!finalFrame.size.width || !finalFrame.size.height) {
        finalFrame = fromVC.view.frame;
        finalFrame.origin = CGPointMake(0, 0);
    }
    [toVC.view setFrame:finalFrame];
    if (self.isPresenting) {
        toVC.view.alpha = 0;
    }

    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                     animations:^{
                         [toVC.view setFrame:CGRectMake(0, 0, fromVC.view.frame.size.width, fromVC.view.frame.size.height)];
                         if (self.isPresenting) {
                             toVC.view.alpha = 1;
                         } else {
                             fromVC.view.alpha = 0;
                         }
                     }
                     completion:^(BOOL finished) {
                         [transitionContext completeTransition:YES];
                         if (!self.isPresenting) {
                             [fromVC.view removeFromSuperview];
                         }
                     }];
}

@end

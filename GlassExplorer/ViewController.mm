//
//  Created by ktiays on 2025/6/10.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

#import <optional>

#import "_UIViewGlass.h"
#import "UIView+GlassEffect.h"
#import "UIGlassEffect+Glass.h"
#import "CAFilter.h"

#import "ViewController.h"
#import "GlassExplorer-Swift.h"

@implementation ViewController {
    UIImageView *_imageView;
    UIView *_glassView;
    std::optional<CGPoint> _lastCenter;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TimCook"]];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:_imageView];
    
    _glassView = [UIView new];
    _glassView.layer.cornerRadius = 30;
    _glassView.layer.cornerCurve = kCACornerCurveContinuous;
    [self.view addSubview:_glassView];
    
    auto panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePanGesture:)];
    [_glassView addGestureRecognizer:panGesture];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    auto configurationViewController = [[ConfigurationHostingController alloc] init];
    auto sheetPresentationController = configurationViewController.sheetPresentationController;
    auto smallDetent =
        [UISheetPresentationControllerDetent customDetentWithIdentifier:@"smallDetent"
                                                               resolver:^CGFloat(id<UISheetPresentationControllerDetentResolutionContext> context) {
            return context.maximumDetentValue * 0.2;
        }];
    sheetPresentationController.detents = @[
        smallDetent,
        UISheetPresentationControllerDetent.mediumDetent,
        UISheetPresentationControllerDetent.largeDetent,
    ];
    sheetPresentationController.largestUndimmedDetentIdentifier = UISheetPresentationControllerDetentIdentifierLarge;
    sheetPresentationController.prefersGrabberVisible = YES;
    configurationViewController.modalInPresentation = YES;
    configurationViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    configurationViewController.glassView = _glassView;
    [self presentViewController:configurationViewController animated:YES completion:nil];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    const CGRect bounds = self.view.bounds;
    
    _imageView.frame = bounds;
    
    if (_lastCenter.has_value()) {
        _glassView.center = *_lastCenter;
    } else {
        const CGSize glassSize = CGSizeMake(200, 200);
        _glassView.frame = CGRectMake((bounds.size.width - glassSize.width) / 2, (bounds.size.height - glassSize.height) / 2, glassSize.width, glassSize.height);
    }
}

- (void)_handlePanGesture:(UIPanGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            _lastCenter = _glassView.center;
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [gesture translationInView:_glassView];
            CGPoint center = *_lastCenter;
            center.x += translation.x;
            center.y += translation.y;
            [UIView animateWithSpringDuration:0.3
                                       bounce:0.12
                        initialSpringVelocity:0
                                        delay:0
                                      options:(UIViewAnimationOptionAllowUserInteraction)
                                   animations:^{
                self->_glassView.center = center;
            } completion:nil];
        } break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            _lastCenter = _glassView.center;
            break;
        default:
            break;
    }
}

@end

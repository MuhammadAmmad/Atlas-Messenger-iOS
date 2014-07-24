//
//  LSComposeView.h
//  LayerSample
//
//  Created by Kevin Coleman on 6/10/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LSButton.h"
#import <MapKit/MapKit.h>

@class LSComposeView;

// SBW: This really feels more like controller behavior...
@protocol LSComposeViewDelegate <NSObject>

- (void)composeView:(LSComposeView *)composeView sendMessageWithText:(NSString *)text;
- (void)composeView:(LSComposeView *)composeView sendMessageWithImage:(UIImage *)image;
- (void)composeView:(LSComposeView *)composeView sendMessageLocation:(CLLocationCoordinate2D)location;

- (void)composeViewShouldRestFrame:(LSComposeView *)composeView;
- (void)composeViewDidTapCamera:(LSComposeView *)composeView;
- (void)composeView:(LSComposeView *)composeView setComposeViewHeight:(CGFloat)height;

@end

@interface LSComposeView : UIView <UITextViewDelegate>

@property (nonatomic, weak) id<LSComposeViewDelegate>delegate;

- (void)updateWithImage:(UIImage *)image;

@end
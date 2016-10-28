//
//  FUProcessBar.h
//  FUText
//
//  Created by Pandara on 14-8-13.
//  Copyright (c) 2014年 Pandara. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ProgressBarProgressStyleNormal,
    ProgressBarProgressStyleDelete,
} ProgressBarProgressStyle;

@interface FUProgressBar : UIView

+ (FUProgressBar *)getInstance;

@property (nonatomic, readonly, strong) UIView      *intervalView;
@property (nonatomic, readonly, strong) UIImageView *progressIndicator;
@property (nonatomic, readonly, strong) UIView      *progressView;

- (void)setLastProgressToStyle:(ProgressBarProgressStyle)style;
- (void)setLastProgressToWidth:(CGFloat)width;

- (void)deleteLastProgress;
- (void)addProgressView;

- (void)stopShining;
- (void)startShining;

@end

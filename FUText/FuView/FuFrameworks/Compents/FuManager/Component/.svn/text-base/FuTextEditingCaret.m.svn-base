//
//  FuTextEditingCaret.m
//  Test
//
//  Created by syq on 14-5-29.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuTextEditingCaret.h"

static const NSTimeInterval SETextEditingCaretInitialBlinkDelay = 0.7;
static const NSTimeInterval SETextEditingCaretBlinkRate = 0.6;
static const NSTimeInterval SETextEditingCaretBlinkAnimationDuration = 0.1;

@interface FuTextEditingCaret ()

@property (nonatomic) NSTimer *blinkTimer;

@end

@implementation FuTextEditingCaret

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:23/255.0 green:174/255.0 blue:199/255.0 alpha:1.0];
        self.userInteractionEnabled = NO;
        
        self.blinkTimer = [NSTimer timerWithTimeInterval:SETextEditingCaretBlinkRate target:self selector:@selector(blink) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.blinkTimer forMode:NSRunLoopCommonModes];
    }
    
    return self;
}

- (void)dealloc
{
    [self.blinkTimer invalidate];
}

- (void)delayBlink
{
    self.alpha = 1.0f;
    self.blinkTimer.fireDate = [NSDate dateWithTimeIntervalSinceNow:SETextEditingCaretInitialBlinkDelay];
}

- (void)stopBlink
{
    [_blinkTimer invalidate];
    self.blinkTimer = nil;
}

- (void)blink
{
    [UIView animateWithDuration:SETextEditingCaretBlinkAnimationDuration delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.alpha = !self.alpha;
    } completion:^(BOOL finished) {
        
    }];
}

@end
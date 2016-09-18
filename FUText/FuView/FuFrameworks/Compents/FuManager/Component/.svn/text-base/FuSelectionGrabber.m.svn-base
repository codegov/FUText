//
//  FuSelectionGrabber.m
//  Test
//
//  Created by javalong on 14-6-2.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuSelectionGrabber.h"

@interface FuSelectionGrabberDot : UIView

@property (nonatomic) UIBezierPath *path;

@end

@implementation FuSelectionGrabberDot

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    self.path = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    [[UIColor blueColor] set];
    [self.path fill];
}

@end

@interface FuSelectionGrabber ()

@end

@implementation FuSelectionGrabber

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        // 线
        _caretView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 1.5f, 0.0f)];
        _caretView.backgroundColor = [UIColor blueColor];
        [self addSubview:_caretView];
        // 点
        _dotView = [[FuSelectionGrabberDot alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 10.0f, 10.0f)];
        [self addSubview:_dotView];
    }
    
    return self;
}

- (void)setFrame:(CGRect)frame
{
    super.frame = frame;
    
    CGRect caretFrame = self.caretView.frame;
    caretFrame.origin.x = (CGRectGetWidth(self.bounds) - CGRectGetWidth(caretFrame)) / 2;
    
    CGRect dotFrame = self.dotView.frame;
    if (self.dotMetric == FuSelectionGrabberDotMetricTop) {
        caretFrame.size.height = CGRectGetHeight(self.bounds) - CGRectGetHeight(dotFrame);
        caretFrame.origin.y    = CGRectGetHeight(dotFrame);
        dotFrame.origin = CGPointMake((CGRectGetWidth(self.bounds) - CGRectGetWidth(dotFrame)) / 2, 0.0);
    } else {
        caretFrame.size.height = CGRectGetHeight(self.bounds) - CGRectGetHeight(dotFrame);
        caretFrame.origin.y    = 0.0;
        dotFrame.origin        = CGPointMake((CGRectGetWidth(self.bounds) - CGRectGetWidth(dotFrame)) / 2, caretFrame.size.height);
    }
    self.caretView.frame = caretFrame;
    self.dotView.frame   = dotFrame;
}

//- (void)layoutSubviews
//{
//    [super layoutSubviews];
//}



@end

//
//  FUGridView.m
//  LearnTest
//
//  Created by syq on 15/10/31.
//  Copyright © 2015年 com.chanjet. All rights reserved.
//

#import "FUGridView.h"

@implementation FUGridView
{
    FUGridDot *_currentPot;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
//        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveAction:)];
//        [self addGestureRecognizer:pan];
        
        UILongPressGestureRecognizer *pan = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(moveAction:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
//        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveAction:)];
//        [self addGestureRecognizer:pan];
        
        UILongPressGestureRecognizer *pan = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(moveAction:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (void)moveAction:(UIGestureRecognizer *)pan
{
    CGPoint point = [pan locationInView:self];
    FUGridDot *dot = nil;
    if (CGRectContainsPoint(self.bounds, point))
    {
        if (!_currentPot || ![_currentPot isInsideWithPoint:point])
        {
            dot = [_dotMatrix findDotWithPoint:point];
        }
    }
    if (!_currentPot || ![_currentPot isInsideWithPoint:point])
    {
        _currentPot = dot;
        if ([_delegate respondsToSelector:@selector(gridView:changeToDot:moveGesture:)])
        {
            [_delegate gridView:self changeToDot:dot moveGesture:pan];
        }
    }
    if ([_delegate respondsToSelector:@selector(gridView:moveToDot:moveGesture:)])
    {
        [_delegate gridView:self moveToDot:dot moveGesture:pan];
    }
    
    if (pan.state == UIGestureRecognizerStateBegan || pan.state == UIGestureRecognizerStateChanged)
    {
        
    } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateFailed || pan.state == UIGestureRecognizerStateCancelled)
    {
        if ([_delegate respondsToSelector:@selector(gridView:changeToDot:moveGesture:)])
        {
            [_delegate gridView:self changeToDot:_currentPot moveGesture:pan];
        }
        _currentPot = nil;
    }
}

- (void)setDotMatrix:(FUDotMatrix *)dotMatrix
{
    _dotMatrix = dotMatrix;
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    for (FUGridDot *dot in _dotMatrix.dotArray)
    {
        [self addSubview:dot.dotView];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

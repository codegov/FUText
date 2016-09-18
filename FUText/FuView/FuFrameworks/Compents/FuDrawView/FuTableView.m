//
//  FuTableView.m
//  Test
//
//  Created by syq on 14/8/27.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuTableView.h"

@interface FuTableView ()
{
//    float    _minimumLongPressDuration;
//    NSTimer *_longPressTimer;
//    
//    BOOL     _isLongPress;
}
@end

@implementation FuTableView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
//        _minimumLongPressDuration = 0.5;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
//
//- (void)dealloc
//{
//    [self stopLongPressTimer];
//}
//
//- (void)startLongPressTimer
//{
//    [self stopLongPressTimer];
//    
//    _longPressTimer = [NSTimer scheduledTimerWithTimeInterval:_minimumLongPressDuration
//                                                          target:self
//                                                        selector:@selector(handleLongPress:)
//                                                        userInfo:nil
//                                                         repeats:NO];
//}
//
//- (void)stopLongPressTimer
//{
//    if (_longPressTimer && [_longPressTimer isValid]) {
//        [_longPressTimer invalidate];
//    }
//    _longPressTimer = nil;
//}
//
//- (void)handleLongPress:(NSTimer *)timer
//{
//    [self stopLongPressTimer];
//    
//
//    _isLongPress = YES;
//    
//}




- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    CGPoint point  = [touch locationInView:self];
    if ([_fuDelegate respondsToSelector:@selector(tableViewDidTouchBegin:point:)]) {
        [_fuDelegate tableViewDidTouchBegin:touch point:point];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    CGPoint point  = [touch locationInView:self];
    if ([_fuDelegate respondsToSelector:@selector(tableViewDidTouchMove:point:)]) {
        [_fuDelegate tableViewDidTouchMove:touch point:point];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    CGPoint point  = [touch locationInView:self];
    if ([_fuDelegate respondsToSelector:@selector(tableViewDidTouchEnd:point:)]) {
        [_fuDelegate tableViewDidTouchEnd:touch point:point];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    CGPoint point  = [touch locationInView:self];
    if ([_fuDelegate respondsToSelector:@selector(tableViewDidTouchEnd:point:)]) {
        [_fuDelegate tableViewDidTouchEnd:touch point:point];
    }
}


@end

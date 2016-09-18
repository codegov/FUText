//
//  FuTextLookMagnifier.m
//  Test
//
//  Created by syq on 14-5-29.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuTextLookMagnifier.h"

@interface FuTextLookMagnifier ()
{
    UIWindow *_console;//控制台窗口
}

@property (assign, nonatomic) CGPoint touchPoint;

@property (strong, nonatomic) UIImage *mask;
@property (strong, nonatomic) UIImage *loupe;
@property (strong, nonatomic) UIImage *loupeFrame;

@property (nonatomic) float keyBoardHeight;    // 记录键盘高度

@end

@implementation FuTextLookMagnifier

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor clearColor];
        self.mask       = [UIImage imageNamed:@"Image.bundle/kb-loupe-mask"];
		self.loupe      = [UIImage imageNamed:@"Image.bundle/kb-loupe-hi"];
		self.loupeFrame = [UIImage imageNamed:@"Image.bundle/kb-loupe-lo"];
        
        _console = [[UIWindow alloc] initWithFrame:frame];
        _console.windowLevel = UIWindowLevelStatusBar + 1.0;//窗口等级不低于状态栏，实现遮盖
        [_console makeKeyAndVisible];
        if ([[[UIApplication sharedApplication] windows] count] > 0)
        {
            [[[[UIApplication sharedApplication] windows] objectAtIndex:0] makeKeyWindow];
        }
    
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	}
    
	return self;
}

#pragma mark - UIKeyboard Notification

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _keyBoardHeight = keyboardRect.size.height;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    _keyBoardHeight = 0.0;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 *  @brief  设置放大镜的位置
 *  @param
 *  @return
 **/

- (void)setTouchPoint:(CGPoint)point
{
	_touchPoint = point;
    point = [self.window convertPoint:point fromView:[UIApplication sharedApplication].keyWindow];
    self.center = CGPointMake(point.x, point.y - self.frame.size.height/2.0 + 20.0);
}

/**
 *  @brief  显示放大镜
 *  @param
 *  @return
 **/

- (void)showInPoint:(CGPoint)point
{
    self.frame = CGRectMake(0.0f, 0.0f, self.mask.size.width, self.mask.size.height);

    [_console addSubview:self];
    
    self.touchPoint = point;
    
    CGRect frame = self.frame;
    CGPoint center = self.center;
    
    CGRect startFrame = self.frame;
    startFrame.size = CGSizeZero;
    self.frame = startFrame;
    
    CGPoint startPosition = self.center;
    startPosition.x += frame.size.width / 2;
    startPosition.y += frame.size.height;
    self.center = self.touchPoint;// startPosition;
    
    [UIView animateWithDuration:0.15 delay:0.0 options:kNilOptions animations:^{
        self.frame = frame;
        self.center = center;
    } completion:nil];
}

/**
 *  @brief  移动放大镜
 *  @param
 *  @return
 **/

- (void)moveToPoint:(CGPoint)point
{
    float height = [UIApplication sharedApplication].keyWindow.bounds.size.height - _keyBoardHeight;
    if (point.y > height) {
        point = CGPointMake(point.x, height);
    }
	self.touchPoint = point;
    [self setNeedsDisplay];
}

/**
 *  @brief  清除放大镜
 *  @param
 *  @return
 **/

- (void)hide
{
    
    CGRect bounds = self.bounds;
    bounds.size = CGSizeZero;
    
    CGPoint position = self.touchPoint;// self.center;
    
    [UIView animateWithDuration:0.15 delay:0.0 options:kNilOptions animations:^{
        self.bounds = bounds;
        self.center = position;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

/**
 *  @brief  绘制放大镜
 *  @param
 *  @return
 **/

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    [_loupeFrame drawInRect:rect];
    
    CGContextSaveGState(ctx);
    
    CGContextClipToMask(ctx, rect, _mask.CGImage); // 蒙板 透视视图
    
    CGContextTranslateCTM(ctx,1*(self.frame.size.width*0.5),1*(self.frame.size.height*0.5));
    CGContextScaleCTM(ctx, 1.5, 1.5);
    CGContextTranslateCTM(ctx,-1*(self.touchPoint.x),-1*(self.touchPoint.y));
    [[UIApplication sharedApplication].keyWindow.layer renderInContext:ctx];
    
    CGContextRestoreGState(ctx);
    
    [_loupe drawInRect:rect];
}

@end
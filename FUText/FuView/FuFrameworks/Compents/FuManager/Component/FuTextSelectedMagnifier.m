//
//  SETextSelectedMagnifier.m
//  Test
//
//  Created by syq on 14-5-29.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuTextSelectedMagnifier.h"

@interface FuTextSelectedMagnifier ()
{
    UIWindow *_console;//控制台窗口
}

@property (assign, nonatomic) CGPoint touchPoint;

@property (strong, nonatomic) UIImage *mask;
@property (strong, nonatomic) UIImage *loupe;
@property (strong, nonatomic) UIImage *loupeFrame;

@property (nonatomic) float offY;

@end

@implementation FuTextSelectedMagnifier

/**
 *  @brief  初始化
 *  @param
 *  @return
 **/

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor clearColor];
        
        self.mask       = [UIImage imageNamed:@"Image.bundle/kb-magnifier-ranged-mask-flipped"];
		self.loupe      = [UIImage imageNamed:@"Image.bundle/kb-magnifier-ranged-hi"];
		self.loupeFrame = [UIImage imageNamed:@"Image.bundle/kb-magnifier-ranged-lo"];
        
        _console             = [[UIWindow alloc] initWithFrame:frame];
        _console.windowLevel = UIWindowLevelStatusBar + 1.0;//窗口等级不低于状态栏，实现遮盖
        [_console makeKeyAndVisible];
        if ([[[UIApplication sharedApplication] windows] count] > 0)
        {
            [[[[UIApplication sharedApplication] windows] objectAtIndex:0] makeKeyWindow];
        }
	}
    
	return self;
}

/**
 *  @brief  设置 选中范围放大镜的位置
 *  @param
 *  @return
 **/

- (void)setTouchPoint:(CGPoint)point
{
	_touchPoint = point;
    CGFloat x   = point.x;
    CGFloat y   = point.y - self.mask.size.height;
    self.center = CGPointMake(x, y);
}

/**
 *  @brief  显示 选中范围放大镜
 *  @param
 *  @return
 **/

- (void)showInPoint:(CGPoint)point offY:(float)offY
{
    _offY = offY;
    
    self.frame = CGRectMake(0.0f, 0.0f, self.mask.size.width, self.mask.size.height + 25); // 25 是箭头的大小
    
    self.touchPoint = point;
    
    [_console addSubview:self];
    
    CGRect frame = self.frame;
    CGPoint center = self.center;
    
    CGRect startFrame = self.frame;
    startFrame.size = CGSizeZero;
    self.frame = startFrame;
    
    CGPoint startPosition = self.center;
    startPosition.x += frame.size.width / 2;
    startPosition.y += frame.size.height;
    self.center = point;//startPosition;
    
    
    [UIView animateWithDuration:0.15 delay:0.0 options:kNilOptions animations:^{
        self.frame = frame;
        self.center = center;
    } completion:nil];
}

/**
 *  @brief  移动 选中范围放大镜
 *  @param
 *  @return
 **/

- (void)moveToPoint:(CGPoint)point offY:(float)offY
{
    _offY = offY;
    
	self.touchPoint = point;
    [self setNeedsDisplay];
}

/**
 *  @brief  移除 选中范围放大镜
 *  @param
 *  @return
 **/

- (void)hide
{
    CGRect bounds = self.bounds;
    bounds.size = CGSizeZero;
    
    CGPoint position = self.touchPoint;
    
    [UIView animateWithDuration:0.15 delay:0.0 options:kNilOptions animations:^{
        self.bounds = bounds;
        self.center = position;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

/**
 *  @brief  绘制 选中范围放大镜
 *  @param
 *  @return
 **/

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
    
    [_loupeFrame drawInRect:rect];
    CGContextSaveGState(context);
    
    CGContextClipToMask(context, CGRectMake(rect.origin.x + 8, rect.origin.y + 5, rect.size.width - 16.0, self.mask.size.height), _mask.CGImage);  // 蒙板的位置和大小 可以透视的视图大小
    
    CGContextTranslateCTM(context,1*(rect.size.width*0.5),1*(rect.size.height*0.5));
    CGContextScaleCTM(context, 1.5, 1.5);
    CGContextTranslateCTM(context, -1*(self.touchPoint.x), -1*(self.touchPoint.y) - 1 - _offY);
    [[UIApplication sharedApplication].keyWindow.layer renderInContext:context];
    
    CGContextRestoreGState(context);
    
    [_loupe drawInRect:rect];
}

@end
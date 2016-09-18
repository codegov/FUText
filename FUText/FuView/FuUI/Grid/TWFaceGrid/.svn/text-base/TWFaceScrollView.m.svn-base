//
//  TWFaceScrollView.m
//  teamwork
//
//  Created by syq on 15/11/4.
//  Copyright © 2015年 chanjet. All rights reserved.
//

#import "TWFaceScrollView.h"

@implementation TWFaceScrollView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

 - (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
//    NSLog(@"用户点击了scroll上的视图%@,是否开始滚动scroll",[view class]);
    //返回yes - 将触摸事件传递给相应的subView; 返回no - 直接滚动scrollView，不传递触摸事件到subView  
    return YES;
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
//    NSLog(@"用户点击的视图 %@",[view class]);
    //no - 不取消，touch事件由view处理，scrollView不滚动; yes - scrollView取消，touch事件由scrollView处理，可滚动
    return NO;
}

@end

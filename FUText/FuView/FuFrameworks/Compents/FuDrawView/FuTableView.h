//
//  FuTableView.h
//  Test
//
//  Created by syq on 14/8/27.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FuTableViewDelegate <NSObject>

@optional
- (void)tableViewDidTouchBegin:(UITouch *)touch point:(CGPoint)point;
- (void)tableViewDidTouchMove:(UITouch *)touch point:(CGPoint)point;
- (void)tableViewDidTouchEnd:(UITouch *)touch point:(CGPoint)point;

- (void)tableViewDidLongPressBegin:(UITouch *)touch point:(CGPoint)point;
- (void)tableViewDidLongPressMove:(UITouch *)touch point:(CGPoint)point;
- (void)tableViewDidLongPressEnd:(UITouch *)touch point:(CGPoint)point;

@end

@interface FuTableView : UITableView

@property (nonatomic, weak) id<FuTableViewDelegate> fuDelegate;

@end

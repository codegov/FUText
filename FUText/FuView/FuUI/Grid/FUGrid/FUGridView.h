//
//  FUGridView.h
//  LearnTest
//
//  Created by syq on 15/10/31.
//  Copyright © 2015年 com.chanjet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUGridDot.h"
#import "FUDotMatrix.h"

@class FUGridView;

@protocol FUGridViewDelegate <NSObject>

@optional
- (void)gridView:(FUGridView *)gridView moveToDot:(FUGridDot *)dot moveGesture:(UIGestureRecognizer *)gesture;
- (void)gridView:(FUGridView *)gridView changeToDot:(FUGridDot *)dot moveGesture:(UIGestureRecognizer *)gesture;

@end

@interface FUGridView : UIView

@property (nonatomic, weak) id<FUGridViewDelegate> delegate;
@property (nonatomic, strong) FUDotMatrix *dotMatrix;

@end

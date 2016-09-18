//
//  FuToolManager.h
//  Test
//
//  Created by syq on 14/8/13.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import "FuTextEditingCaret.h"
#import "FuSelectionGrabber.h"

@class FuTextView;

@interface FuManager : NSObject

- (id)initWithTextView:(FuTextView *)textView;

@property (nonatomic, strong, readonly) FuTextEditingCaret *caretView;    // 编辑光标
@property (nonatomic, strong, readonly) FuSelectionGrabber *startGrabber; // 开始拖动控件
@property (nonatomic, strong, readonly) FuSelectionGrabber *endGrabber;   // 结尾拖动控件

// 输入文本时，更新光标位置
- (void)updateCaretViewWithLocation:(CFIndex)location line:(CTLineRef)line lineHeight:(float)lineHieght caretHeight:(float)caretHeight;

// 移动选中放大镜
- (void)moveSelectedMagnifierToPoint:(CGPoint)point offY:(float)offY;
- (void)hideSelectedMagnifier;

// 移动查看放大镜
- (void)moveLookMagnifierToPoint:(CGPoint)point;
- (void)hideLookMagnifierToPoint:(CGPoint)point;

// 二分查找/折半查找
- (CFIndex)binarySearchForLineNum:(CFArrayRef)lines count:(CFIndex)count location:(CFIndex)location type:(int)type;

// 更新光标位置
- (void)updateCaretViewWithPoint:(CGPoint)point caretHeight:(float)caretHeight;


@end

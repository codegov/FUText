//
//  FuDrawView.h
//  Test
//
//  Created by syq on 14/8/12.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "FuTableView.h"
#import "FuDrawViewCell.h"
#import "FuTextModel.h"

@class FuDrawView;

@protocol FuDrawViewDelegate <NSObject>

@optional
- (void)drawViewClickTextRun:(FuTextRun *)textRun;
- (void)drawViewDidTouchBegin:(UITouch *)touch point:(CGPoint)point;
- (void)drawViewDidTouchMove:(UITouch *)touch point:(CGPoint)point;
- (void)drawViewDidTouchEnd:(UITouch *)touch point:(CGPoint)point;
- (void)drawViewDidLongPress:(UILongPressGestureRecognizer *)longPress point:(CGPoint)point;
- (void)drawViewWillBeginDragging:(FuDrawView *)drawView;
- (void)drawViewDidEndDecelerating:(FuDrawView *)drawView;
- (void)drawViewDidEndDragging:(FuDrawView *)drawView;
- (void)drawViewDidScroll:(FuDrawView *)drawView;

@end

@interface FuDrawView : UIView<UITableViewDelegate, UITableViewDataSource, FuTableViewDelegate>

@property (nonatomic, weak)   id<FuDrawViewDelegate> delegate;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) NSAttributedString *attributedText; // 绘制文本
@property (nonatomic) NSRange highlightRange;    // 高亮文本范围

@property (nonatomic) UIEdgeInsets edgeInsets;         // 绘制视图与本视图的边距 默认为0
@property (nonatomic, strong) UIView *textHeaderView;  // 绘制视图上边视图
@property (nonatomic, strong) UIView *textFooterView;  // 绘制视图下边视图


@property (nonatomic) CFArrayRef lines;           // 行数据源
@property (nonatomic) CFIndex    lineCount;       // 总行数
@property (nonatomic) float      lineHeight;      // 行高
@property (nonatomic, readonly, strong) NSMutableDictionary *lineHeightDictionary;

@property (nonatomic, readonly, strong) FuTableView *tableView;

- (CFIndex)getLineNumWithPoint:(CGPoint)point;      // 得到点所处于的行号
- (CFIndex)getLineLocationWithPoint:(CGPoint)point; // 得到点所处于行的位置

- (void)reloadTable;
- (CTFrameRef)createFrameWithAttributedText:(NSAttributedString *)attributedText;
- (void)updateLineLayoutHighlightMarkedRect:(FuLineLayout *)lineLayout;

@end

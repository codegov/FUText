//
//  FuLabel.h
//  Test
//
//  Created by syq on 14/8/12.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FuTextModel.h"

@protocol FuLabelDelegate <NSObject>

@optional
- (void)labelClickTextRun:(FuTextRun *)textRun;

@end

@interface FuLabel : UIView

@property (nonatomic, weak) id<FuLabelDelegate> delegate;
@property (nonatomic, strong) FuTextModel *textModel;

@property (nonatomic) UIEdgeInsets edgeInsets; // 绘制视图与本视图的边距 默认为0
@property (nonatomic) FuTextType clickTextType;// 默认 FuText_url | FuText_at | FuText_number | FuText_topic;
@property (nonatomic) BOOL showMoreTruncation; // 显示不全时，是否显示"..."
@property (nonatomic, strong) NSString *truncationEndText; // 省略字符

@property (nonatomic) NSInteger numberOfLines; // 显示的行数 默认0 表示不限制，全部显示

@property (nonatomic) BOOL scrollEnabled;      // 能否滚动 默认NO

// 如果不确定label的高度，可以通过此方法确定label的高度
+ (float)heightWithTextModel:(FuTextModel *)model
               numberOfLines:(NSInteger)numberOfLines
                 contentSize:(CGSize)contentSize;

@end

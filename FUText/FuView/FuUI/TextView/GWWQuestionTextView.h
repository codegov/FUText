//
//  GWWQuestionTextView.h
//  GroupWenWen
//
//  Created by javalong on 16/4/8.
//  Copyright © 2016年 evan. All rights reserved.
//

#import "GWWTextView.h"

@interface GWWQuestionTextView : GWWTextView

@property (nonatomic) NSInteger allowInputMax;    // 最大允许输入数 默认-1，无限制
@property (nonatomic) BOOL needScrollToBarBottom; // 默认NO
@property (nonatomic) BOOL needGridImage;         // 是否需要九宫格图片显示 默认NO

@end

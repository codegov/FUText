//
//  FuTextRun.h
//  Test
//
//  Created by syq on 14/8/20.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

/**
 *富文本类型
 */
typedef enum {
    FuText_normal  = 1 << 0,    // 普通文本
    FuText_at      = 1 << 1,    // @
    FuText_topic   = 1 << 2,    // 主题
    FuText_url     = 1 << 3,    // url
    FuText_img     = 1 << 4,    // 图片
    FuText_number  = 1 << 5,    // 数字电话
    FuText_view    = 1 << 6,    // 视图
    FuText_EscapeAnglebracket = 1 << 7, // <>转义
    FuText_SpaceWidth = 1 << 8, // 空宽
    FuText_truncation = 1 << 9, // 省略文字
    FuText_none    = 1 << 10,    // 点击文本时，富文本所有类型都不响应 优先级最高
    FuText_all     = 1 << 11     // 点击文本时，富文本所有类型都响应   优先级第二高
} FuTextType;

#define FUTEXT_IMG_EDGE 1 // 表情之间的间隔

@interface FuTextRun : NSObject

@property (nonatomic) FuTextType type;           // 关键字类型
@property (nonatomic) CFRange    range;          // 关键字range
@property (nonatomic, strong) NSString *string;  // 关键字内容

@property (nonatomic) CFRange    oRange;         // 原关键字range
@property (nonatomic, strong) NSString *oString; // 原关键字内容

@property (nonatomic) Boolean select;
@property (nonatomic) CGSize  size;   //图片大小
@property (nonatomic) CGSize  runSize;//块大小
@property (nonatomic, strong) id object;
@property (nonatomic, strong) NSDictionary *userInfo;

@property (nonatomic, readonly) CTRunDelegateCallbacks callbacks;

@end

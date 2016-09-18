//
//  FuTextModel.h
//  Test
//
//  Created by syq on 14/8/12.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FuTextRun.h"
#import "FuTextColor.h"

@interface FuTextModel : NSObject

@property (nonatomic, strong) NSString *string;            // 默认 is nil
@property (nonatomic, copy)   NSAttributedString *attributedString; // 默认 is nil

@property (nonatomic, strong) UIFont   *font;              // 默认 is 16.0
@property (nonatomic) NSTextAlignment   textAlignment;     // 默认 is NSLeftTextAlignment

@property (nonatomic) CGFloat lineSpacing;                 // 行间距  默认 is 4.0
@property (nonatomic) CGFloat paragraphSpacing;            // 段间距  默认 is 4.0

@property (nonatomic) NSRange selectedRange;                // 选中文本范围 和 光标位置
@property (nonatomic) NSRange markedRange;                  // 标记文本范围

@property (nonatomic) FuTextType textType;

@property (nonatomic) CGFloat custromViewWidth;
@property (nonatomic) CGFloat viewLineSpacing;


// event
@property (nonatomic)         NSRange   eventRange;        // 事件范围 默认 is [0, string.length]
@property (nonatomic, strong) UIColor  *eventColor;        // 事件范围文本的颜色 默认 is nil
@property (nonatomic, strong) UIFont   *eventFont;         // 事件字体大小


// 只读
@property (nonatomic, readonly)         CGFloat lineHeight;        // 行高    默认 is font.lineHeight + lineSpacing
@property (nonatomic, readonly)         CGFloat fontHeight;        // 字体高   默认is font.lineHeight
@property (nonatomic, strong, readonly) NSMutableDictionary *attributes;  // 文本样式字典
@property (nonatomic, strong, readonly) FuTextColor         *textColor;   // 文本颜色
@property (nonatomic, strong, readonly) NSMutableDictionary *viewRunDictionary;



// 方法
- (NSAttributedString *)getAttrString; // 绘制数据
- (NSAttributedString *)getAttrStringWithTextType:(FuTextType)textType; // 绘制数据
- (NSString *)getReallyString; // 真实数据
- (NSString *)getCopyString;   // copy数据
- (void)clearCacheString;
- (void)getReallyString:(NSString **)string custromViewPathList:(NSArray **)pathList; //

+ (NSMutableArray *)parser:(NSString *)str; // 解析文本，得到文本块FuTextRun
- (FuTextRun *)binarySearchForTextRun:(CFIndex)location; // 二分查找/折半查找文本块FuTextRun


+ (NSString *)regOfRichText;
+ (NSString *)regOfURL;
+ (NSString *)regOfNumber;
+ (NSString *)regOfFace;
+ (NSString *)regOfView;
+ (NSString *)regOfViewImg;
+ (NSString *)regOfViewImgUrl;
+ (NSString *)regOfViewImgUrl2;

+ (void)regChunksWithText:(NSString *)text regString:(NSString *)regString chunks:(NSMutableArray *)chunks;
+ (void)eliminateChunksFromSuperChunks:(NSMutableArray *)superChunks chunks:(NSMutableArray *)chunks;
+ (void)mergeChunksToRich:(NSMutableArray *)richTextChunks chunks:(NSMutableArray *)chunks;

+ (NSAttributedString *)getReplacementStringWithName:(NSString *)name type:(FuTextType)type size:(CGSize)size runWidth:(CGFloat)width;
+ (NSAttributedString *)getReplacementStringWithName:(NSString *)name type:(FuTextType)type size:(CGSize)size runWidth:(CGFloat)width viewLineSpacing:(CGFloat)viewLineSpacing;
+ (CGSize)getCustromViewSizeWithImagePath:(NSString *)path viewWidth:(CGFloat)viewWidth isHave:(BOOL *)isHave;

@end

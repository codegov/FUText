//
//  NSString+Filter.m
//  teamwork
//
//  Created by sunlin on 14-4-28.
//  Copyright (c) 2014年 chanjet. All rights reserved.
//

#import "NSString+FuFace.h"

@implementation NSString (FuFace)

+ (NSArray *)faceArray
{
     return @[@"微笑",  @"撇嘴",  @"色",     @"发呆",    @"得意",  @"流泪",  @"害羞",   @"闭嘴",   @"睡觉",   @"大哭",   // 1
              @"尴尬",  @"发怒",  @"调皮",   @"呲牙",    @"惊讶",  @"难过",  @"酷",     @"冷汗",   @"抓狂", @"吐",     // 2
              @"偷笑",  @"愉快",  @"白眼",   @"傲慢",    @"饥饿",  @"困",    @"惊恐",   @"流汗",   @"憨笑", @"悠闲",   // 3
              @"奋斗",  @"咒骂",  @"疑问",   @"嘘",     @"晕",    @"疯了",   @"衰",     @"骷髅",  @"敲打", @"再见",   // 4
              @"擦汗",  @"抠鼻",  @"鼓掌",   @"糗大了",  @"坏笑",  @"左哼哼", @"右哼哼",  @"哈欠",  @"鄙视", @"委屈",   // 5
              @"快哭了", @"阴险",  @"亲亲",   @"吓",     @"可怜",  @"菜刀",   @"西瓜",   @"啤酒",  @"篮球", @"乒乓",   // 6
              @"咖啡",  @"米饭",   @"猪头",   @"玫瑰",    @"凋谢",  @"嘴唇",   @"爱心",   @"心碎",  @"蛋糕", @"闪电",   // 7
              @"炸弹",  @"匕首",   @"足球",   @"瓢虫",    @"便便",  @"月亮",   @"太阳",   @"礼物",  @"拥抱", @"强",    // 8
              @"弱",    @"握手",  @"胜利",   @"抱拳",    @"勾引",  @"拳头",   @"差劲",   @"爱你",  @"no",  @"ok",    // 9
              @"爱情",  @"飞吻",  @"跳跳",    @"发抖",   @"怄火",  @"转圈",   @"磕头",   @"回头",  @"跳绳", @"投降",   // 10
              @"笑脸",  @"生病",  @"破涕为笑", @"吐舌头", @"脸红",  @"恐惧",   @"失望",   @"眨眼",  @"满意", @"无语",   // 11
              @"恶魔",  @"鬼魂",  @"礼盒",    @"拜托",   @"强壮",  @"钱",     @"庆祝"];                              // 12
}

+ (NSArray *)faceOldA
{
    return @[@"微笑", @"呲牙", @"奋斗", @"疑问", @"抓狂", @"惊讶", @"流汗", @"憨笑", @"流泪", @"发怒",
             @"笑脸", @"闭嘴", @"晕",  @"阴险", @"色",   @"哈欠", @"调皮", @"失望", @"可怜", @"亲亲",
             @"再见", @"握手", @"ok", @"强"];
}

+ (NSArray *)faceOldArray
{
    return @[@"wx", @"zy", @"fd",  @"yw",  @"zhk", @"jy", @"lh", @"hx",  @"ll", @"fn",
             @"kx", @"bz", @"yun", @"shh", @"am",  @"hq", @"tp", @"shw", @"gd", @"qq",
             @"zj", @"wsh", @"hd", @"qiang"];
}

- (NSString *)faceFormat
{
    NSString *name = self;
    if ([name hasPrefix:@"["])
    {
        name = [name substringFromIndex:1];
    }
    if ([name hasSuffix:@"]"])
    {
        name = [name substringToIndex:name.length - 1];
    }
    NSArray *newArray = [NSString faceArray];
    if ([newArray containsObject:name])
    {
        NSInteger index = [newArray indexOfObject:name];
        name = [NSString faceNameOfIndex:index];
    } else if ([[NSString faceOldArray] containsObject:name])
    {
        NSInteger index = [[NSString faceOldArray] indexOfObject:name];
        NSArray *array = [NSString faceOldA];
        if (index < array.count)
        {
            NSString *temp = [array objectAtIndex:index];
            if ([newArray containsObject:temp])
            {
                index = [newArray indexOfObject:temp];
                name = [NSString faceNameOfIndex:index];
            } else
            {
                name = @"";
            }
        } else
        {
            name = @"";
        }
    } else
    {
        name = @"";
    }
    return name;
}

- (BOOL)isExistFace
{
    NSString *name = self;
    if ([[NSString faceArray] containsObject:name])
    {
        return YES;
    } else if ([[NSString faceOldArray] containsObject:name])
    {
        return YES;
    }
    return NO;
}

- (NSString *)faceFormatToCh
{
    NSString *name = self;
    if ([[NSString faceOldArray] containsObject:name])
    {
        NSInteger index = [[NSString faceOldArray] indexOfObject:name];
        NSArray *array = [NSString faceOldA];
        if (index < array.count)
        {
            name = [array objectAtIndex:index];
        }
    }
    return name;
}

+ (NSString *)faceNameOfIndex:(NSInteger)index
{
    return [NSString stringWithFormat:@"face%@", @(index + 1).stringValue];
}

+ (NSString *)facePlaceholderOfIndex:(NSInteger)index
{
    NSArray *newArray = [NSString faceArray];
    if (index < newArray.count) {
        return [newArray objectAtIndex:index];
    }
    return nil;
}

- (BOOL)isUrl
{
    NSString *		regex = @"http(s)?:\\/\\/([\\w-]+\\.)+[\\w-]+(\\/[\\w- .\\/?%&=]*)?";
    NSPredicate *	pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    
    return [pred evaluateWithObject:self];
}

@end

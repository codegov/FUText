//
//  FuTextModel.m
//  Test
//
//  Created by syq on 14/8/12.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuTextModel.h"
#import <CoreText/CoreText.h>
#import "NSString+FuFace.h"
#import "GWWTextCache.h"

@interface FuTextModel ()
{
    NSMutableArray *_runArray;
}
@end

@implementation FuTextModel

static NSString * const OBJECT_REPLACEMENT_CHARACTER = @"\uFFFC";//Unicode编码 为对象占位符

+ (NSString *)regOfRichText
{
    return @"\\{([^}]+)\\}{1}";
}

+ (NSString *)regOfURL
{
    return @"((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z0-9]{2,4})(:\\d+)?(/?[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|([a-zA-Z0-9\\.\\-]+\\.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/?[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";
}

+ (NSString *)regOfNumber
{
//    return @"((0|86|17951)?(1[0-9])[0-9]{9}|((\\d{7,8})|(\\d{4}|\\d{3})[-]{0,1}(\\d{7,8})|(\\d{4}|\\d{3})[-]{0,1}(\\d{7,8})-(\\d{4}|\\d{3}|\\d{2}|\\d{1})|(\\d{7,8})-(\\d{4}|\\d{3}|\\d{2}|\\d{1})))";
    return @"((\\(\\d{3,4}\\))(\\d{6,8}))|(\\d{3,4}-\\d{6,8})|(\\d{3,17})|(1[2-8])\\\\d{9}";
}

+ (NSString *)regOfFace
{
    return @"\\[[a-zA-Z0-9\\u4e00-\\u9fa5]+\\]";
}

+ (NSString *)regOfView
{
    return @"<img[^>]+src\\s*=\\s*['\"]([^'\"]+)['\"][^>]*>";
}

+ (NSString *)regOfViewImg
{
    return @"src\\s*=\\s*\"?(.*?)(\"|>|\\s+)";
}

+ (NSString *)regOfViewImgUrl
{
    return @"http://pic.wenwen.soso.com/p/\\d{8}/(\\d{1,}-\\d{1,}).jpg";
}

+ (NSString *)regOfViewImgUrl2
{
    return @"http://p.qpic.cn/wenwenpic/0/([\\d]+-[\\d]+)(/[\\d]+)?";
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _font = [UIFont systemFontOfSize:16];
        _lineSpacing      = 4.0;
        _paragraphSpacing = 4.0;
        _textAlignment    = NSTextAlignmentLeft;
        _textColor   = [[FuTextColor alloc] init];
        _runArray    = [[NSMutableArray alloc] init];
        _viewRunDictionary = [[NSMutableDictionary alloc] init];
        _selectedRange = NSMakeRange(NSNotFound, 0);
        _textType = FuText_normal;
    }
    return self;
}

- (CGFloat)lineHeight
{
    return (int)(_font.lineHeight + _lineSpacing);
}

- (CGFloat)fontHeight
{
    return (int)_font.lineHeight;
}

- (void)setString:(NSString *)string
{
//    _string = string;
    if (string) {
        self.attributedString = [[NSAttributedString alloc] initWithString:string];
    } else {
        self.attributedString = nil;
    }
}

- (void)setAttributedString:(NSAttributedString *)attributedString
{
    _attributedString = [attributedString copy];
    if (!_attributedString.string.length)
    {
        _string = nil;
    }
//    _string = attributedString.string;
}

- (void)clearCacheString
{
    _string = nil;
}

// 二分查找/折半查找
- (FuTextRun *)binarySearchForTextRun:(CFIndex)location
{
    if (location < _attributedString.length && location > 0)
    {
        NSLog(@"location==%@", @(location));
        NSRange range = NSMakeRange(0, 1);
        NSDictionary*dic = [_attributedString attributesAtIndex:location effectiveRange:&range];
        NSLog(@"dic ===%@", dic);
    }

    // 通过上面逻辑替换掉下面的逻辑
    CFIndex low = 0, high = _runArray.count - 1, mid;
    while (low <= high)
    {
        FuTextRun *minRun = [_runArray objectAtIndex:low];
        if (minRun.oRange.location <= location && location <= (minRun.oRange.location + minRun.oRange.length)) return minRun;
        
        FuTextRun *maxRun = [_runArray objectAtIndex:high];
        if (maxRun.oRange.location <= location && location <= (maxRun.oRange.location + maxRun.oRange.length)) return maxRun;
        
        //当前查找区间R[low..high]非空
        mid = low + ((high-low)/2);
        //使用(low+high)/2会有整数溢出的问题
        //（问题会出现在当low+high的结果大于表达式结果类型所能表示的最大值时，
        //这样，产生溢出后再/2是不会产生正确结果的，而low+((high-low)/2)不存在这个问题
        FuTextRun *midRun = [_runArray objectAtIndex:mid];
        if(midRun.oRange.location <= location && location <= (midRun.oRange.location + midRun.oRange.length)) return midRun;//查找成功返回
        
        if(midRun.oRange.location > location)
            high = mid - 1;//继续在R[low..mid-1]中查找
        else
            low = mid + 1;//继续在R[mid+1..high]中查找
    }
    
    return nil; //当low>high时表示所查找区间内没有结果，查找失败
}

#pragma mark 文本样式

- (NSAttributedString *)getAttrString
{
    return [self getAttrStringWithTextType:_textType];
}

- (NSAttributedString *)getAttrStringWithTextType:(FuTextType)textType // 绘制数据
{
    NSString *formatString = self.attributedString.string;
    if (!formatString.length)
    {
        _string = nil;
        return nil;
    }
    if ([_string isEqualToString:formatString])
    {
        if (_eventColor || _eventFont)
        {
            NSMutableAttributedString *aString = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedString];
            [self dealEventWithAString:aString];
            self.attributedString = aString;
        }
        return self.attributedString;
    }
    _string = formatString;
    [_viewRunDictionary removeAllObjects];
    
    NSArray *runArray = [FuTextModel parserWithType:_string type:textType lastRun:nil recordIndex:nil recordOIndex:nil];
    
//    FuTextRun *lastRun = nil;
//    if (_runArray.count) {
//        lastRun = _runArray.lastObject;
//    }
//    NSArray *runArray = [FuTextModel parserWithType:self.string type:textType lastRun:lastRun recordIndex:nil recordOIndex:nil];
//    if (runArray.count) {
//        [_runArray addObjectsFromArray:runArray];
//    }
    
    NSMutableAttributedString *aString = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedString];

    for (int i = 0; i < runArray.count; i++)
    {
        UIColor *color;
        FuTextRun *modle = (FuTextRun *)[runArray objectAtIndex:i];
        switch (modle.type) {
            case FuText_normal:
                color = _textColor.color;
                break;
            case FuText_at:
            {
                color = modle.select ? _textColor.color_select : _textColor.color_at;
                NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:modle.string];
                [string addAttribute:@"type" value:@(FuText_at) range:NSMakeRange(0, string.length)];
                [string addAttribute:@"param" value:@{@"name": modle.string, @"uid": modle.object} range:NSMakeRange(0, string.length)];
                
                NSString *imageString = [NSString stringWithFormat:@"{%@,%@}", modle.string, modle.object];
                
                if (_selectedRange.location != NSNotFound) {
                    if (_selectedRange.location > modle.range.location) {
                        _selectedRange.location -= (imageString.length - string.length);
                    }
                }
                [aString replaceCharactersInRange:NSMakeRange(modle.range.location, imageString.length) withAttributedString:string];
            }
                break;
            case FuText_topic:
                color = modle.select ? _textColor.color_select : _textColor.color_topic;
                break;
            case FuText_url:
                color = modle.select ? _textColor.color_select : _textColor.color_url;
                break;
            case FuText_number:
                color = modle.select ? _textColor.color_select : _textColor.color_number;
                break;
            case FuText_img:
            {
                NSAttributedString *string = [FuTextModel getReplacementStringWithName:modle.string type:FuText_img size:CGSizeMake(_font.pointSize, _font.pointSize) runWidth:_font.pointSize];
                NSString *imageString = modle.oString;
                if (_selectedRange.location != NSNotFound) {
                    if (_selectedRange.location > modle.range.location) {
                        _selectedRange.location -= (imageString.length - string.length);
                    }
                }
                [aString replaceCharactersInRange:NSMakeRange(modle.range.location, imageString.length) withAttributedString:string];
            }
                
            case FuText_view:
            {
                BOOL isHave = NO;
                CGSize size = [FuTextModel getCustromViewSizeWithImagePath:modle.string viewWidth:_custromViewWidth isHave:&isHave];
                NSAttributedString *string = [FuTextModel getReplacementStringWithName:modle.string type:FuText_view size:size runWidth:_custromViewWidth viewLineSpacing:_viewLineSpacing];
                NSString *imageString = modle.oString;
                if (_selectedRange.location != NSNotFound) {
                    if (_selectedRange.location > modle.range.location) {
                        _selectedRange.location -= (imageString.length - string.length);
                    }
                }
                if (!isHave)
                {
                    NSRange range = NSMakeRange(modle.range.location, string.length);
                    [_viewRunDictionary setObject:modle.string forKey:NSStringFromRange(range)];
                }
                [aString replaceCharactersInRange:NSMakeRange(modle.range.location, imageString.length) withAttributedString:string];
            }
                continue; ///  表情文字 不能在绘制文本中
                
            case FuText_EscapeAnglebracket:
            {
                color = _textColor.color;
                NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:modle.string];
                [string addAttribute:@"type" value:@(FuText_EscapeAnglebracket) range:NSMakeRange(0, string.length)];
                [string addAttribute:@"param" value:@{@"name": modle.string} range:NSMakeRange(0, string.length)];
                [aString replaceCharactersInRange:NSMakeRange(modle.range.location, string.length) withAttributedString:string];
            }
                break;
            default:
                break;
        }
        
        NSRange range = NSMakeRange(modle.range.location, modle.range.length);
        NSMutableDictionary *attrs = [FuTextModel formatAttributesWithFont:_font textColor:color textAlignment:_textAlignment lineSpacing:_lineSpacing paragraphSpacing:_paragraphSpacing lineHeight:self.lineHeight];
        [aString addAttributes:attrs range:range];
    }
    
    [FuTextModel updateAttributesInRange:aString color:_textColor];

    [self dealEventWithAString:aString];
    
    self.attributedString = aString;
    
    return aString;
}

- (void)dealEventWithAString:(NSMutableAttributedString *)aString
{
    NSRange tempRange = _eventRange;
    if (NSMaxRange(tempRange) > aString.length)
    {
        if (tempRange.location < aString.length)
        {
            tempRange = NSMakeRange(tempRange.location, aString.length - tempRange.location);
        }
    }
    if (_eventColor)
    {
        [aString addAttribute:(id)kCTForegroundColorAttributeName value:(id)_eventColor.CGColor range:tempRange];
    }
    
    if (_eventFont)
    {
        CFStringRef fontName = (__bridge CFStringRef)_eventFont.fontName;
        CGFloat fontSize     = _eventFont.pointSize;
        CTFontRef ctfont     = CTFontCreateWithName(fontName, fontSize, NULL);
        [aString addAttribute:(id)kCTFontAttributeName value:(__bridge id)ctfont range:tempRange];
        CFRelease(ctfont);
    }
}


+ (void)updateAttributesInRange:(NSMutableAttributedString *)aString color:(FuTextColor *)color
{
    [aString enumerateAttributesInRange:NSMakeRange(0, aString.length) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        
        @autoreleasepool {
            int type = [attrs[@"type"] intValue];
            NSString *text = [aString.string substringWithRange:range];
            NSDictionary *dic = attrs[@"param"];
            if (type == FuText_at) {
                if ([text isEqualToString:dic[@"name"]])
                {
                    [aString addAttribute:(id)kCTForegroundColorAttributeName value:(id)color.color_at.CGColor range:range];
                } else {
                    [aString removeAttribute:@"type" range:range];
                    [aString removeAttribute:@"param" range:range];
                }
            } else if (type == FuText_topic)
            {
                if ([text isEqualToString:dic[@"name"]]) {
                    [aString addAttribute:(id)kCTForegroundColorAttributeName value:(id)color.color_topic.CGColor range:range];
                } else {
                    [aString removeAttribute:@"type" range:range];
                    [aString removeAttribute:@"param" range:range];
                }
            }
        }
        
    }];
}


- (NSString *)getReallyString
{
    NSString *string = nil;
    [self getReallyString:&string custromViewPathList:nil];
    return string;
}

- (void)getReallyString:(NSString **)string custromViewPathList:(NSArray **)pathList
{
    NSMutableString *result = [[NSMutableString alloc] init];
    NSMutableArray  *list   = [[NSMutableArray alloc] init];
    [_attributedString enumerateAttributesInRange:NSMakeRange(0, _attributedString.length) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        
        @autoreleasepool {
            
            NSString *text = [_attributedString.string substringWithRange:range];
            int type = [attrs[@"type"] intValue];
            NSDictionary *dic = attrs[@"param"];
            if (type == FuText_at)
            {
                if ([text isEqualToString:dic[@"name"]])
                {
                    [result appendFormat:@"{%@,%@}", dic[@"name"], dic[@"uid"]];
                } else {
                    [result appendString:text];
                }
            } else if (type == FuText_topic)
            {
                if ([text isEqualToString:dic[@"name"]])
                {
                    [result appendFormat:@"{%@,%@}", dic[@"name"], dic[@"topicId"]];
                } else {
                    [result appendString:text];
                }
            } else if (type == FuText_img)
            {
                NSString *f = dic[@"name"];
                [result appendFormat:@"[%@]", [f faceFormatToCh]];
            } else if (type == FuText_view)
            {
                NSString *path = dic[@"name"];
                [list addObject:path];
                [result appendFormat:@"<img src=\"%@\">", path];
            } else if (type == FuText_EscapeAnglebracket)
            {
                text = [text stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@"&lt"];
                text = [text stringByReplacingCharactersInRange:NSMakeRange(text.length - 1, 1) withString:@"&gt"];
                [result appendString:text];
            } else
            {
                [result appendString:text];
            }
        }
        
    }];
    if (string)   *string   = result;
    if (pathList) *pathList = list;
}

- (NSString *)getCopyString
{
    NSMutableString *result = [[NSMutableString alloc] init];
    [_attributedString enumerateAttributesInRange:_selectedRange options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        
        @autoreleasepool {
            
            NSString *text = [_attributedString.string substringWithRange:range];
            int type = [attrs[@"type"] intValue];
            NSDictionary *dic = attrs[@"param"];
            if (type == FuText_img)
            {
                NSString *f = dic[@"name"];
                [result appendFormat:@"[%@]", [f faceFormatToCh]];
            } else if (type == FuText_view)
            {
                NSString *f = dic[@"name"];
                [result appendFormat:@"<img src=\"%@\">", f];
            } else
            {
                [result appendString:text];
            }
            
        }
    }];
    
    return result;
}

- (NSMutableDictionary *)attributes
{
    return [FuTextModel formatAttributesWithFont:_font textColor:_textColor.color textAlignment:_textAlignment lineSpacing:_lineSpacing paragraphSpacing:_paragraphSpacing lineHeight:self.lineHeight];
}

+ (NSMutableDictionary *)formatAttributesWithFont:(UIFont *)font
                                        textColor:(UIColor *)textColor
                                    textAlignment:(NSTextAlignment)textAlignment
                                      lineSpacing:(float)lineSpacing
                                 paragraphSpacing:(float)paragraphSpacing
                                       lineHeight:(float)lineHeight
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    if (font)
    {
        CFStringRef fontName = (__bridge CFStringRef)font.fontName;
        CGFloat fontSize     = font.pointSize;
        CTFontRef ctfont     = CTFontCreateWithName(fontName, fontSize, NULL);
        [attributes setObject:(__bridge id)ctfont forKey:(id)kCTFontAttributeName];
        CFRelease(ctfont);
    }
    
    if (textColor)
    {
        CGColorRef color = textColor.CGColor;
        [attributes setObject:(__bridge id)color forKey:(id)kCTForegroundColorAttributeName];
    }
    
    CTTextAlignment alignment;
    if (textAlignment == NSTextAlignmentRight) {
        alignment = kCTTextAlignmentRight;
    } else if (textAlignment == NSTextAlignmentCenter) {
        alignment = kCTTextAlignmentCenter;
    } else {
        alignment = (CTTextAlignment)textAlignment;
    }
    CGFloat lSpacing = roundf(lineSpacing);
    CGFloat minLine  = lineHeight;
    CGFloat maxLine  = lineHeight;
    CGFloat pSpacing = roundf(paragraphSpacing);
    
    CTLineBreakMode lineBreak = kCTLineBreakByCharWrapping;// kCTLineBreakByWordWrapping;//kCTLineBreakByClipping;//换行模式
    
    CTParagraphStyleSetting setting[] = {
        { kCTParagraphStyleSpecifierAlignment,          sizeof(alignment), &alignment},
        { kCTParagraphStyleSpecifierMinimumLineHeight,  sizeof(minLine), &minLine },
        { kCTParagraphStyleSpecifierMaximumLineHeight,  sizeof(maxLine), &maxLine },
        { kCTParagraphStyleSpecifierLineSpacing,        sizeof(lSpacing), &lSpacing },
        { kCTParagraphStyleSpecifierMinimumLineSpacing, sizeof(lSpacing), &lSpacing },
        { kCTParagraphStyleSpecifierMaximumLineSpacing, sizeof(lSpacing), &lSpacing },
        { kCTParagraphStyleSpecifierParagraphSpacing,   sizeof(pSpacing), &pSpacing },
        { kCTParagraphStyleSpecifierLineBreakMode,      sizeof(CTLineBreakMode), &lineBreak }
    };
    
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(setting, sizeof(setting) / sizeof(CTParagraphStyleSetting));
    [attributes setObject:(__bridge id)paragraphStyle forKey:(id)kCTParagraphStyleAttributeName];
    CFRelease(paragraphStyle);
    
    return attributes;
}


/**
 * 正则解析,返回CTRunModel数组
 * 表情：[name]
 * 表情：{!name}
 * @某人：{@name}
 * 话题：{#name}
 **/
+ (NSMutableArray *)parser:(NSString *)str
{
    return [FuTextModel parserWithType:str type:(FuText_at | FuText_img | FuText_normal | FuText_topic | FuText_number | FuText_url) lastRun:nil recordIndex:nil recordOIndex:nil];
}

+ (NSMutableArray *)parserNext:(NSString *)str recordIndex:(NSInteger *)recordIndex recordOIndex:(NSInteger *)recordOIndex
{
    return [FuTextModel parserWithType:str type:(FuText_at | FuText_img | FuText_normal | FuText_topic | FuText_number | FuText_url) lastRun:nil recordIndex:recordIndex recordOIndex:recordOIndex];
}


+ (NSMutableArray *)parserWithType:(NSString *)str type:(int)type lastRun:(FuTextRun *)lastRun recordIndex:(NSInteger *)recordIndex recordOIndex:(NSInteger *)recordOIndex
{
    if (str == nil) return nil;

    // {}
    __block NSMutableArray *richTextChunks = [[NSMutableArray alloc] init];
    [self regChunksWithText:str regString:[self regOfRichText] chunks:richTextChunks];

    // url
    __block NSMutableArray *urlChunks = [[NSMutableArray alloc] init];
    if (type & FuText_url)
    {
        [self regChunksWithText:str regString:[self regOfURL] chunks:urlChunks];
    }
    
    // number
    __block NSMutableArray *numberChunks = [[NSMutableArray alloc] init];
    if (type & FuText_number)
    {
        [self regChunksWithText:str regString:[self regOfNumber] chunks:numberChunks];
    }
    
    // face
    __block NSMutableArray *faceChunks = [[NSMutableArray alloc] init];
    if (type & FuText_img)
    {
        [self regChunksWithText:str regString:[self regOfFace] chunks:faceChunks];
    }
    
    // view
    __block NSMutableArray *viewChunks = [[NSMutableArray alloc] init];
    if (type *FuText_view)
    {
        [self regChunksWithText:str regString:[self regOfView] chunks:viewChunks];
    }
    
    // url和number有交集时取url
    [self eliminateChunksFromSuperChunks:urlChunks chunks:numberChunks];
    // url和face有交集时取url
    [self eliminateChunksFromSuperChunks:urlChunks chunks:faceChunks];
    
    // face和number有交集时取face
    [self eliminateChunksFromSuperChunks:faceChunks chunks:numberChunks];
    
    // view和url有交集时取view
    [self eliminateChunksFromSuperChunks:viewChunks chunks:urlChunks];
    // view和number有交集时取view
    [self eliminateChunksFromSuperChunks:viewChunks chunks:numberChunks];
    // view和face有交集时取view
    [self eliminateChunksFromSuperChunks:viewChunks chunks:faceChunks];
    
    // richText和face有交集时取richText
    [self eliminateChunksFromSuperChunks:richTextChunks chunks:faceChunks];
    // richText和url有交集取richText
    [self eliminateChunksFromSuperChunks:richTextChunks chunks:urlChunks];
    // richText和number有交集取richText
    [self eliminateChunksFromSuperChunks:richTextChunks chunks:numberChunks];
    // richText和view有交集取richText
    [self eliminateChunksFromSuperChunks:richTextChunks chunks:viewChunks];
    // 合并
    [self mergeChunksToRich:richTextChunks chunks:faceChunks];
    [self mergeChunksToRich:richTextChunks chunks:urlChunks];
    [self mergeChunksToRich:richTextChunks chunks:numberChunks];
    [self mergeChunksToRich:richTextChunks chunks:viewChunks];
    
    NSMutableArray *ctrunArray = [[NSMutableArray alloc] init];
    NSInteger index = 0;
    NSInteger indexRun = recordIndex ? *recordIndex : 0;
    NSInteger oIndexRun = recordOIndex ? *recordOIndex : 0;
    
    if (lastRun) {
        oIndexRun = lastRun.oRange.location + lastRun.oRange.length;
    }
    
    for (NSTextCheckingResult *result in richTextChunks)
    {
        // 正常文字
        if (result.range.location < index) continue;
        if (result.range.location >= str.length) break;
        NSString *normalStr = [str substringWithRange:NSMakeRange(index, result.range.location - index)];
        index = result.range.location;
        
        if (normalStr.length > 0)
        {
            FuTextRun *txtModel = [[FuTextRun alloc] init];
            txtModel.type = FuText_normal;
            txtModel.range = CFRangeMake(indexRun, normalStr.length);
            txtModel.string = normalStr;
            txtModel.oRange = CFRangeMake(oIndexRun, normalStr.length);
            txtModel.oString = normalStr;
            indexRun += normalStr.length;
            oIndexRun += normalStr.length;
            [ctrunArray addObject:txtModel];
        }
        // 特殊文字图片
        NSString *speStr = [str substringWithRange:result.range];
        index += result.range.length;
        
        if ([urlChunks containsObject:result]) {
            // url
            FuTextRun *urlModel = [[FuTextRun alloc] init];
            urlModel.type = FuText_url;
            urlModel.range = CFRangeMake(indexRun, speStr.length);
            urlModel.string = speStr;
            urlModel.oRange = CFRangeMake(oIndexRun, speStr.length);
            urlModel.oString = speStr;
            indexRun += speStr.length;
            oIndexRun += speStr.length;
            [ctrunArray addObject:urlModel];
        }
        else if ([faceChunks containsObject:result] && type & FuText_img)
        {
            NSString *imgStr = speStr.length > 2 ? [speStr substringWithRange:NSMakeRange(1, result.range.length - 2)] : speStr;
            if ([imgStr isExistFace])
            {
                FuTextRun *imgModel = [[FuTextRun alloc] init];
                imgModel.type = FuText_img;
                imgModel.range = CFRangeMake(indexRun, 1);
                imgModel.string = imgStr;
                imgModel.oRange = CFRangeMake(oIndexRun, 1);
                imgModel.oString = speStr;
//                imgModel.size = CGSizeMake(18.0, 18.0);
                indexRun ++;
                oIndexRun ++;
                
                [ctrunArray addObject:imgModel];
            }
            else
            {
                FuTextRun *txtModel = [[FuTextRun alloc] init];
                txtModel.type = FuText_normal;
                txtModel.range = CFRangeMake(indexRun, speStr.length);
                txtModel.string = speStr;
                txtModel.oRange = CFRangeMake(oIndexRun, speStr.length);
                txtModel.oString = speStr;
                indexRun += speStr.length;
                oIndexRun += speStr.length;
                [ctrunArray addObject:txtModel];
            }
        }
        else if ([speStr hasPrefix:@"{!"] && type & FuText_img) {
            // 图片名
            NSString *imgStr = speStr.length >= 3 ? [speStr substringWithRange:NSMakeRange(2, result.range.length - 3)] : speStr;
            if ([imgStr isExistFace])
            {
                FuTextRun *imgModel = [[FuTextRun alloc] init];
                imgModel.type = FuText_img;
                imgModel.range = CFRangeMake(indexRun, 1);
                imgModel.string = imgStr;
                imgModel.oRange = CFRangeMake(oIndexRun, 1);
                imgModel.oString = speStr;
//                imgModel.size = CGSizeMake(18.0, 18.0);
                indexRun ++;
                oIndexRun ++;
                
                [ctrunArray addObject:imgModel];
            }
            else if (imgStr.length)
            {
                FuTextRun *txtModel = [[FuTextRun alloc] init];
                txtModel.type = FuText_normal;
                txtModel.range = CFRangeMake(indexRun, 2);
                txtModel.string = [speStr substringToIndex:2];;
                txtModel.oRange = CFRangeMake(oIndexRun, 2);
                txtModel.oString = [speStr substringToIndex:2];;
                indexRun += txtModel.string.length;
                oIndexRun += txtModel.oString.length;
                [ctrunArray addObject:txtModel];
                
                NSArray *arry = [self parserNext:imgStr recordIndex:&indexRun recordOIndex:&oIndexRun];
                if (arry.count)
                {
                    [ctrunArray addObjectsFromArray:arry];
                }
                
                FuTextRun *txtModel2 = [[FuTextRun alloc] init];
                txtModel2.type = FuText_normal;
                txtModel2.range = CFRangeMake(indexRun, 1);
                txtModel2.string = [speStr substringFromIndex:speStr.length - 1];
                txtModel2.oRange = CFRangeMake(oIndexRun, 1);
                txtModel2.oString = [speStr substringFromIndex:speStr.length - 1];
                indexRun += txtModel2.string.length;
                oIndexRun += txtModel2.oString.length;
                [ctrunArray addObject:txtModel2];

            }
            else
            {
                FuTextRun *txtModel = [[FuTextRun alloc] init];
                txtModel.type = FuText_normal;
                txtModel.range = CFRangeMake(indexRun, speStr.length);
                txtModel.string = speStr;
                txtModel.oRange = CFRangeMake(oIndexRun, speStr.length);
                txtModel.oString = speStr;
                indexRun += speStr.length;
                oIndexRun += speStr.length;
                [ctrunArray addObject:txtModel];
            }
        } else if ([speStr hasPrefix:@"{@"] && (type & FuText_at)) {
            // at
            NSRange found = [speStr rangeOfString:@"," options:NSCaseInsensitiveSearch];
            if (found.length > 0)
            {
                NSRange range = [speStr rangeOfString:@","];
                NSString *name = [speStr substringWithRange:NSMakeRange(1, range.location - 1)];
                
                FuTextRun *topicModel = [[FuTextRun alloc] init];
                topicModel.type = FuText_at;
                topicModel.range = CFRangeMake(indexRun, name.length);
                topicModel.string = name;
                topicModel.oRange = CFRangeMake(oIndexRun, name.length);
                topicModel.oString = speStr;
                topicModel.object = [speStr substringWithRange:NSMakeRange(range.location + 1, speStr.length - name.length - 3)];
                indexRun += name.length;
                oIndexRun += name.length;
                [ctrunArray addObject:topicModel];
            }
            else
            {
                FuTextRun *txtModel = [[FuTextRun alloc] init];
                txtModel.type = FuText_normal;
                txtModel.range = CFRangeMake(indexRun, speStr.length);
                txtModel.string = speStr;
                txtModel.oRange = CFRangeMake(oIndexRun, speStr.length);
                txtModel.oString = speStr;
                indexRun += speStr.length;
                oIndexRun += speStr.length;
                [ctrunArray addObject:txtModel];
            }
            
        } else if ([speStr hasPrefix:@"{#"] && type & FuText_topic) {
            // 话题
            NSString *name = [speStr substringWithRange:NSMakeRange(1, result.range.length - 2)];
            
            FuTextRun *altModel = [[FuTextRun alloc] init];
            altModel.type = FuText_topic;
            altModel.range = CFRangeMake(indexRun, name.length);
            altModel.string = name;
            altModel.range = CFRangeMake(oIndexRun, name.length);
            altModel.string = speStr;
            indexRun += name.length;
            oIndexRun += name.length;
            [ctrunArray addObject:altModel];
            
        }
        else if ([numberChunks containsObject:result] && type & FuText_number) {
            // number
            FuTextRun *urlModel = [[FuTextRun alloc] init];
            urlModel.type = FuText_number;
            urlModel.range = CFRangeMake(indexRun, speStr.length);
            urlModel.string = speStr;
            urlModel.oRange = CFRangeMake(oIndexRun, speStr.length);
            urlModel.oString = speStr;
            indexRun += speStr.length;
            oIndexRun += speStr.length;
            [ctrunArray addObject:urlModel];
        }
        else if ([viewChunks containsObject:result] && type & FuText_view) {
            // view
            NSMutableArray *viewImgChunks = [[NSMutableArray alloc] init];
            [self regChunksWithText:speStr regString:[self regOfViewImg] chunks:viewImgChunks];
            if (viewImgChunks.count == 1)
            {
                NSTextCheckingResult *result1 = viewImgChunks.firstObject;
                NSString *srcstring = [speStr substringWithRange:result1.range];
                NSArray *srcList = [srcstring componentsSeparatedByString:@"\""];
                if (srcList.count == 3)
                {
                    NSString *path = [srcList objectAtIndex:1];
                    if (path.length)
                    {
                        BOOL isViewRun = NO;
                        if (path.isUrl)
                        {
                            NSMutableArray *viewImgUrlChunks = [[NSMutableArray alloc] init];
                            [self regChunksWithText:path regString:[self regOfViewImgUrl] chunks:viewImgUrlChunks];
                            isViewRun = (viewImgUrlChunks.count == 1);
                            if (!isViewRun)
                            {
                                [viewImgUrlChunks removeAllObjects];
                                [self regChunksWithText:path regString:[self regOfViewImgUrl2] chunks:viewImgUrlChunks];
                                isViewRun = (viewImgUrlChunks.count == 1);
                            }
                        } else
                        {
                            NSString *tempPath = [path hasPrefix:@"Documents/"] ? path : [NSString stringWithFormat:@"Documents/%@", path];
                            path = [path hasPrefix:NSHomeDirectory()] ? path : [NSHomeDirectory() stringByAppendingPathComponent:tempPath];
                            if ([UIImage imageWithContentsOfFile:path])
                            {
                                isViewRun = YES;
                            }
                        }
                        if (isViewRun)
                        {
                            FuTextRun *viewModel = [[FuTextRun alloc] init];
                            viewModel.type = FuText_view;
                            viewModel.range = CFRangeMake(indexRun, 1);
                            viewModel.string = path;
                            viewModel.oRange = CFRangeMake(oIndexRun, 1);
                            viewModel.oString = speStr;
                            indexRun ++;
                            oIndexRun ++;
                            [ctrunArray addObject:viewModel];
                            
                            continue;
                        }
                    }
                }
            }
            // 当文字处理
            NSString *name = [speStr substringWithRange:NSMakeRange(0, result.range.length)];
            
            FuTextRun *normalModel = [[FuTextRun alloc] init];
            normalModel.type = FuText_EscapeAnglebracket;
            normalModel.range = CFRangeMake(indexRun, name.length);
            normalModel.string = name;
            normalModel.oRange = CFRangeMake(oIndexRun, speStr.length);
            normalModel.oString = speStr;
            indexRun += name.length;
            oIndexRun += speStr.length;
            [ctrunArray addObject:normalModel];
        }
        else {
            // 当文字处理
            NSString *name = [speStr substringWithRange:NSMakeRange(0, result.range.length)];
            
            FuTextRun *normalModel = [[FuTextRun alloc] init];
            normalModel.type = FuText_normal;
            normalModel.range = CFRangeMake(indexRun, name.length);
            normalModel.string = name;
            normalModel.oRange = CFRangeMake(oIndexRun, name.length);
            normalModel.oString = name;
            indexRun += name.length;
            oIndexRun += speStr.length;
            [ctrunArray addObject:normalModel];
        }
    }
    if (index < str.length) {
        
        // 正常文字
        NSString *normalStr = [str substringWithRange:NSMakeRange(index, str.length - index)];
        
        FuTextRun *txtModel = [[FuTextRun alloc] init];
        txtModel.type = FuText_normal;
        txtModel.range = CFRangeMake(indexRun, normalStr.length);
        txtModel.string = normalStr;
        txtModel.oRange = CFRangeMake(oIndexRun, normalStr.length);
        txtModel.oString = normalStr;
        
        if (recordOIndex)
        {
            indexRun += normalStr.length;
            oIndexRun += normalStr.length;
        }
        
        [ctrunArray addObject:txtModel];
        
    } else if (index > str.length) {
        NSLog(@"解析文本出错:解析长度已经超出文本长度");
    }
    
    if (recordIndex) {
        *recordIndex = indexRun;
    }
    if (recordOIndex) {
        *recordOIndex = oIndexRun;
    }
    
    return ctrunArray;
}

#pragma mark - 正则匹配

+ (void)regChunksWithText:(NSString *)text regString:(NSString *)regString chunks:(NSMutableArray *)chunks
{
    NSRegularExpression *richTextExp = [[NSRegularExpression alloc] initWithPattern:regString options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators error:nil];
    chunks.array = [richTextExp matchesInString:text options:0 range:NSMakeRange(0, [text length])];
}

#pragma mark - 剔除

+ (void)eliminateChunksFromSuperChunks:(NSMutableArray *)superChunks chunks:(NSMutableArray *)chunks
{
    __block NSMutableArray *tempArray = [NSMutableArray array];
    [chunks enumerateObjectsUsingBlock:^(id obj1, NSUInteger idx1, BOOL *stop1)
     {
         NSTextCheckingResult *result = (NSTextCheckingResult *)obj1;
         [superChunks enumerateObjectsUsingBlock:^(id obj2, NSUInteger idx2, BOOL *stop2)
          {
              NSTextCheckingResult *superResult = (NSTextCheckingResult *)obj2;
              if (NSIntersectionRange(superResult.range, result.range).length > 0)
              {
                  [tempArray addObject:result];
                  *stop2 = YES;
              }
          }];
     }];
    [chunks removeObjectsInArray:tempArray];
    [tempArray removeAllObjects];
    tempArray = nil;
}

#pragma mark - 合并

+ (void)mergeChunksToRich:(NSMutableArray *)richTextChunks chunks:(NSMutableArray *)chunks
{
    if (richTextChunks.count == 0 && chunks.count > 0)
    {
        [richTextChunks addObjectsFromArray:chunks];
    }
    else
    {
        [chunks enumerateObjectsUsingBlock:^(id obj1, NSUInteger idx1, BOOL *stop1)
         {
            __block NSTextCheckingResult *result = (NSTextCheckingResult *)obj1;
            [richTextChunks enumerateObjectsUsingBlock:^(id obj2, NSUInteger idx2, BOOL *stop2) {
                NSTextCheckingResult *richTextResult = (NSTextCheckingResult *)obj2;
                if (result && richTextResult && NSIntersectionRange(result.range, richTextResult.range).length == 0)
                {
                    if (result.range.location + result.range.length <= richTextResult.range.location)
                    {
                        [richTextChunks insertObject:result atIndex:idx2];
                        *stop2 = YES;
                    }
                    if (idx2 == richTextChunks.count - 1)
                    {
                        [richTextChunks insertObject:result atIndex:richTextChunks.count];
                        *stop2 = YES;
                    }
                }
            }];
        }];
    }
}

+ (NSAttributedString *)getReplacementStringWithName:(NSString *)name type:(FuTextType)type size:(CGSize)size runWidth:(CGFloat)width
{
    return [FuTextModel getReplacementStringWithName:name type:type size:size runWidth:width viewLineSpacing:0];
}

+ (NSAttributedString *)getReplacementStringWithName:(NSString *)name type:(FuTextType)type size:(CGSize)size runWidth:(CGFloat)width viewLineSpacing:(CGFloat)viewLineSpacing
{
    NSString *replacementString = OBJECT_REPLACEMENT_CHARACTER;
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:replacementString];
    [string addAttribute:@"type" value:@(type) range:NSMakeRange(0, string.length)];
    NSMutableDictionary *paramDic = [[NSMutableDictionary alloc] init];
    if (name.length)
    {
        [paramDic setObject:name forKey:@"name"];
    }
    if (!CGSizeEqualToSize(size, CGSizeZero))
    {
        [paramDic setObject:NSStringFromCGSize(size) forKey:@"size"];
    }
    [string addAttribute:@"param" value:paramDic range:NSMakeRange(0, string.length)];
    
    CGFloat imgHeight = size.height;
    CGFloat imgWidth  = width;
    if (size.width > width)
    {
        imgHeight = imgHeight * width / size.width;
    } else
    {
        imgWidth = size.width;
    }
    size = CGSizeMake(imgWidth, imgHeight);
    
    FuTextRun *run = [[FuTextRun alloc] init];
    run.string     = name;
    run.size       = size;
    run.runSize    = CGSizeMake(width, size.height + viewLineSpacing);
    run.type       = type;
    
    CTRunDelegateCallbacks callbacks = run.callbacks;
    CTRunDelegateRef runDelegate = CTRunDelegateCreate(&callbacks, (__bridge_retained void *)run);
    [string addAttributes:@{(id)kCTRunDelegateAttributeName: (__bridge id)runDelegate} range:NSMakeRange(0, string.length)];
    CFRelease(runDelegate);
    return string;
}

+ (CGSize)getCustromViewSizeWithImagePath:(NSString *)path viewWidth:(CGFloat)viewWidth isHave:(BOOL *)isHave
{
    float height = 80;
    float width  = viewWidth;
    
    NSString *sizeString = [[GWWTextCache instance].cache objectForKey:path];
    CGSize imageSize = CGSizeFromString(sizeString);
    if (CGSizeEqualToSize(imageSize, CGSizeZero))
    {
        UIImage *image = nil;
        if (path.isUrl)
        {

        } else
        {
            NSString *tempPath = [path hasPrefix:@"Documents/"] ? path : [NSString stringWithFormat:@"Documents/%@", path];
            path = [path hasPrefix:NSHomeDirectory()] ? path : [NSHomeDirectory() stringByAppendingPathComponent:tempPath];
            image = [UIImage imageWithContentsOfFile:path];
        }
        if (image)
        {
            imageSize = image.size;
            sizeString = NSStringFromCGSize(imageSize);
            [[GWWTextCache instance].cache setObject:sizeString forKey:path];
        }
    }

    if (!CGSizeEqualToSize(imageSize, CGSizeZero))
    {
        height = imageSize.height;
        if (imageSize.width > width)
        {
            height = height * width / imageSize.width;
        } else
        {
            width  = imageSize.width;
            height = imageSize.height;
        }
        *isHave = YES;
    }

    return CGSizeMake(width, height);
}

@end

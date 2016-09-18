//
//  FuToolManager.m
//  Test
//
//  Created by syq on 14/8/13.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuManager.h"
#import "FuDrawViewCell.h"
#import "FuTextLookMagnifier.h"
#import "FuTextSelectedMagnifier.h"
#import "FuTextView.h"


@interface FuManager ()
{
    FuTextEditingCaret      *_caretView;            // 编辑光标
    FuTextLookMagnifier     *_lookMagnifier;        // 查看放大镜
    FuTextSelectedMagnifier *_selectedMagnifier;    // 选中文本放大镜
    FuSelectionGrabber      *_startGrabber;         // 选中文本开始拖把
    FuSelectionGrabber      *_endGrabber;           // 选中文本结束拖把
}

@property (nonatomic, weak) FuTextView  *textView;

@end

@implementation FuManager

- (id)initWithTextView:(FuTextView *)textView
{
    self = [super init];
    if (self)
    {
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textView.spellCheckingType = UITextSpellCheckingTypeDefault;
        self.textView = textView;
        
        _lookMagnifier = [[FuTextLookMagnifier alloc] init]; // 查看放大镜
        _selectedMagnifier = [[FuTextSelectedMagnifier alloc] init]; // 选中放大镜
    }
    return self;
}

- (void)dealloc
{
    [_caretView stopBlink];
}

#pragma mark - 移动查看放大镜

- (void)moveLookMagnifierToPoint:(CGPoint)point
{
    [_caretView delayBlink];
    if (!_lookMagnifier.superview) {
        [_lookMagnifier showInPoint:point];
    }
    [_lookMagnifier moveToPoint:point];
}

#pragma mark - 隐藏查看放大镜

- (void)hideLookMagnifierToPoint:(CGPoint)point
{
    [_lookMagnifier hide];
}

#pragma mark - 编辑光标

- (FuTextEditingCaret *)caretView
{
    if (!_caretView) {
        _caretView   = [[FuTextEditingCaret alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 1.5f, (int)_textView.text.font.lineHeight)];
    }
    return _caretView;
}

#pragma mark - 更新光标

static NSString * const OBJECT_REPLACEMENT_CHARACTER = @"\uFFFC";//Unicode编码 为对象占位符

- (void)updateCaretViewWithLocation:(CFIndex)location line:(CTLineRef)line lineHeight:(float)lineHieght caretHeight:(float)caretHeight
{
    if (location == NSNotFound || !line)
    {
        [self updateCaretViewWithPoint:CGPointZero caretHeight:caretHeight];
    } else
    {
        CGPoint point = CGPointZero;
        point.x = CTLineGetOffsetForStringIndex(line, location, NULL);
        point.y = lineHieght;
        
        if ([self isNeedUpdateCaretOfInsertView])
        {
            point.x = 0;
            point.y = lineHieght + caretHeight;
            caretHeight = _textView.text.font.lineHeight + _textView.text.lineSpacing;
        }
        
//        CFRange lineRange = CTLineGetStringRange(line);
//        NSRange stringRange = NSMakeRange(lineRange.location, lineRange.length);
//        CFIndex lastIndex = location - 1;
//        CFIndex stringLastIndex = _textView.text.selectedRange.location - 2;
//        if (lastIndex < NSMaxRange(stringRange) && lastIndex >= stringRange.location && stringLastIndex < _textView.text.string.length)
//        {
//            NSString *lastCharacter = [_textView.text.string substringWithRange:NSMakeRange(stringLastIndex, 2)]; // 解决手动换行
//            if ([lastCharacter isEqualToString:@"\n "]) // 换行符
//            {
//                point.x =  0;
//                point.y = lineNum * lineHieght;
//            }
//        }
        [self updateCaretViewWithPoint:point caretHeight:caretHeight];
    }
    
    [_textView scrollToCaretPosition];
}

- (BOOL)isNeedUpdateCaretOfInsertView
{
    __block BOOL needChange = NO;
    CFIndex lastIndex = _textView.text.selectedRange.location;
    CFIndex i1 = lastIndex - 1;
    NSUInteger len = _textView.text.attributedString.length;
    if (lastIndex != NSNotFound && i1 >= 0 && lastIndex <= len)
    {
        [_textView.text.attributedString enumerateAttribute:(id)kCTRunDelegateAttributeName inRange:NSMakeRange(i1, 1) options:kNilOptions usingBlock:^(id value, NSRange range, BOOL *stop) {
            if (!value) return;
            
            CTRunDelegateRef runDelegate = (__bridge CTRunDelegateRef)value;
            FuTextRun *attachment = (__bridge FuTextRun *)CTRunDelegateGetRefCon(runDelegate);
            if (!attachment) return;
            
            if (attachment.type == FuText_view)
            {
                needChange = YES;
            }
        }];
        if (lastIndex < len)
        {
            [_textView.text.attributedString enumerateAttribute:(id)kCTRunDelegateAttributeName inRange:NSMakeRange(lastIndex, 1) options:kNilOptions usingBlock:^(id value, NSRange range, BOOL *stop) {
                if (!value) return;
                
                CTRunDelegateRef runDelegate = (__bridge CTRunDelegateRef)value;
                FuTextRun *attachment = (__bridge FuTextRun *)CTRunDelegateGetRefCon(runDelegate);
                if (!attachment) return;
                
                if (attachment.type == FuText_view)
                {
                    needChange = NO;
                }
            }];
        }
    }
    return needChange;
}

- (void)updateCaretViewWithPoint:(CGPoint)point caretHeight:(float)caretHeight
{
    CGRect frame = _caretView.frame;
    frame.origin.y = _textView.edgeInsets.top + _textView.textHeaderView.frame.size.height + point.y;
    frame.origin.x = _textView.edgeInsets.left + point.x;
    if (caretHeight > 0)
    {
        frame.size.height = caretHeight - _textView.text.lineSpacing;
    }
    _caretView.frame = frame;
}

#pragma mark - 选择视图的拖动手柄

- (FuSelectionGrabber *)startGrabber
{
    if (!_startGrabber) {
        _startGrabber = [[FuSelectionGrabber alloc] init];
        _startGrabber.dotMetric = FuSelectionGrabberDotMetricTop;
    }
    return _startGrabber;
}

- (FuSelectionGrabber *)endGrabber
{
    if (!_endGrabber) {
        _endGrabber = [[FuSelectionGrabber alloc] init];
        _endGrabber.dotMetric = FuSelectionGrabberDotMetricBottom;
    }
    return _endGrabber;
}

// 移动选中放大镜
- (void)moveSelectedMagnifierToPoint:(CGPoint)point offY:(float)offY
{
    point = [_textView drawConvertPoint:point];
    if (!_selectedMagnifier.superview) {
        [_selectedMagnifier showInPoint:point offY:offY];
    }
    [_selectedMagnifier moveToPoint:point offY:offY];
}

// 隐藏选中放大镜
- (void)hideSelectedMagnifier
{
    [_selectedMagnifier hide];
}


// 二分查找/折半查找
- (CFIndex)binarySearchForLineNum:(CFArrayRef)lines count:(CFIndex)count location:(CFIndex)location type:(int)type
{
    CFIndex low = 0, high = count - 1, mid;
    while (low <= high)
    {
        CTLineRef minLine = CFArrayGetValueAtIndex(lines, low);
        CFRange minRange = CTLineGetStringRange(minLine);
        if (type == 1 ) {
            if (minRange.location <= location && location <= (minRange.location + minRange.length)) return low;
        } else
        {
            if (minRange.location <= location && location < (minRange.location + minRange.length)) return low;
        }
        
        CTLineRef maxLine = CFArrayGetValueAtIndex(lines, high);
        CFRange maxRange = CTLineGetStringRange(maxLine);
        if (type == 2) {
            if (maxRange.location <= location && location <= (maxRange.location + maxRange.length)) return high;
        } else
        {
            if (maxRange.location < location && location <= (maxRange.location + maxRange.length)) return high;
        }
        
        //当前查找区间R[low..high]非空
        mid = low + ((high-low)/2);
        //使用(low+high)/2会有整数溢出的问题
        //（问题会出现在当low+high的结果大于表达式结果类型所能表示的最大值时，
        //这样，产生溢出后再/2是不会产生正确结果的，而low+((high-low)/2)不存在这个问题
        CTLineRef midLine = CFArrayGetValueAtIndex(lines, mid);
        CFRange midRange = CTLineGetStringRange(midLine);
        if (type == 1) {
            if(midRange.location < location && location <= (midRange.location + midRange.length)) return mid;//查找成功返回
        } else
        {
            if(midRange.location <= location && location < (midRange.location + midRange.length)) return mid;//查找成功返回
        }
        
        BOOL v = type == 1 ? midRange.location >= location : midRange.location > location;
        
        if(v)
            high = mid - 1;//继续在R[low..mid-1]中查找
        else
            low = mid + 1;//继续在R[mid+1..high]中查找
    }
    return -1; //当low>high时表示所查找区间内没有结果，查找失败
}

@end

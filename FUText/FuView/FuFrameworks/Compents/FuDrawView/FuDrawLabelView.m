//
//  FuReusableDrawView.m
//  Test
//
//  Created by syq on 14/8/22.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuDrawLabelView.h"
#import "NSString+FuExtendedStringDrawing.h"

#define SHOW_TEXT_LENGTH 5000

@interface FuDrawLabelView ()
{
    CTFrameRef                    _frameRef;
    CFIndex                       _location;
    NSMutableAttributedString    *_displayAString;
    
    
    BOOL _showEndTruncation;
    FuTextRun *_clickRun;   // 是否击中文本块
    BOOL       _isClickEnd; // 是否击中省略字符
}

@end



@implementation FuDrawLabelView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _showMoreTruncation = YES;
        _clickTextType = FuText_url | FuText_at | FuText_number | FuText_topic;
    }
    return self;
}

- (void)dealloc
{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    
    if (self.lines)
    {
        self.lines = nil;
    }
    
    if (_frameRef)
    {
        CFRelease(_frameRef);
        _frameRef = nil;
    }
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
{
    super.edgeInsets = edgeInsets;
    [self setNeedsLayout];
}

- (void)setNumberOfLines:(NSInteger)numberOfLines
{
    _numberOfLines = numberOfLines;
    _location = 0;
    _displayAString = [[NSMutableAttributedString alloc] init];
    [self updateDisplayAString];
}

- (void)setHighlightedTextColor:(UIColor *)highlightedTextColor
{
    _highlightedTextColor = highlightedTextColor;
    
    NSMutableAttributedString *aString = nil;
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    if (highlightedTextColor)
    {
        CGColorRef color = highlightedTextColor.CGColor;
        [attributes setObject:(__bridge id)color forKey:(id)kCTForegroundColorAttributeName];
        
        aString = [[NSMutableAttributedString alloc] initWithAttributedString:_displayAString];
        [aString addAttributes:attributes range:NSMakeRange(0, aString.length)];
    } else {
        aString = _displayAString;
    }

    if (_frameRef) CFRelease(_frameRef);
    _frameRef  = [self createFrameWithAttributedText:aString];
    self.lines = CTFrameGetLines(_frameRef);
    
    [self setNeedsLayout];
}

#pragma mark - 更新显示文本

- (void)updateDisplayAString
{
    if (_location >= self.attributedText.length) return;
  
    BOOL showAll = NO; // 是否已经全部显示
    CFIndex off = self.attributedText.length - (SHOW_TEXT_LENGTH + _location);
    if (off > 0)
    {
        NSAttributedString *aString = [self.attributedText attributedSubstringFromRange:NSMakeRange(_location, SHOW_TEXT_LENGTH)];
        NSArray *preList = [FuTextModel parser:aString.string];
        
        if (preList.count)
        {
            FuTextRun *run = nil;
            int tNum = 0;
            for (NSInteger i = preList.count - 1; i >= 0; i--) {
                 run = [preList objectAtIndex:i];
                if (run.type != FuText_normal) {
                    tNum ++;
                    if (tNum == 2) { // 不使用倒数第一run，原因是它可能是一个不完整的或者是一个交错的。例如{@温州,800882
                        break;
                    }
                }
            }
            if (run) {
                CFIndex preLength = run.oRange.location + run.oRange.length;
                _textModel.attributedString = [self.attributedText attributedSubstringFromRange:NSMakeRange(_location, preLength)];
                [_displayAString appendAttributedString:[_textModel getAttrString]];
                _location += preLength;
            } else { // 没有符合规则的run 则折半处理。
                _textModel.attributedString = [self.attributedText attributedSubstringFromRange:NSMakeRange(_location, SHOW_TEXT_LENGTH/2)];
                [_displayAString appendAttributedString:[_textModel getAttrString]];
                _location += SHOW_TEXT_LENGTH/2;
            }
        } else { // 没有run 则折半处理。
            _textModel.attributedString = [self.attributedText attributedSubstringFromRange:NSMakeRange(_location, SHOW_TEXT_LENGTH/2)];
            [_displayAString appendAttributedString:[_textModel getAttrString]];
            _location += SHOW_TEXT_LENGTH/2;
        }
    } else
    {
        showAll = YES;
        _textModel.attributedString = [self.attributedText attributedSubstringFromRange:NSMakeRange(_location, (self.attributedText.length - _location))];
        [_displayAString appendAttributedString:[_textModel getAttrString]];
        _location = self.attributedText.length;
    }
    
    if (_frameRef) CFRelease(_frameRef);
    _frameRef  = [self createFrameWithAttributedText:_displayAString];
    self.lines = CTFrameGetLines(_frameRef);
    self.lineCount = CFArrayGetCount(self.lines);
    if (!showAll && self.lineCount > 1) {
        self.lineCount = self.lineCount - 1;
    }
    
    [self updateTruncationEndText];
    
    [self setNeedsLayout];
}

- (void)setShowMoreTruncation:(BOOL)showMoreTruncation
{
    _showMoreTruncation = showMoreTruncation;
    
    [self updateTruncationEndText];
    [self setNeedsLayout];
}


- (void)updateTruncationEndText
{
    _showEndTruncation = NO;
    
    if (_numberOfLines > 0 && _numberOfLines < self.lineCount) {
        _location = self.attributedText.length;
        
        CTLineRef line = CFArrayGetValueAtIndex(self.lines, (_numberOfLines - 1));
        CFRange stringRange = CTLineGetStringRange(line);
        CFIndex length = stringRange.length + stringRange.location;
        [_displayAString deleteCharactersInRange:NSMakeRange(length, _displayAString.length - length)];
        
        float oldLineHeight = [[self.lineHeightDictionary objectForKey:@(_numberOfLines - 2).stringValue] floatValue];
        float cLineHeight = [[self.lineHeightDictionary objectForKey:@(_numberOfLines - 1).stringValue] floatValue];
        float lineHeight = cLineHeight - oldLineHeight;
        
        UIFont *endfont = [UIFont systemFontOfSize:(self.font.pointSize - 2)];
        NSUInteger len = 0;
        CGSize moresize = CGSizeZero;
        CGSize endsize  = CGSizeZero;
        NSAttributedString *moreString = nil;
        if (_showMoreTruncation)
        {
            moreString = [[NSAttributedString alloc] initWithString:@"..." attributes:_textModel.attributes];
            len += moreString.length;
            moresize = [moreString.string sizeWithFontOfCompatible:self.font constrainedToSize:CGSizeMake(MAXFLOAT, lineHeight)];
        }
    
        if (_truncationEndText.length)
        {
            _showEndTruncation = YES;
            
            len += _truncationEndText.length;
            endsize = [_truncationEndText sizeWithFontOfCompatible:endfont constrainedToSize:CGSizeMake(MAXFLOAT, lineHeight)];
        }
        
        float mwidth = moresize.width + endsize.width;
        
        for (NSInteger i = stringRange.length - 1; (i > 0 && mwidth > 0); i--)
        {
            float x = CTLineGetOffsetForStringIndex(line, (i + stringRange.location), NULL);
            float tempWidth = self.tableView.frame.size.width - self.edgeInsets.left - self.edgeInsets.right - x;
            
            if (mwidth <= tempWidth) {
                len = (stringRange.length - i);
                break;
            }
        }
        
        if (len > 0 && len < _displayAString.length) {
            NSRange range = NSMakeRange(_displayAString.length - len, len);
            [_displayAString deleteCharactersInRange:range];
        }
        
        if (_showMoreTruncation) {
            [_displayAString appendAttributedString:moreString];
        }
        
        if (_truncationEndText.length)
        {
            NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
            CFStringRef fontName = (__bridge CFStringRef)endfont.fontName;
            CGFloat fontSize     = endfont.pointSize;
            CTFontRef ctfont     = CTFontCreateWithName(fontName, fontSize, NULL);
            [attributes setObject:(__bridge id)ctfont forKey:(id)kCTFontAttributeName];
            CFRelease(ctfont);
            
            NSMutableAttributedString *tString = [[NSMutableAttributedString alloc] initWithString:_truncationEndText attributes:attributes];
            
            [tString addAttribute:NSForegroundColorAttributeName value:_textModel.textColor.color_at range:NSMakeRange(0, tString.length)];
            [_displayAString appendAttributedString:tString];
        }
        
        if (_frameRef) CFRelease(_frameRef);
        _frameRef = [self createFrameWithAttributedText:_displayAString];
        self.lines = CTFrameGetLines(_frameRef);
        self.lineCount = CFArrayGetCount(self.lines);
    }
}

- (void)layoutSubviews
{
    [self reloadTable];
    [super layoutSubviews];
}

#pragma mark - UITableView Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_numberOfLines >= self.lineCount) {
        return self.lineCount;
    }
    return _numberOfLines > 0 ? _numberOfLines : self.lineCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CTLineRef line = CFArrayGetValueAtIndex(self.lines, indexPath.row);
    CGFloat ascent;
    CGFloat descent;
    CGFloat leading;
    CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    float height = fabs(ascent) + fabs(descent) + fabs(leading);
    float oldH = [[self.lineHeightDictionary objectForKey:@(indexPath.row - 1).stringValue] floatValue];
    NSInteger row = [self tableView:tableView numberOfRowsInSection:indexPath.section];
    if (indexPath.row < row - 1)
    {
        height += _textModel.lineSpacing;
    } else
    {
        oldH = oldH + _textModel.lineSpacing;
    }
    [self.lineHeightDictionary setObject:@(height + oldH) forKey:@(indexPath.row).stringValue];
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *tempId = @"DrawLabelView";
    FuDrawViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tempId];
    if (!cell) {
        cell = [[FuDrawViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tempId edgeInsets:self.edgeInsets];
    }
    NSInteger row = indexPath.row;
    if (row == self.lineCount - 1 && _location < self.attributedText.length) {
        [self updateDisplayAString];
    }

    CTLineRef line = CFArrayGetValueAtIndex(self.lines, row);
    CGFloat ascent;
    CGFloat descent;
    CGFloat leading;
    CGFloat width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    
    FuLineMetrics metrics;
    metrics.ascent  = ascent;
    metrics.descent = descent;
    metrics.leading = leading;
    metrics.width   = width;
    metrics.trailingWhitespaceWidth = CTLineGetTrailingWhitespaceWidth(line);
    
    float height = fabs(ascent) + fabs(descent) + fabs(leading);
    CGRect lineRect = CGRectMake(self.edgeInsets.left, 0.0, tableView.bounds.size.width - self.edgeInsets.left - self.edgeInsets.right, fabsf(height));
    
    FuLineLayout *lineLayout = [[FuLineLayout alloc] initWithLine:line index:row rect:lineRect metrics:metrics];
    lineLayout.attributedString = [_displayAString attributedSubstringFromRange:lineLayout.stringRange];
    
    [self updateLineLayoutHighlightMarkedRect:lineLayout];
    
    cell.line = lineLayout;
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];

    return cell;
}

#pragma mark - FuTableView Delegate

- (void)tableViewDidTouchEnd:(UITouch *)touch point:(CGPoint)point
{
    if ([self.delegate respondsToSelector:@selector(drawViewClickTextRun:)])
    {
        if (_isClickEnd) {
            FuTextRun *run = [[FuTextRun alloc] init];
            run.type = FuText_truncation;
            run.string = _truncationEndText;
            run.oString = _truncationEndText;
            [self.delegate drawViewClickTextRun:run];
        } else if (_clickRun) {
            [self.delegate drawViewClickTextRun:_clickRun];
        }
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (_clickTextType & FuText_none) {
        return self.tableView.scrollEnabled ? [super hitTest:point withEvent:event] : nil;
    } else if ([self canHitTest:point]) {
        return [super hitTest:point withEvent:event];
    } else if (_clickTextType & FuText_all) {
        return [super hitTest:point withEvent:event];
    }
    return nil;
}


- (BOOL)canHitTest:(CGPoint)point
{
    _isClickEnd = NO;
    _clickRun = nil;
    
    CGPoint tpoint = [self.tableView convertPoint:point fromView:self];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:tpoint];
    if (indexPath == nil) {
        return NO;
    } else {
        CTLineRef line = CFArrayGetValueAtIndex(self.lines, indexPath.row);
        CFIndex index =  CTLineGetStringIndexForPosition(line, CGPointMake(tpoint.x - self.edgeInsets.left, tpoint.y));
        if (index == NSNotFound) {
            return NO;
        } else {
            if (_showEndTruncation && index >= (_displayAString.length - _truncationEndText.length)) {
                if (FuText_truncation & _clickTextType || FuText_all & _clickTextType) {
                    _isClickEnd = YES;
                }
                return _isClickEnd;
            } else {
                _clickRun = [_textModel binarySearchForTextRun:index];
                if (_clickRun.type & _clickTextType || FuText_all & _clickTextType) {
                    return YES;
                } else {
                    return NO;
                }
            }
        }
    }
    
    return NO;
}

@end

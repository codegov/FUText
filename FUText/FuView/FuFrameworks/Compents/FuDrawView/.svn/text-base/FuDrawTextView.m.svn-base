//
//  FuDrawTextView.m
//  Test
//
//  Created by syq on 14/8/27.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuDrawTextView.h"

@interface FuDrawTextView ()
{
    CTFrameRef                    _frameRef;
}

@end

@implementation FuDrawTextView

- (void)dealloc
{
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

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _numberOfLines = -1;
    }
    return self;
}

- (void)setNumberOfLines:(NSInteger)numberOfLines
{
    _numberOfLines = numberOfLines;
    
    [self reloadTable];
}


- (void)setAttributedText:(NSAttributedString *)attributedText
{
    super.attributedText = attributedText;
    
    if (_frameRef) {
        CFRelease(_frameRef);
        _frameRef = nil;
    }
    self.lines = nil;
    self.lineCount = 0;
    if (attributedText.length)
    {
        _frameRef = [self createFrameWithAttributedText:attributedText];
        self.lines = CTFrameGetLines(_frameRef);
        self.lineCount = CFArrayGetCount(self.lines);
    }
    [self reloadTable];
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
    static NSString *tempId = @"DrawTextView";
    FuDrawViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tempId];
    if (!cell) {
        cell = [[FuDrawViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tempId edgeInsets:self.edgeInsets];
    }
    NSInteger row = indexPath.row;
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
    CGRect lineRect = CGRectMake(self.edgeInsets.left, 0.0, tableView.bounds.size.width - self.edgeInsets.left - self.edgeInsets.right, height);
    
    FuLineLayout *lineLayout = [[FuLineLayout alloc] initWithLine:line index:row rect:lineRect metrics:metrics];
    lineLayout.attributedString = [self.attributedText attributedSubstringFromRange:lineLayout.stringRange];
    
    [self updateLineLayoutHighlightMarkedRect:lineLayout];
    
    cell.line = lineLayout;
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];

    return cell;
}

@end

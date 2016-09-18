//
//  FuDrawView.m
//  Test
//
//  Created by syq on 14/8/12.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuDrawView.h"


@interface FuDrawView ()
{
    BOOL _isScroll;
}

@end

@implementation FuDrawView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _lineHeightDictionary = [[NSMutableDictionary alloc] init];
        _edgeInsets      = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
        
        _tableView = [[FuTableView alloc] initWithFrame:self.bounds];
        _tableView.delegate   = self;
        _tableView.dataSource = self;
        _tableView.fuDelegate = self;
        _tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:_tableView];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureStateChanged:)];
        [_tableView addGestureRecognizer:longPress];
    }
    return self;
}

- (void)setTextHeaderView:(UIView *)textHeaderView
{
    _textHeaderView = textHeaderView;
    [self updateHeader];
}

- (void)setTextFooterView:(UIView *)textFooterView
{
    _textFooterView = textFooterView;
    [self updateFooter];
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
{
    _edgeInsets = edgeInsets;
    [self updateHeader];
    [self updateFooter];
}

- (void)updateHeader
{
    if (_tableView.tableHeaderView.subviews.count == 2)
    {
        UIView *view1 = _tableView.tableHeaderView.subviews.firstObject;
        CGRect frame = view1.frame;
        frame.size.height = _edgeInsets.top;
        view1.frame = frame;
        
        UIView *view2 = _tableView.tableHeaderView.subviews.lastObject;
        frame = _textHeaderView.frame;
        frame.origin.y = _edgeInsets.top;
        view2.frame = frame;
        
        if (view2 != _textHeaderView)
        {
            [view2 removeFromSuperview];
            view2 = nil;
            frame = _textHeaderView.frame;
            frame.origin.y = _edgeInsets.bottom;
            _textHeaderView.frame = frame;
            view2 = _textHeaderView;
            [_tableView.tableHeaderView addSubview:_textHeaderView];
        }
        
        frame = _tableView.tableHeaderView.frame;
        frame.size.height = view2.frame.origin.y + view2.frame.size.height;
        _tableView.tableHeaderView.frame = frame;
    } else
    {
        _tableView.tableHeaderView = [self createViewWithHeight:_edgeInsets.top otherView:_textHeaderView];
    }
}

- (void)updateFooter
{
    if (_tableView.tableFooterView.subviews.count == 2)
    {
        UIView *view1 = _tableView.tableFooterView.subviews.firstObject;
        CGRect frame = view1.frame;
        frame.size.height = _edgeInsets.bottom;
        view1.frame = frame;
        
        UIView *view2 = _tableView.tableFooterView.subviews.lastObject;
        frame = _textFooterView.frame;
        frame.origin.y = _edgeInsets.bottom;
        view2.frame = frame;
        
        if (view2 != _textFooterView)
        {
            [view2 removeFromSuperview];
            view2 = nil;
            frame = _textFooterView.frame;
            frame.origin.y = _edgeInsets.bottom;
            _textFooterView.frame = frame;
            view2 = _textFooterView;
            [_tableView.tableFooterView addSubview:_textFooterView];
        }
        
        frame = _tableView.tableFooterView.frame;
        frame.size.height = view2.frame.origin.y + view2.frame.size.height;
        _tableView.tableFooterView.frame = frame;
    } else
    {
        _tableView.tableFooterView = [self createViewWithHeight:_edgeInsets.bottom otherView:_textFooterView];
    }
}

- (UIView *)createViewWithHeight:(float)height otherView:(UIView *)otherView
{
    UIView *topView = [[UIView alloc] init];
    float y = 0.0;
    if (height > 0) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, y, self.bounds.size.width, height)];
        [topView addSubview:headerView];
        y = height;
    }
    if (otherView) {
        CGRect frame = otherView.frame;
        frame.origin.y = y;
        otherView.frame = frame;
        [topView addSubview:otherView];
        y += frame.size.height;
    }
    topView.frame = CGRectMake(0.0, 0.0, _tableView.frame.size.width, y);
    return topView;
}

#pragma mark - 长按事件

- (void)longPressGestureStateChanged:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [gestureRecognizer locationInView:_tableView];
    if ([_delegate respondsToSelector:@selector(drawViewDidLongPress:point:)]) {
        [_delegate drawViewDidLongPress:gestureRecognizer point:point];
    }
}

#pragma mark - 手势事件

- (void)tableViewDidTouchBegin:(UITouch *)touch point:(CGPoint)point
{
    if (_isScroll) {
        return;
    }
    if ([_delegate respondsToSelector:@selector(drawViewDidTouchBegin:point:)]) {
        [_delegate drawViewDidTouchBegin:touch point:point];
    }
}

- (void)tableViewDidTouchMove:(UITouch *)touch point:(CGPoint)point
{
    if ([_delegate respondsToSelector:@selector(drawViewDidTouchMove:point:)]) {
        [_delegate drawViewDidTouchMove:touch point:point];
    }
}

- (void)tableViewDidTouchEnd:(UITouch *)touch point:(CGPoint)point
{
    if ([_delegate respondsToSelector:@selector(drawViewDidTouchEnd:point:)]) {
        [_delegate drawViewDidTouchEnd:touch point:point];
    }
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _isScroll = YES;
    if ([_delegate respondsToSelector:@selector(drawViewWillBeginDragging:)]) {
        [_delegate drawViewWillBeginDragging:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (!scrollView.isTracking && !scrollView.isDecelerating && !scrollView.isDragging) {
        _isScroll = NO;
    }
    if ([_delegate respondsToSelector:@selector(drawViewDidEndDecelerating:)]) {
        [_delegate drawViewDidEndDecelerating:self];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
        _isScroll = NO;
    
    if (!decelerate && [_delegate respondsToSelector:@selector(drawViewDidEndDragging:)]) {
        [_delegate drawViewDidEndDragging:self];
    }
}

//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
//{
//    _isScroll = NO;
//    if ([_delegate respondsToSelector:@selector(drawViewDidEndDecelerating:)]) {
//        [_delegate drawViewDidEndDecelerating:self];
//    }
//}
//
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
//{
//    _isScroll = NO;
//    if (!decelerate && [_delegate respondsToSelector:@selector(drawViewDidEndDragging:)]) {
//        [_delegate drawViewDidEndDragging:self];
//    }
//}

#pragma mark - 得到点所处于的行号

- (CFIndex)getLineNumWithPoint:(CGPoint)point
{
    NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:point];
    NSInteger vRow = 0;
    if (point.y < _tableView.tableHeaderView.frame.size.height && indexPath == nil) {
        vRow = 0;
    } else if (indexPath == nil) {
        vRow = _lineCount - 1;
    } else {
        vRow = indexPath.row;
    }
    return vRow;
}

#pragma mark - 得到点所处于行的位置

- (CFIndex)getLineLocationWithPoint:(CGPoint)point
{
    CFIndex row = [self getLineNumWithPoint:point];
    CTLineRef line = CFArrayGetValueAtIndex(_lines, row);
    CFIndex index = CTLineGetStringIndexForPosition(line, point);
    return index;
}

#pragma mark - 刷新表格

- (void)reloadTable
{
    [_tableView reloadData];
}

- (CTFrameRef)createFrameWithAttributedText:(NSAttributedString *)attributedText
{
    CFAttributedStringRef attributedString = (__bridge CFAttributedStringRef)attributedText;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attributedString);
    
	CGRect frameRect = CGRectZero;
    frameRect.size.width = _tableView.frame.size.width - _edgeInsets.left - _edgeInsets.right;
    frameRect.size.height = MAXFLOAT;
    frameRect.origin.y  = _tableView.frame.size.height - MAXFLOAT;
    frameRect.origin.x = _edgeInsets.left;
    
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, frameRect);
	CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributedText.length), path, NULL);
	CGPathRelease(path);
    CFRelease(framesetter);
    
    return frame;
}

#pragma mark - UITableView Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _lineCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *tempId = @"Test";
    FuDrawViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tempId];
    if (!cell) {
        cell = [[FuDrawViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tempId edgeInsets:_edgeInsets];
    }
    
    return cell;
}

#pragma mark - 更新行的高亮标记文件的位置大小

- (void)updateLineLayoutHighlightMarkedRect:(FuLineLayout *)lineLayout
{
    if (_highlightRange.location == NSNotFound || _highlightRange.length == 0) {
        lineLayout.highlightRect = CGRectZero;
    } else if (_highlightRange.location >= NSMaxRange(lineLayout.stringRange)) {
        lineLayout.highlightRect = CGRectZero;
    } else {
        CGRect rect = CGRectZero;
        float y = 0;
        CFIndex index = NSMaxRange(_highlightRange);
        CFIndex lineIndex = NSMaxRange(lineLayout.stringRange);
        if (_highlightRange.location >= lineLayout.stringRange.location)
        {
            float x = CTLineGetOffsetForStringIndex(lineLayout.line, _highlightRange.location, NULL);
            if (index > lineIndex) {
                rect = CGRectMake(x, y, lineLayout.rect.size.width - x, lineLayout.rect.size.height);
            } else {
                float x2 = CTLineGetOffsetForStringIndex(lineLayout.line, index, NULL);
                rect = CGRectMake(x, y, x2 - x, lineLayout.rect.size.height);
            }
        } else {
            if (index > lineIndex) {
                rect = CGRectMake(0.0, y, lineLayout.rect.size.width, lineLayout.rect.size.height);
            } else {
                float x2 = CTLineGetOffsetForStringIndex(lineLayout.line, index, NULL);
                rect = CGRectMake(0.0, y, x2, lineLayout.rect.size.height);
            }
        }
        lineLayout.highlightRect = rect;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([_delegate respondsToSelector:@selector(drawViewDidScroll:)]) {
        [_delegate drawViewDidScroll:self];
    }
}


@end

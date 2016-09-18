//
//  FuLabel.m
//  Test
//
//  Created by syq on 14/8/12.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuLabel.h"
#import "FuDrawLabelView.h"


@interface FuLabel ()<FuDrawViewDelegate>
{
    FuDrawLabelView     *_contentView;
    
    BOOL _isLongPress;
    BOOL _isHighlight;
}
@end

@implementation FuLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _showMoreTruncation = YES;
        _clickTextType = FuText_url | FuText_at | FuText_number | FuText_topic;
        [self createContentView];
        self.scrollEnabled = NO;
    }
    return self;
}

- (void)createContentView          // 绘制对象
{
    _contentView = [[FuDrawLabelView alloc] initWithFrame:self.bounds];
    _contentView.delegate = self;
    [self addSubview:_contentView];
}

- (void)dealloc
{
    _contentView.delegate = nil;
    _contentView = nil;
}

- (void)setScrollEnabled:(BOOL)scrollEnabled
{
    _scrollEnabled = scrollEnabled;
    _contentView.tableView.scrollEnabled = scrollEnabled;
}

- (void)setClickTextType:(FuTextType)clickTextType
{
    _clickTextType = clickTextType;
    _contentView.clickTextType = clickTextType;
}

- (void)setTextModel:(FuTextModel *)textModel
{
    _textModel = textModel;
    [self setNeedsLayout];
}


- (void)setNumberOfLines:(NSInteger)numberOfLines
{
    _numberOfLines = numberOfLines < 0 ? 0 : numberOfLines;
    [self setNeedsLayout];
}

- (void)setTruncationEndText:(NSString *)truncationEndText
{
    _truncationEndText = truncationEndText;
    [self setNeedsLayout];
}

- (void)setShowMoreTruncation:(BOOL)showMoreTruncation
{
    _showMoreTruncation = showMoreTruncation;
    [self setNeedsLayout];
}


- (void)layoutSubviews
{
    _contentView.clickTextType      = _clickTextType;
    _contentView.font               = _textModel.font;
    _contentView.lineHeight         = _textModel.lineHeight;
    _contentView.textModel          = _textModel;
    _contentView.attributedText     = _textModel.string.length ? [[NSMutableAttributedString alloc] initWithString:_textModel.string] : [[NSMutableAttributedString alloc] init]; //[_textModel getAttrString];
    
    _contentView.truncationEndText  = _truncationEndText;
    _contentView.showMoreTruncation = _showMoreTruncation;
    _contentView.edgeInsets         = _edgeInsets;
    _contentView.numberOfLines      = _numberOfLines;

    [super layoutSubviews];
}

+ (float)heightWithTextModel:(FuTextModel *)model
               numberOfLines:(NSInteger)numberOfLines
                 contentSize:(CGSize)contentSize
{
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:[model getAttrString]];
    CFAttributedStringRef attributedString = (__bridge CFAttributedStringRef)attributedText;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attributedString);
    
    CGRect frameRect = CGRectZero;
    frameRect.size.width  = contentSize.width;
    frameRect.size.height = MAXFLOAT;
    frameRect.origin.y    = - MAXFLOAT;
    frameRect.origin.x    = 0.0;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, frameRect);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributedText.length), path, NULL);
    CGPathRelease(path);
    CFRelease(framesetter);
    
    CFArrayRef lines = CTFrameGetLines(frame);
    NSInteger lineCount = CFArrayGetCount(lines);
    
    if (numberOfLines > 0 && numberOfLines < lineCount) {
        lineCount = numberOfLines;
    }
    
    float lineHeight = 0;
    for (int i = 0; i < lineCount; i++)
    {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGFloat ascent;
        CGFloat descent;
        CGFloat leading;
        CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        float height = 0;
        height -= ascent; // 字体原点 与 系统原点 有ascent偏离，则将字体原点向上偏移ascent
        height -= fabs(descent);
        height -= leading;
        height -= model.lineSpacing;
        height = fabsf(height);
        lineHeight += height;
    }
    CFRelease(frame);
    
    return lineHeight > contentSize.height ? contentSize.height : lineHeight;
}

#pragma mark - FuDrawViewDelegate

- (void)drawViewClickTextRun:(FuTextRun *)textRun
{
    
    if (_isHighlight) {
        _isHighlight = NO;
        _contentView.highlightRange = NSMakeRange(0, 0);
        [_contentView reloadTable];
        [self hideEditingMenu];
    }
    if (_isLongPress) return;
    if ([_delegate respondsToSelector:@selector(labelClickTextRun:)]) {
        [_delegate labelClickTextRun:textRun];
    }
}

- (void)drawViewDidLongPress:(UILongPressGestureRecognizer *)longPress point:(CGPoint)point
{
//    _mouseLocation = [gestureRecognizer locationInView:_contentView.tableView];
    
    if (longPress.state == UIGestureRecognizerStateBegan)
    {
        _isLongPress = YES;
        _contentView.highlightRange = NSMakeRange(0, _contentView.attributedText.length);
        [_contentView reloadTable];
        [self becomeFirstResponder];
        [self showEditingMenuWithPoint:point];
    } else if (longPress.state == UIGestureRecognizerStateChanged)
    {
     
    } else if (longPress.state == UIGestureRecognizerStateEnded ||
               longPress.state == UIGestureRecognizerStateCancelled ||
               longPress.state == UIGestureRecognizerStateFailed)
    {
        _isLongPress = NO;
        _isHighlight = YES;
//        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
//        if (pasteboard.string.length)
//        {
//            if (self.text.string.length) {
//                self.menuType = FuMenuTypeWithSelect | FuMenuTypeWithSelectAll | FuMenuTypeWithPaste;
//            } else {
//                self.menuType = FuMenuTypeWithPaste;
//            }
//            [self showEditingMenu];
//        } else if (self.text.string.length)
//        {
//            self.menuType = FuMenuTypeWithSelect | FuMenuTypeWithSelectAll;
//            [self showEditingMenu];
//        }
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - 编辑菜单

- (void)showEditingMenuWithPoint:(CGPoint)point
{
    CGRect rect = CGRectMake(point.x, point.y, 0, 0); // 默认显示在光标处
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    menuController.arrowDirection    = UIMenuControllerArrowDefault;
    [menuController setTargetRect:rect inView:_contentView.tableView];
    [menuController setMenuVisible:YES animated:YES];
}

#pragma mark - 隐藏菜单

- (void)hideEditingMenu
{
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    [menuController setMenuVisible:NO animated:YES];
}

#pragma mark - 菜单功能

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender  // 要想显示菜单，必须重新此方法
{
    if (action == @selector(copy:))
    {
        return YES;
    }
    return NO; //隐藏系统默认的菜单项
}

#pragma mark - 拷贝

- (void)copy:(id)sender
{
    _isHighlight = NO;
    _contentView.highlightRange = NSMakeRange(0, 0);
    [_contentView reloadTable];
    
    FuTextModel *model = [[FuTextModel alloc] init];
    model.attributedString = _contentView.attributedText;
    [model getAttrString];
    model.selectedRange = NSMakeRange(0, model.string.length);
    NSString *string = [model getCopyString];
    
#if TARGET_OS_IPHONE
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = string;
#else
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard writeObjects:@[string]];
#endif
}

@end

//
//  FuTextInput.m
//  Test
//
//  Created by syq on 14-5-28.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuTextInput.h"
#import "FuTextView.h"
#import "FuTextRun.h"


//static NSString * const OBJECT_REPLACEMENT_CHARACTER = @"\uFFFC";//Unicode编码 为对象占位符
static NSString * const ZERO_WIDTH_SPACE = @"\u200B";
static NSString * const LINE_SEPARATOR   = @"\u2028";
static NSString * const PARAGRAPH_SEPARATOR = @"\u2029";


@interface FuTextInput ()
{
    BOOL _isSpace; // 是否是空格
    
    __weak FuTextView *_responderView;
}
@property (nonatomic, readonly) NSMutableAttributedString *editingAttributedText;
@property (nonatomic, strong) UITextInputStringTokenizer *tokenizer;

@property (nonatomic) CGPoint preTextPoint;

@end

@implementation FuTextInput

#if TARGET_OS_IPHONE
@synthesize inputDelegate;
@synthesize markedTextStyle;
#endif

- (id)initWithTextView:(FuTextView *)textView
{
    self = [super init];
    if (self)
    {
        _responderView = textView;
        _editable      = YES;
    }
    return self;
}

#pragma mark - 属性

- (void)setEditable:(BOOL)editable
{
    _editable = editable;
    if (!_editable) {
        _isEditing = NO;
    }
}

- (void)setIsEditing:(BOOL)isEditing
{
    if (!_editable) return;
    _isEditing = isEditing;
}

- (NSMutableAttributedString *)editingAttributedText
{
    return _responderView.text.attributedString ? _responderView.text.attributedString.mutableCopy : [[NSMutableAttributedString alloc] init];
}

- (void)clearCurrentTriggerString
{
    _currentTriggerString = @"";
}

#pragma mark - 第一响应视图 重写父类方法

- (UIResponder *)nextResponder
{
    return _responderView;
}

#pragma mark - 设置可以获得焦点 重写父类方法

- (BOOL)canBecomeFirstResponder
{
    return _editable;
}

- (BOOL)becomeFirstResponder
{
    if ([self canBecomeFirstResponder]) {
        self.isEditing = YES;
        return [super becomeFirstResponder];
    } else {
        self.isEditing = NO;
    }
    return NO;
}

- (BOOL)canResignFirstResponder
{
    return _editable;
}

- (BOOL)resignFirstResponder
{
    self.isEditing = NO;
    if ([self canResignFirstResponder]) {
        if (self.canEditAttachments) { // 可以编辑附件时，保证是编辑状态
            self.isEditing = YES;
        }
        return [super resignFirstResponder];
    }
    return NO;
}

- (UIView *)inputView
{
    return _responderView.inputView;
}

- (UIView *)inputAccessoryView
{
    return _responderView.inputAccessoryView;
}

#pragma mark - 重写UITextInput接口的方法

- (NSString *)textInRange:(UITextRange *)range
{
    FuTextRange *r = (FuTextRange *)range;
    if (r.range.location == NSNotFound) {
        return nil;
    }
    if (_responderView.text.attributedString.string.length < NSMaxRange(r.range)) {
        return nil;
    }
    
    NSString *text = [_responderView.text.attributedString.string substringWithRange:r.range];
    return text;
}

- (void)replaceRange:(UITextRange *)range withText:(NSString *)text
{
    FuTextRange *r = (FuTextRange *)range;

    if (!text.length) return;
    
    NSRange selectedRange = _responderView.text.selectedRange;
    if (r.range.location + r.range.length <= selectedRange.location && selectedRange.location != NSNotFound) { // 在选中范围的前面替换文本，则更新选中范围的位置
        selectedRange.location -= r.range.length - text.length;
    } else {
        selectedRange.location = text.length;
    }

//    NSMutableString *editingText = _responderView.text.string.length ? _responderView.text.string.mutableCopy : [[NSMutableString alloc] init];
//    [editingText replaceCharactersInRange:r.range withString:text];
    
//    _responderView.text.string = editingText.copy;
    
    NSMutableAttributedString *editingAttributedText = self.editingAttributedText;
    [self replaceCharactersInRange:r.range withString:text forAttributedString:editingAttributedText];
    _responderView.text.selectedRange  = selectedRange;
    
    [self addAttributesWithText:editingAttributedText];
}

- (UITextRange *)selectedTextRange
{
    return [FuTextRange rangeWithNSRange:_responderView.text.selectedRange];
}

- (void)setSelectedTextRange:(UITextRange *)selectedTextRange
{
    FuTextRange *textRange = (FuTextRange *)selectedTextRange;
    _responderView.text.selectedRange = textRange.range;
}

- (UITextRange *)markedTextRange
{
    if (_responderView.text.markedRange.location == NSNotFound) return nil;

    return [FuTextRange rangeWithNSRange:_responderView.text.markedRange];
}


// Describes how the marked text should be drawn.
// selectedRange is a range within the markedText
// 中文输入时，采用标记文本，会走这里。
// 英文输入时，不采用标记文本，则不会走这里，而走insertText:
- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)selectedRange
{
//    if (markedText.length == 0 && NSMaxRange(selectedRange) == 0) {
//        return;
//    }
    
    if ([@"__NSCFConstantString" isEqualToString:NSStringFromClass([markedText class])])
    {
//        _responderView.text.markedRange = NSMakeRange(NSNotFound, 0);
//        return;
    }
    
    if (NSMaxRange(_responderView.text.selectedRange) > self.editingAttributedText.length) {
        _responderView.text.selectedRange = NSMakeRange(self.editingAttributedText.length, 0);
    }
    NSRange tempSelectedRange = _responderView.text.selectedRange;
    NSRange markedTextRange = _responderView.text.markedRange;
    
    NSRange replaceRange;
    
    if (markedTextRange.location != NSNotFound) {
        if (!markedText) {
            markedText = @"";
        }
        
        replaceRange = markedTextRange;
        
        markedTextRange.length = markedText.length;
    } else if (tempSelectedRange.length > 0) {
        replaceRange = tempSelectedRange;
        
        markedTextRange.location = tempSelectedRange.location;
        markedTextRange.length = markedText.length;
    } else if (tempSelectedRange.location == NSNotFound)
    {
        replaceRange = NSMakeRange(0, 0);
        markedTextRange.location = 0;
        markedTextRange.length = markedText.length;
    } else {
        replaceRange = tempSelectedRange;
        
        markedTextRange.location = tempSelectedRange.location;
        markedTextRange.length = markedText.length;
    }
    
    NSMutableAttributedString *editingAttributedText = self.editingAttributedText;
    [self replaceCharactersInRange:replaceRange withString:markedText forAttributedString:editingAttributedText];
    
    tempSelectedRange = NSMakeRange(markedTextRange.location + selectedRange.location, selectedRange.length);

    _responderView.text.markedRange   = markedTextRange;
    _responderView.text.selectedRange = tempSelectedRange;
    
    [self addAttributesWithText:editingAttributedText];
}

//- (void)setMarkedTextStyle:(NSDictionary *)markedTextStyle
//{
//}
//
//- (NSDictionary *)markedTextStyle
//{
//    return @{UITextInputTextBackgroundColorKey: [UIColor blueColor]};
//}

// 标记使用完成
- (void)unmarkText
{
    [self.inputDelegate selectionWillChange:self];
    
    NSRange markedTextRange = _responderView.text.markedRange;
    if (markedTextRange.location == NSNotFound) return;
    
    markedTextRange.location = NSNotFound;
    markedTextRange.length   = 0;
    _responderView.text.markedRange = markedTextRange;
}

- (id<UITextInputTokenizer>)tokenizer
{
    if (!_tokenizer) {
        _tokenizer = [[UITextInputStringTokenizer alloc] initWithTextInput:self];
    }
    return _tokenizer;
}

- (UITextPosition *)beginningOfDocument
{
    FuTextPosition *position = [FuTextPosition positionWithIndex:0];
    return position;
}

- (UITextPosition *)endOfDocument
{
    FuTextPosition *position = [FuTextPosition positionWithIndex:_responderView.text.attributedString.string.length];
    return position;
}

///* Methods for creating ranges and positions. */
- (UITextRange *)textRangeFromPosition:(UITextPosition *)fromPosition toPosition:(UITextPosition *)toPosition
{
    FuTextPosition *from = (FuTextPosition *)fromPosition;
    FuTextPosition *to = (FuTextPosition *)toPosition;
    if (to.index < from.index) {
        FuTextPosition *temp = from;
        from = to;
        to = temp;
    }
    
    NSUInteger location = MIN(from.index, to.index);
    NSUInteger length = ABS(to.index - from.index);
    
    return [FuTextRange rangeWithNSRange:NSMakeRange(location, length)];
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position offset:(NSInteger)offset
{
    FuTextPosition *pos = (FuTextPosition *)position;
    NSInteger end = pos.index + offset;
    if (end > _responderView.text.attributedString.string.length || end < 0) {
        return nil;
    }
    
    return [FuTextPosition positionWithIndex:end];
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset
{
    FuTextPosition *pos = (FuTextPosition *)position;
    NSInteger newPos = pos.index;
    
    switch (direction) {
        case UITextLayoutDirectionRight:
            newPos += offset;
            break;
        case UITextLayoutDirectionLeft:
            newPos -= offset;
            break;
        case UITextLayoutDirectionUp:
        case UITextLayoutDirectionDown:
            break;
    }
    
    if (newPos < 0) {
        newPos = 0;
    }
    
    if (newPos > _responderView.text.attributedString.string.length) {
        newPos = _responderView.text.attributedString.string.length;
    }
    
    return [FuTextPosition positionWithIndex:newPos];
}

/* Simple evaluation of positions */
- (NSComparisonResult)comparePosition:(UITextPosition *)position toPosition:(UITextPosition *)other
{
    FuTextPosition *pos = (FuTextPosition *)position;
    FuTextPosition *o   = (FuTextPosition *)other;
    
    if (pos.index == o.index) {
        return NSOrderedSame;
    } if (pos.index < o.index) {
        return NSOrderedAscending;
    } else {
        return NSOrderedDescending;
    }
}

- (NSInteger)offsetFromPosition:(UITextPosition *)from toPosition:(UITextPosition *)toPosition
{
    FuTextPosition *f = (FuTextPosition *)from;
    FuTextPosition *t = (FuTextPosition *)toPosition;
    return t.index - f.index;
}

/* Layout questions. */
- (UITextPosition *)positionWithinRange:(UITextRange *)range farthestInDirection:(UITextLayoutDirection)direction
{
    FuTextRange *r = (FuTextRange *)range;
    NSInteger pos = 0;//r.range.location;
    
    switch (direction) {
        case UITextLayoutDirectionUp:
        case UITextLayoutDirectionLeft:
            pos = r.range.location;
            break;
        case UITextLayoutDirectionRight:
        case UITextLayoutDirectionDown:
            pos = r.range.location + r.range.length;
            break;
    }
    
    return [FuTextPosition positionWithIndex:pos];
}

- (UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction
{
    FuTextPosition *pos = (FuTextPosition *)position;
    NSRange result ;//=  NSMakeRange(pos.index, 1);
    
    switch (direction) {
        case UITextLayoutDirectionUp:
        case UITextLayoutDirectionLeft:
            result = NSMakeRange(pos.index - 1, 1);
            break;
        case UITextLayoutDirectionRight:
        case UITextLayoutDirectionDown:
            result = NSMakeRange(pos.index, 1);
            break;
    }
    
    return [FuTextRange rangeWithNSRange:result];
}

/* Writing direction */
- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction
{
    return UITextWritingDirectionLeftToRight;
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(UITextRange *)range
{
    // Not supported.
}


/* Geometry used to provide, for example, a correction rect. */
- (CGRect)firstRectForRange:(UITextRange *)range
{
    return CGRectZero;
//    FuTextRange *r = (FuTextRange *)range;
//    CGRect rect = [_responderView rectOfStringWithRange:r.range];
//    return rect;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    return CGRectZero;
}

- (NSArray *)selectionRectsForRange:(UITextRange *)range       // Returns an array of UITextSelectionRects
{
    return nil;
}


/* Hit testing. */
- (UITextPosition *)closestPositionToPoint:(CGPoint)point;
{
    CFIndex index = [_responderView getLineLocationWithPoint:point];

    if (index == kCFNotFound) {
        return nil;
    }
    return [FuTextPosition positionWithIndex:index];
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange *)range
{
    CFIndex index = [_responderView getLineLocationWithPoint:point];
    
    if (index == kCFNotFound) {
        return nil;
    }
    
    FuTextRange *r = (FuTextRange *)range;
    if (index >= r.range.location && index <= r.range.location + r.range.length) {
        return [FuTextPosition positionWithIndex:index];
    }
    
    return nil;
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point
{
    CFIndex index = [_responderView getLineLocationWithPoint:point];
    
    if (index == kCFNotFound) {
        return nil;
    }
    
    CFIndex length = 1;
    
    if (index < 0) {
        index = 0;
    }
    if (index > _responderView.text.attributedString.string.length) {
        index = _responderView.text.attributedString.string.length;
        length = 0;
    }
    
    return [FuTextRange rangeWithNSRange:NSMakeRange(index, length)];
}

- (BOOL)shouldChangeTextInRange:(UITextRange *)range replacementText:(NSString *)text
{
    BOOL shouldChangeTextInRange = YES;
    //    FuTextRange *r = (FuTextRange *)range;
    //    if ([self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
    //        shouldChangeTextInRange = [self.delegate textView:self shouldChangeTextInRange:r.range replacementText:text];
    //    }
    
    return shouldChangeTextInRange;
}

- (void)insertDictationResult:(NSArray *)dictationResult
{
}

/* These are optional methods for clients that wish to know when there are pending dictation results. */
- (void)dictationRecordingDidEnd
{
}

- (void)dictationRecognitionFailed
{
    [super resignFirstResponder];
    [super becomeFirstResponder];
}

//- (id)insertDictationResultPlaceholder
//{
//    return [UIImage imageNamed:@"kb-drag-dot"];
//}
//- (CGRect)frameForDictationResultPlaceholder:(id)placeholder
//{
//    return CGRectMake(0.0, 0.0, 15.0, 17.0);
//}
///* willInsertResult will be NO if the recognition failed. */
//- (void)removeDictationResultPlaceholder:(id)placeholder willInsertResult:(BOOL)willInsertResult
//{
//}

#pragma mark - 重写UIKeyInput接口的方法

- (BOOL)hasText
{
    return _responderView.text.attributedString.string.length > 0;
}

- (void)insertText:(NSString *)text
{
    if ([_delegate respondsToSelector:@selector(textInput:shouldChangeTextInRange:replacementText:)])
    {
        NSRange inrange = _responderView.text.selectedRange;
        if (inrange.location == NSNotFound)
        {
            inrange.location = text.length;
        } else
        {
            inrange.location += text.length;
        }
        BOOL value = [_delegate textInput:self shouldChangeTextInRange:inrange replacementText:text];
        
        if (!value) return;
    }
    
    if ([@"__NSCFConstantString" isEqualToString:NSStringFromClass([text class])] && [text isEqualToString:@"          "])// 录音为空时，产生是10个空格
    {
        _responderView.text.markedRange = NSMakeRange(NSNotFound, 0);
        return;
    }
    
    if (!text.length) {
        text = @"";
        [self unmarkText];
    }
    
    BOOL isN = NO;
    if ([text isEqualToString:@"\n"] && (_responderView.text.selectedRange.location == NSNotFound || _responderView.text.selectedRange.location == _responderView.text.attributedString.string.length))
    { // 光标在最后，解决换行问题
        text = @"\n ";
        isN = YES;
    }

    if ([text isEqualToString:@" "] && [_responderView isCaretFrameOverSuper]) {
        _isSpace = YES;
        return;
    }
    
    if (![text isEqualToString:@" "]) {  // 解决输入空格 问题
        if (_isSpace && ![text isEqualToString:@"\n"]) {
            text = [NSString stringWithFormat:@"\n%@", text];
        }
        _isSpace = NO;
    }

    NSRange selectedNSRange = _responderView.text.selectedRange;
    NSRange markedTextNSRange = _responderView.text.markedRange;
    
    NSRange replaceRange;
    
    if (markedTextNSRange.location != NSNotFound)
    {
        replaceRange = markedTextNSRange;
        selectedNSRange.location = markedTextNSRange.location + text.length;
        selectedNSRange.length = 0;
        markedTextNSRange = NSMakeRange(NSNotFound, 0);
    } else if (selectedNSRange.length > 0)
    {
        replaceRange = selectedNSRange;
        selectedNSRange.length = 0;
        selectedNSRange.location += text.length;
    } else if (selectedNSRange.location == NSNotFound)
    {
        replaceRange = NSMakeRange(0, 0);
        selectedNSRange.location = text.length;
    } else
    {
        replaceRange = selectedNSRange;
        selectedNSRange.location += text.length;
    }

    NSMutableAttributedString *editingAttributedText = self.editingAttributedText;
    [self replaceCharactersInRange:replaceRange withString:text forAttributedString:editingAttributedText];
    
    _responderView.text.markedRange = markedTextNSRange;
    
    if (isN && selectedNSRange.location != NSNotFound && selectedNSRange.location > 0) {
        isN = NO;
        selectedNSRange = NSMakeRange((selectedNSRange.location - 1), selectedNSRange.length);
    }
    _responderView.text.selectedRange = selectedNSRange;

    [self addAttributesWithText:editingAttributedText];
    
    [self clearCurrentTriggerString];
    
    NSArray *triggerArray = [_triggerString componentsSeparatedByString:@","];
    if ([triggerArray containsObject:text]) {
        [self deleteBackward];
        if ([_delegate respondsToSelector:@selector(textInputOfTriggerString:triggerString:)]) {
            _currentTriggerString = text;
            [_delegate textInputOfTriggerString:self triggerString:text];
        }
    }
}

- (void)deleteBackward
{
    [self deleteBackwardWithRange:_responderView.text.selectedRange];
//    if (_responderView.text.string.length > 0)
//    {
//        NSRange selectedNSRange = _responderView.text.selectedRange;
////        NSRange markedTextNSRange = _responderView.text.markedRange;
//        
//        NSMutableAttributedString *editingAttributedText = self.editingAttributedText;
//        NSRange deleteRange = NSMakeRange(0, 0);
//
//
//        if (selectedNSRange.length > 0)
//        {
//            deleteRange = selectedNSRange;
//            selectedNSRange.length = 0;
//        } else if (selectedNSRange.location != NSNotFound && selectedNSRange.location > 0)
//        {
//            deleteRange = NSMakeRange(selectedNSRange.location - 1, 1);
//            selectedNSRange.location--;
//            selectedNSRange.length = 0;
//        }
//        
//        [editingAttributedText deleteCharactersInRange:deleteRange];
//
//        _responderView.text.markedRange = selectedNSRange;
//        _responderView.text.selectedRange = selectedNSRange;
//        
//        [self addAttributesWithText:editingAttributedText];
//        
//        
//        NSString *str = nil;
//        if (editingAttributedText.length && selectedNSRange.location != NSNotFound && editingAttributedText.length > selectedNSRange.location)
//        {
//            if (selectedNSRange.location > 2)
//            {
//                str = [editingAttributedText.string substringWithRange:NSMakeRange(selectedNSRange.location - 2, 2)];
//                if ([str isEqualToString:@"\n "])
//                {
//                    [self deleteBackward1];
//                }
//            } else
//            {
//                str = [editingAttributedText.string substringWithRange:NSMakeRange(selectedNSRange.location, 1)];
//                if ([str isEqualToString:@" "]) {
//                    _responderView.text.selectedRange = NSMakeRange(selectedNSRange.location + 1, selectedNSRange.length);
////                    [self deleteBackward1];
//                } else if ([str isEqualToString:@"\n"]) {
//                    _responderView.text.selectedRange = NSMakeRange(selectedNSRange.location + 1, selectedNSRange.length);
//                    [self deleteBackward1];
//                }
//            }
//        }
//        
//    } else
//    {
//        _responderView.text.markedRange = NSMakeRange(NSNotFound, 0);
//        _responderView.text.selectedRange = NSMakeRange(NSNotFound, 0);
//        
//        [self addAttributesWithText:nil];
//    }
}

- (void)deleteBackwardWithRange:(NSRange)range
{
    if (_responderView.text.attributedString.string.length > 0)
    {
        NSRange selectedNSRange = range;

        NSMutableAttributedString *editingAttributedText = self.editingAttributedText;
        NSRange deleteRange = NSMakeRange(0, 0);
 
        if (selectedNSRange.length > 0)
        {
            deleteRange = selectedNSRange;
            selectedNSRange.length = 0;
        } else if (selectedNSRange.location != NSNotFound && selectedNSRange.location > 0)
        {
            deleteRange = NSMakeRange(selectedNSRange.location - 1, 1);
            selectedNSRange.location--;
            selectedNSRange.length = 0;
        }

        [editingAttributedText deleteCharactersInRange:deleteRange];
        
        _responderView.text.markedRange = selectedNSRange;
        _responderView.text.selectedRange = selectedNSRange;
        
        [self addAttributesWithText:editingAttributedText];
        
        
        NSString *str = nil;
        if (editingAttributedText.length && selectedNSRange.location != NSNotFound && editingAttributedText.length > selectedNSRange.location)
        {
            if (selectedNSRange.location > 2)
            {
                str = [editingAttributedText.string substringWithRange:NSMakeRange(selectedNSRange.location - 2, 2)];
                if ([str isEqualToString:@"\n "])
                {
                    [self deleteBackward1];
                }
            } else
            {
                str = [editingAttributedText.string substringWithRange:NSMakeRange(selectedNSRange.location, 1)];
                if ([str isEqualToString:@" "]) {
                    _responderView.text.selectedRange = NSMakeRange(selectedNSRange.location + 1, selectedNSRange.length);
                } else if ([str isEqualToString:@"\n"]) {
                    _responderView.text.selectedRange = NSMakeRange(selectedNSRange.location + 1, selectedNSRange.length);
                    [self deleteBackward1];
                }
            }
        }
        
    } else
    {
        _responderView.text.markedRange = NSMakeRange(NSNotFound, 0);
        _responderView.text.selectedRange = NSMakeRange(NSNotFound, 0);
        
        [self addAttributesWithText:nil];
    }
}

- (void)deleteBackward1
{
    if (_responderView.text.attributedString.string.length > 0)
    {
        NSRange selectedNSRange = _responderView.text.selectedRange;
        
        NSMutableAttributedString *editingAttributedText = self.editingAttributedText;
        NSRange deleteRange = NSMakeRange(0, 0);
        
        if (selectedNSRange.length > 0)
        {
            deleteRange = selectedNSRange;
            selectedNSRange.length = 0;
        } else if (selectedNSRange.location != NSNotFound && selectedNSRange.location > 0)
        {
            deleteRange = NSMakeRange(selectedNSRange.location - 1, 1);
            selectedNSRange.location--;
            selectedNSRange.length = 0;
        }

        [editingAttributedText deleteCharactersInRange:deleteRange];
        
        _responderView.text.markedRange = selectedNSRange;
        _responderView.text.selectedRange = selectedNSRange;
        
        [self addAttributesWithText:editingAttributedText];
        
    } else
    {
        _responderView.text.markedRange = NSMakeRange(NSNotFound, 0);
        _responderView.text.selectedRange = NSMakeRange(NSNotFound, 0);
        
        [self addAttributesWithText:nil];
    }
}

#pragma mark - 其他方法

- (void)insertAttributedText:(NSAttributedString *)attributedText
{
    NSRange selectedNSRange = _responderView.text.selectedRange;
    NSRange markedTextNSRange = _responderView.text.markedRange;
    
    NSMutableAttributedString *editingAttributedText = self.editingAttributedText;
    NSRange replaceRange;
    
    if (markedTextNSRange.location != NSNotFound) {
        replaceRange = markedTextNSRange;
        
        selectedNSRange.location = markedTextNSRange.location + attributedText.length;
        selectedNSRange.length = 0;
        
        markedTextNSRange = NSMakeRange(NSNotFound, 0);
    } else if (selectedNSRange.length > 0)
    {
        replaceRange = selectedNSRange;
        
        selectedNSRange.length = 0;
        selectedNSRange.location += attributedText.length;
    } else if (selectedNSRange.location == NSNotFound)
    {
        replaceRange = NSMakeRange(0, 0);
        selectedNSRange.location = attributedText.length;
    } else {
        replaceRange = selectedNSRange;
        selectedNSRange.location += attributedText.length;
    }
    
    [editingAttributedText replaceCharactersInRange:replaceRange withAttributedString:attributedText];
    
    
    _responderView.text.markedRange = markedTextNSRange;
    _responderView.text.selectedRange = selectedNSRange;
    
    [self addAttributesWithText:editingAttributedText];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)aString forAttributedString:(NSMutableAttributedString *)attributdString
{ // range 为新输入文字的范围 aString 为新输入的文字 attributdString 为旧的文字
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:aString];
    if (attributdString.length >= (range.location + range.length))
            [attributdString replaceCharactersInRange:range withAttributedString:string];
}


- (void)addAttributesWithText:(NSMutableAttributedString *)attributtedString
{
    if (attributtedString.length && _responderView.text.attributedString.length && [_responderView.text.attributedString.string  isEqualToString:attributtedString.string])
    {
        [_responderView.text clearCacheString];
    }
    _responderView.text.attributedString = attributtedString;
    
    if ([_delegate respondsToSelector:@selector(textInputOfAttributedText:attributedText:)]) {
        [_delegate textInputOfAttributedText:self attributedText:attributtedString];
    }
}

@end


/**
 内部类
 */

@implementation FuTextRange

+ (FuTextRange *)rangeWithNSRange:(NSRange)theRange
{
    if (theRange.location == NSNotFound) {
        return nil;
    }
    
    FuTextRange *range = [[FuTextRange alloc] init];
    range.range = theRange;
    return range;
}

- (UITextPosition *)start
{
    return [FuTextPosition positionWithIndex:self.range.location];
}

- (UITextPosition *)end
{
	return [FuTextPosition positionWithIndex:self.range.location + self.range.length];
}

- (BOOL)isEmpty
{
    return self.range.length == 0;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@)", [super description], NSStringFromRange(self.range)];
}

@end



@implementation FuTextPosition

+ (FuTextPosition *)positionWithIndex:(NSUInteger)index
{
    FuTextPosition *position = [[FuTextPosition alloc] init];
    position.index = index;
    return position;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@)", [super description], @(self.index).stringValue];
}

@end

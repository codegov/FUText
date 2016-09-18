         //
//  FuTextView.m
//  Test
//
//  Created by syq on 14-5-28.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuTextView.h"
#import "FuDrawTextView.h"

static NSString * const OBJECT_REPLACEMENT_CHARACTER = @"\uFFFC";//Unicode编码 为对象占位符

@interface FuTextView ()<UITextViewDelegate, FuTextInputDelegate, FuDrawViewDelegate>
{
    CGPoint                       _mouseLocation;
    CGRect                        _initFrame;    // 初始化的frame
    
    BOOL _inputing;
    
    CTLineRef _updateLine;
    NSRange   _updateStringRange;
}

@property (nonatomic, strong) FuTextInput         *textInput;            // 数据来源

@property (nonatomic, strong) NSString            *selectedText;         // 选中的文本

@end

@implementation FuTextView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _text        = [[FuTextModel alloc] init];
        _text.viewLineSpacing = 10;
        _preText     = [[FuTextModel alloc] init];
        _sufText     = [[FuTextModel alloc] init];
        _placeHolder = [[FuTextModel alloc] init];
        _placeHolder.textColor.color = [UIColor lightGrayColor];
        _inputing = YES;
        
        self.menuType    = FuMenuTypeWithCopy | FuMenuTypeWithCut | FuMenuTypeWithPaste | FuMenuTypeWithSelect;
        _initFrame       = frame;
        _edgeInsets      = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
        
        [self createContentView];
        [self createTextInput];
        self.triggerString = @"@";
        
        _toolManager = [[FuManager alloc] initWithTextView:self];
        
        [_contentView.tableView addSubview:_toolManager.caretView];
        [_contentView.tableView addSubview:_toolManager.startGrabber];
        [_contentView.tableView addSubview:_toolManager.endGrabber];
        
        UIPanGestureRecognizer *startGrabberGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(grabberMoved:)];
        [_toolManager.startGrabber addGestureRecognizer:startGrabberGestureRecognizer];
        
        UIPanGestureRecognizer *endGrabberGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(grabberMoved:)];
        [_toolManager.endGrabber addGestureRecognizer:endGrabberGestureRecognizer];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveGWWImageViewImageDidChangeNotification:) name:@"GWWImageViewImageDidChangeNotification" object:nil];
    }
    return self;
}

- (void)receiveGWWImageViewImageDidChangeNotification:(NSNotification *)notification
{
    if (!(_text.textType & FuText_view)) return;
    
    NSString *value      = [notification.userInfo objectForKey:@"range"];
    NSString *path       = [notification.userInfo objectForKey:@"path"];
    NSString *type       = [notification.userInfo objectForKey:@"type"];
    NSString *sizeString = [notification.userInfo objectForKey:@"changeSize"];
    NSRange range = NSRangeFromString(value);
    CGSize size   = CGSizeFromString(sizeString);
    if ([type isEqualToString:@"delete"])
    {
        [self deleteBackwardWithRange:range];
    } else if ([type isEqualToString:@"download"])
    {
        NSAttributedString *string = [FuTextModel getReplacementStringWithName:path type:FuText_view size:size runWidth:_text.custromViewWidth viewLineSpacing:_text.viewLineSpacing];
        NSMutableAttributedString *aString = [[NSMutableAttributedString alloc] initWithAttributedString:_contentView.attributedText];
        [aString replaceCharactersInRange:range withAttributedString:string];
        _text.attributedString = aString;
        _contentView.attributedText = aString;
        _inputing = YES;
        [self updateHighlightGrabber];
    }
}

- (void)setScrollTop:(BOOL)scrollTop
{
    self.contentView.tableView.scrollsToTop = scrollTop;
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
{
    _edgeInsets = edgeInsets;
    
    _contentView.edgeInsets = edgeInsets;
    
    float tvalue = 10.0;
    float bvalue = 10.0;
//    if (edgeInsets.top < tvalue) {
//        tvalue = edgeInsets.top;
//    }
//    if (edgeInsets.bottom < bvalue) {
//        bvalue = edgeInsets.bottom;
//    }
    _toolManager.startGrabber.dotView.frame = CGRectMake(0.0, 0.0, tvalue, tvalue);
    _toolManager.endGrabber.dotView.frame   = CGRectMake(0.0, 0.0, bvalue, bvalue);
}

- (void)setTextHeaderView:(UIView *)textHeaderView
{
    _textHeaderView = textHeaderView;
    _contentView.textHeaderView = textHeaderView;
}

- (void)setTextFooterView:(UIView *)textFooterView
{
    _textFooterView = textFooterView;
    _contentView.textFooterView = textFooterView;
}

- (void)setNumberOfLines:(NSInteger)numberOfLines
{
//    if (_numberOfLines == numberOfLines) {
//        _inputing = NO;
//    } else {
        _inputing = YES;
        _numberOfLines = numberOfLines;
        _contentView.numberOfLines = numberOfLines;
        
        if (numberOfLines < 0) {
//            self.text.selectedRange = NSMakeRange(self.text.string.length, 0);
            [self updateHighlightGrabber];
        }
//    }
}

- (void)setTriggerString:(NSString *)triggerString
{
    _triggerString = triggerString;
    _textInput.triggerString = triggerString;
}

- (void)insertString:(NSString *)string;
{
    [_textInput insertText:string];
}

- (void)scrollToCaretPosition
{
    CGFloat maxCaretY = CGRectGetMaxY(_toolManager.caretView.frame);
    CGFloat minCaretY = CGRectGetMinY(_toolManager.caretView.frame);
    CGFloat offsetY   = _contentView.tableView.contentOffset.y;
    CGFloat tableHei  = _contentView.tableView.frame.size.height;
    
    if (minCaretY < offsetY)
    {
        CGPoint p = _contentView.tableView.contentOffset;
        p.y = minCaretY - _edgeInsets.top;
        _contentView.tableView.contentOffset = p;
    }
    
    CGFloat v = 2 * _edgeInsets.bottom;
    v = _textFooterView.frame.size.height > v ? v : _textFooterView.frame.size.height;
    if (maxCaretY > (offsetY + tableHei) || (maxCaretY + v + _edgeInsets.bottom) > (offsetY + tableHei))
    {
        CGPoint p = _contentView.tableView.contentOffset;
        p.y = maxCaretY - tableHei + _edgeInsets.bottom + v;
        _contentView.tableView.contentOffset = p;
    }

    float height = _toolManager.caretView.frame.origin.y + _toolManager.caretView.frame.size.height + self.edgeInsets.bottom + self.textFooterView.frame.size.height;
//    if (_contentView.tableView.contentSize.height < height) {
//        _contentView.tableView.contentSize = CGSizeMake(_contentView.tableView.contentSize.width, height);
//    }    
    float nHeight = _contentView.tableView.contentOffset.y < 0 ? (height - _contentView.tableView.contentOffset.y) : height;
    float offHeight = nHeight - _contentView.tableView.frame.size.height;
//
//    float height2 = self.edgeInsets.bottom + self.textFooterView.frame.size.height + _toolManager.caretView.bounds.size.height;
//    float nHeight2 = _contentView.tableView.contentOffset.y < 0 ? (height2 - _contentView.tableView.contentOffset.y) : height2;
//    float offHeight2 = nHeight2 - _contentView.tableView.bounds.size.height;
//    if (offHeight2 > 0) {
//        if ((_toolManager.caretView.frame.origin.y - _text.lineSpacing) < _contentView.tableView.contentOffset.y)
//        {
//            [_contentView.tableView scrollRectToVisible:_toolManager.caretView.frame animated:NO];
//            return;
//        }
//        CGRect frame = _toolManager.caretView.frame;
//        frame.origin.y += offHeight2;
//        CGFloat v = CGRectGetMaxY(frame) - (_contentView.tableView.contentOffset.y + _contentView.tableView.frame.size.height);
//        if (v > 0)
//        {
//            frame.origin.y += v;
//        }
////        frame.size.height += offHeight2;
//        [_contentView.tableView scrollRectToVisible:frame animated:NO];
//    } else if (offHeight > 0)
//    {
//        if ((_toolManager.caretView.frame.origin.y - _text.lineSpacing) < _contentView.tableView.contentOffset.y)
//        {
//            [_contentView.tableView scrollRectToVisible:_toolManager.caretView.frame animated:NO];
//            return;
//        }
//        CGFloat ed = 2 * _edgeInsets.bottom;
//        CGFloat v = self.textFooterView.frame.size.height > ed ? ed : self.textFooterView.frame.size.height;
//        float y = _toolManager.caretView.frame.origin.y + self.edgeInsets.bottom + v;// + self.textFooterView.frame.size.height;
//        CGRect frame = CGRectMake(_toolManager.caretView.frame.origin.x, y, _toolManager.caretView.frame.size.width, _toolManager.caretView.frame.size.height);
//        [_contentView.tableView scrollRectToVisible:frame animated:NO];
//    } else {
//        [_contentView.tableView scrollRectToVisible:_toolManager.caretView.frame animated:NO];
//    }
    if (_needManageScroll)
    {
        float mHeight = _contentView.tableView.contentOffset.y < 0 ? (_contentView.tableView.contentSize.height - _contentView.tableView.contentOffset.y) : _contentView.tableView.contentSize.height;
        
        BOOL isCanScroll = (mHeight - _contentView.tableView.frame.size.height) >= 1;
        
        if (offHeight > 0 || isCanScroll)
        {
            _contentView.tableView.scrollEnabled = YES;
        } else {
            _contentView.tableView.scrollEnabled = NO;
        }
    }
}

- (void)scrollOfHeight:(float)height
{
    _contentView.tableView.contentOffset = CGPointMake(_contentView.tableView.contentOffset.x, _contentView.tableView.contentOffset.y + height);
}

- (void)scrollToTop
{
    _contentView.tableView.contentOffset = CGPointMake(_contentView.tableView.contentOffset.x, 0);
}

#pragma mark - 插入当前触发器字符

- (void)insertTriggerString
{
    if (self.textInput.currentTriggerString && [self.textInput.currentTriggerString length] > 0)
    {
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:self.textInput.currentTriggerString];
        [_textInput insertAttributedText:string];
        [self.textInput clearCurrentTriggerString];
    }
}

#pragma mark - 插入@

- (void)insertAtWithName:(NSString *)name uid:(NSString *)uid
{
    if (!name.length || !uid.length) return;
    
    [_textInput insertText:@" "];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:name];
    [string addAttribute:@"type" value:@(FuText_at) range:NSMakeRange(0, string.length)];
    [string addAttribute:@"param" value:@{@"name": name, @"uid": uid} range:NSMakeRange(0, string.length)];
    [_textInput insertAttributedText:string];
    
    [_textInput insertText:@" "];
}

#pragma mark - 插入话题

- (void)insertTopicWithName:(NSString *)name topicId:(NSString *)topicId
{
    if (!name.length || !topicId.length) return;
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:name];
    [string addAttribute:@"type" value:@(FuText_topic) range:NSMakeRange(0, string.length)];
    [string addAttribute:@"param" value:@{@"name": name, @"topicId": topicId} range:NSMakeRange(0, string.length)];
    [_textInput insertAttributedText:string];
    
    [_textInput insertText:@" "];
}

#pragma mark - 插入表情

- (void)insertFaceWithName:(NSString *)name size:(CGSize)size
{
    if (!name.length) return;
    [_textInput insertAttributedText:[FuTextModel getReplacementStringWithName:name type:FuText_img size:size runWidth:size.width]];
}

#pragma mark - 插入图片

- (void)insertImageWithName:(NSString *)name size:(CGSize)size
{
    if (!name.length) return;
    [_textInput insertAttributedText:[FuTextModel getReplacementStringWithName:name type:FuText_view size:size runWidth:_text.custromViewWidth viewLineSpacing:_text.viewLineSpacing]];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)grabberMoved:(UIPanGestureRecognizer *)gestureRecognizer
{
    [_textInput.inputDelegate selectionWillChange:_textInput];
    
    FuSelectionGrabber *startGrabber = _toolManager.startGrabber;
    FuSelectionGrabber *endGrabber = _toolManager.endGrabber;
    
    _mouseLocation = [gestureRecognizer locationInView:_contentView.tableView];
    
    CFIndex lineNum = [self getLineNumWithPoint:_mouseLocation];
    CTLineRef line = [self getLineWithlineNum:lineNum];
    
    CFIndex preLen = self.preText.attributedString.string.length;
    CFIndex index = CTLineGetStringIndexForPosition(line, CGPointMake(_mouseLocation.x - _edgeInsets.left, _mouseLocation.y)) - preLen;
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan ||
        gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        if (startGrabber == gestureRecognizer.view)
        {
            startGrabber.dragging = YES;
            CFIndex length = NSMaxRange(self.text.selectedRange) - index;
            if (length > 0 && index >= 0) { // 前置光标不超过后置光标
                self.text.selectedRange = NSMakeRange(index, length);
            }
            [_toolManager moveSelectedMagnifierToPoint:startGrabber.center offY:startGrabber.dotView.frame.size.height]; //通过前置光标 移动选中放大镜
        } else
        {
            CFIndex location = self.text.selectedRange.location;
            CFIndex length = index - location;
            if (length > 0) {
                self.text.selectedRange = NSMakeRange(location, length);
            }
            [_toolManager moveSelectedMagnifierToPoint:endGrabber.center offY:0];    //通过后置光标 移动选中放大镜
        }
        
        [self scrollToPoint:_mouseLocation];
        
        float bOff2 = _toolManager.startGrabber.frame.origin.y - _contentView.tableView.contentOffset.y;
        float eOff2 = _toolManager.endGrabber.frame.origin.y + _toolManager.endGrabber.frame.size.height - _contentView.tableView.contentOffset.y;
        
        // 拖动控件不在可视范围，则不需要显示菜单
        if (bOff2 >= self.frame.size.height || eOff2 < 1) {
            [_toolManager hideSelectedMagnifier];
        }
        
        [self hideEditingMenu];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded ||
               gestureRecognizer.state == UIGestureRecognizerStateCancelled ||
               gestureRecognizer.state == UIGestureRecognizerStateFailed)
    {
        CGPoint point = CGPointZero;
        if (gestureRecognizer.view == startGrabber) {
            startGrabber.dragging = NO;
            point = CGPointMake(startGrabber.center.x, startGrabber.center.y - startGrabber.dotView.frame.size.height);
        } else {
            endGrabber.dragging = NO;
            point = CGPointMake(endGrabber.center.x, endGrabber.center.y - endGrabber.dotView.frame.size.height);
        }
        
        [_toolManager hideSelectedMagnifier];
        if (self.text.selectedRange.length)
        {
            _mouseLocation = point;
            [self showEditingMenu];
        } else {
            [self hideEditingMenu];
        }
    }
    
    [_textInput.inputDelegate selectionDidChange:_textInput];
    
    [self setNeedsLayout];
}

#pragma mark - 高亮视图变化

- (void)updateHighlightGrabber
{
    CFIndex location = _text.selectedRange.location;
    if (location == NSNotFound) {
        location = 0;
    }
    NSInteger preLen = _preText.attributedString.string.length;
    location += preLen;
    
    if (_text.selectedRange.length) // 有选中文本
    {
        float x = 0;
        float y = 0;
        float width = 20.0;
        
        CFIndex row    = [_toolManager binarySearchForLineNum:_contentView.lines count:_contentView.lineCount location:location type:1];
        
        float lineHeight = [[_contentView.lineHeightDictionary objectForKey:@(row).stringValue] floatValue];
        float oldHeight  = [[_contentView.lineHeightDictionary objectForKey:@(row - 1).stringValue] floatValue];
        
        CTLineRef line = CFArrayGetValueAtIndex(_contentView.lines, row);
        x = CTLineGetOffsetForStringIndex(line, location, NULL);
        y = oldHeight + _edgeInsets.top + _textHeaderView.frame.size.height - _toolManager.startGrabber.dotView.frame.size.height;
        _toolManager.startGrabber.frame = CGRectMake(x - width/2.0 + _edgeInsets.left, y, width, (lineHeight - oldHeight - _text.lineSpacing) + _toolManager.startGrabber.dotView.frame.size.height);
        
        CFIndex mLocation = NSMaxRange(_text.selectedRange) + preLen;
        CFIndex mRow      = [_toolManager binarySearchForLineNum:_contentView.lines count:_contentView.lineCount location:mLocation type:2];
        lineHeight = [[_contentView.lineHeightDictionary objectForKey:@(mRow).stringValue] floatValue];
        oldHeight  = [[_contentView.lineHeightDictionary objectForKey:@(mRow - 1).stringValue] floatValue];
        CTLineRef mLine   = CFArrayGetValueAtIndex(_contentView.lines, mRow);
        x = CTLineGetOffsetForStringIndex(mLine, mLocation, NULL);
        y = oldHeight + _edgeInsets.top + _textHeaderView.frame.size.height;
        _toolManager.endGrabber.frame = CGRectMake(x - width/2.0 + _edgeInsets.left, y, width, (lineHeight - oldHeight - _text.lineSpacing) + _toolManager.endGrabber.dotView.frame.size.height);
        
        _toolManager.startGrabber.hidden = NO;
        _toolManager.endGrabber.hidden   = NO;
        _toolManager.caretView.hidden    = YES;
        [_toolManager.caretView delayBlink];
    } else
    {
        if (_inputing) // 输入文本时更新光标 目的是：与点击更新光标区分开来，则点击不需要通过下面代码去更新光标位置
        {
            _inputing = NO;
//            if (self.isEditing)
            {
                CFIndex row = [self getLineNumWithLocation:location];
                CTLineRef line = nil;
                if (_contentView.lines) {
                    line = CFArrayGetValueAtIndex(_contentView.lines, row);
                }
                float lineHeight = [[_contentView.lineHeightDictionary objectForKey:@(row).stringValue] floatValue];
                float oldHeight  = [[_contentView.lineHeightDictionary objectForKey:@(row- 1).stringValue] floatValue];
                [_toolManager updateCaretViewWithLocation:location line:line lineHeight:oldHeight caretHeight:(lineHeight - oldHeight)];
                [_textInput.inputDelegate selectionDidChange:_textInput];
            }
        } else
        {
            [self scrollToCaretPosition];
        }
        
        _toolManager.startGrabber.hidden = YES;
        _toolManager.endGrabber.hidden   = YES;
        _toolManager.caretView.hidden    = !self.isEditing;
        [_toolManager.caretView delayBlink];
    }
}

#pragma mark - 获取此点所处于行的位置

- (CFIndex)getLineLocationWithPoint:(CGPoint)point
{
    return [_contentView getLineLocationWithPoint:point];
}

#pragma mark - 通过点得到行号

- (CFIndex)getLineNumWithPoint:(CGPoint)point;
{
    return [_contentView getLineNumWithPoint:point];
}

#pragma mark - 通过范围得到行号

- (CFIndex)getLineNumWithLocation:(CFIndex)location
{
    if (location == NSNotFound) return 0;
    CFIndex row = [_toolManager binarySearchForLineNum:_contentView.lines count:_contentView.lineCount location:location type:[self getTempType]];
    row = row < 0 ? 0 : row;
    return row;
}

- (int)getTempType // 临时添加
{
    /*
     输入文字时，光标一般在行后，但是换行时，光标需在行前。所以通过type来区分
     */
    CFIndex lo = _text.selectedRange.location;
    NSInteger textLen = _text.attributedString.string.length;
    int type = 1;
    if (lo != NSNotFound && lo < textLen && lo > 0)
    {
        CFIndex lastIndex = lo - 1;
        NSString *lastCharacter = [_text.attributedString.string substringWithRange:NSMakeRange(lastIndex, 1)];
        if ([lastCharacter isEqualToString:@"\n"])
        {
            type = 2;
        }
    }
    return type;
}

#pragma mark - 通过行号得到行

- (CTLineRef)getLineWithlineNum:(CFIndex)lineNum
{
    if (lineNum >=0 && lineNum <= _contentView.lineCount) {
        return CFArrayGetValueAtIndex(_contentView.lines, lineNum);
    }
    return nil;
}

#pragma mark - 判断光标是否超出编辑区域 （原因：系统没有处理一直输入空格不会换行，导致的问题）

- (BOOL)isCaretFrameOverSuper
{
    return (_toolManager.caretView.frame.origin.x + _toolManager.caretView.frame.size.width * 2) >= (_contentView.tableView.frame.size.width - _edgeInsets.right);
}

- (CGPoint)drawConvertPoint:(CGPoint)point
{
    return [_contentView.tableView convertPoint:point toView:nil];
}

#pragma mark - 属性

- (void)layoutSubviews
{
    _text.custromViewWidth = self.bounds.size.width - self.edgeInsets.left - self.edgeInsets.right;
    
    NSRange tempMarkedRange = NSMakeRange(NSNotFound, 0);
    NSMutableAttributedString *appAttri = [[NSMutableAttributedString alloc] init];
    NSInteger preLen = self.preText.attributedString.string.length;
    if (preLen)
    {
        [appAttri appendAttributedString:[self.preText getAttrString]];
    }
    
    if (self.placeHolder.attributedString.string.length && !self.text.attributedString.string.length)
    {
        [appAttri appendAttributedString:[self.placeHolder getAttrString]];
    } else
    {
        if (_text.markedRange.length) {
            tempMarkedRange = _text.markedRange;
        } else if (_text.selectedRange.length) {
            tempMarkedRange = _text.selectedRange;
        }
        
        if (self.text.attributedString.string.length)
        {
            [appAttri appendAttributedString:[self.text getAttrString]];
        }
    }
    
    if (tempMarkedRange.length)
    {
        NSInteger len = (tempMarkedRange.location == NSNotFound) ? preLen : (preLen + tempMarkedRange.location);
        tempMarkedRange = NSMakeRange(len, tempMarkedRange.length);
    }

    _contentView.textModel = _text;
    _contentView.font = _text.font;
    _contentView.highlightRange = tempMarkedRange;
    _contentView.attributedText = appAttri;
    
    if ([_delegate respondsToSelector:@selector(textViewScrollHeightDidChange:scrollHeight:)])
    {
        float lineHeight = [[_contentView.lineHeightDictionary objectForKey:@(_contentView.lineCount - 1).stringValue] floatValue];
        float height = lineHeight + _edgeInsets.top + _edgeInsets.bottom + self.textHeaderView.frame.size.height + self.textFooterView.frame.size.height - _text.lineSpacing;
        [_delegate textViewScrollHeightDidChange:self scrollHeight:height];
    }
    
    [self updateHighlightGrabber];

    [super layoutSubviews];
}

- (NSRange)selectedRange
{
    return _text.selectedRange;
}

- (NSString *)selectedText
{
    return [_text.attributedString.string substringWithRange:_text.selectedRange];
}

- (BOOL)becomeFirstResponder
{
    [super becomeFirstResponder];
    BOOL value = [_textInput becomeFirstResponder];
    _toolManager.caretView.hidden = NO;
    return value;
}

- (BOOL)resignFirstResponder
{
    [super resignFirstResponder];
    BOOL value = [_textInput resignFirstResponder];
    _toolManager.caretView.hidden = !self.isEditing;
    return value;
}

- (BOOL)isFirstResponder
{
    return [_textInput isFirstResponder];
}

- (BOOL)isEditing
{
    return _textInput.isEditing;
}

- (void)setCanEditAttachments:(BOOL)canEditAttachments
{
    _textInput.canEditAttachments = canEditAttachments;
}

- (void)setEditable:(BOOL)editable
{
    _textInput.editable = editable;
}

- (BOOL)editable
{
    return _textInput.editable;
}

- (void)setAutocapitalizationType:(UITextAutocapitalizationType)autocapitalizationType
{
    _textInput.autocapitalizationType = autocapitalizationType;
}

- (void)setAutocorrectionType:(UITextAutocorrectionType)autocorrectionType
{
    _textInput.autocorrectionType = autocorrectionType;
}

- (void)setSpellCheckingType:(UITextSpellCheckingType)spellCheckingType
{
    _textInput.spellCheckingType = spellCheckingType;
}

- (void)setKeyboardType:(UIKeyboardType)keyboardType
{
    _textInput.keyboardType = keyboardType;
}

- (void)setKeyboardAppearance:(UIKeyboardAppearance)keyboardAppearance
{
    _textInput.keyboardAppearance = keyboardAppearance;
}

- (void)setReturnKeyType:(UIReturnKeyType)returnKeyType
{
    _textInput.returnKeyType = returnKeyType;
}

- (void)setEnablesReturnKeyAutomatically:(BOOL)enablesReturnKeyAutomatically
{
    _textInput.enablesReturnKeyAutomatically = enablesReturnKeyAutomatically;
}

- (void)setSecureTextEntry:(BOOL)secureTextEntry
{
    _textInput.secureTextEntry = secureTextEntry;
}

- (void)setFrame:(CGRect)frame
{
    super.frame = frame;
    _contentView.frame = CGRectMake(0.0, 0.0, frame.size.width, frame.size.height);
}

#pragma mark - 创建控件

- (void)createTextInput // 监听键盘输入
{
    _textInput                        = [[FuTextInput alloc] initWithTextView:self];
    _textInput.delegate               = self;
    _textInput.autocorrectionType     = UITextAutocorrectionTypeNo;
    _textInput.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _textInput.spellCheckingType      = UITextSpellCheckingTypeDefault;
}

- (void)createContentView          // 绘制对象
{
    _contentView                  = [[FuDrawTextView alloc] initWithFrame:self.bounds];
    _contentView.delegate         = self;
    _contentView.backgroundColor  = [UIColor clearColor];
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_contentView];
}

#pragma mark - 编辑菜单

- (void)showEditingMenu
{
    CGRect rect = _toolManager.caretView.frame; // 默认显示在光标处
    
    if (!_toolManager.startGrabber.hidden && !_toolManager.endGrabber.hidden) // 拖动控件显示时
    {
        float bOff = _toolManager.startGrabber.frame.origin.y - _contentView.tableView.contentOffset.y;
        float eOff = _toolManager.endGrabber.frame.origin.y + _toolManager.endGrabber.frame.size.height - _contentView.tableView.contentOffset.y;

        // 拖动控件不在可视范围，则不需要显示菜单
        if (bOff >= self.frame.size.height || eOff < 1) return;
        
        if (CGPointEqualToPoint(_mouseLocation, CGPointZero)) { // 不存在记录的点
            float bOff2 = _toolManager.startGrabber.frame.origin.y + _toolManager.startGrabber.frame.size.height - _contentView.tableView.contentOffset.y;
            float eOff2 = _toolManager.endGrabber.frame.origin.y - _contentView.tableView.contentOffset.y;
            if (bOff2 >= 1) { // 开始拖动控件可见
                rect.origin.x = _toolManager.startGrabber.center.x;
                rect.origin.y = _toolManager.startGrabber.frame.origin.y;
            } else if (eOff2 < self.frame.size.height) { // 结尾拖动控件可见
                rect.origin.x = _toolManager.endGrabber.center.x;
                rect.origin.y = _toolManager.endGrabber.frame.origin.y;
            } else { // 开始拖动控件和结尾拖动控件 都不可见
                rect.origin.x = _contentView.tableView.center.x;
                rect.origin.y = _contentView.tableView.center.y + _contentView.tableView.contentOffset.y;
            }
        } else {
            rect.origin.x = _mouseLocation.x;
            rect.origin.y = _mouseLocation.y;
        }
    }
    
    float bOff = rect.origin.y - _contentView.tableView.contentOffset.y;
    float eOff = rect.origin.y + rect.size.height - _contentView.tableView.contentOffset.y;
    
    // 拖动控件不在可视范围，则不需要显示菜单
    if (bOff >= self.frame.size.height || eOff < 1) return;
    
    
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
    if (action == @selector(cut:) && (_menuType & FuMenuTypeWithCut))
    {
        return YES;
    } else if (action == @selector(copy:) && (_menuType & FuMenuTypeWithCopy))
    {
        return YES;
    } else if (action == @selector(paste:) && (_menuType & FuMenuTypeWithPaste))
    {
        return YES;
    } else if (action == @selector(select:) && (_menuType & FuMenuTypeWithSelect))
    {
        return YES;
    } else if (action == @selector(selectAll:) && (_menuType & FuMenuTypeWithSelectAll))
    {
        return YES;
    }
    return NO; //隐藏系统默认的菜单项
}

#pragma mark - 剪切

- (void)cut:(id)sender
{
#if TARGET_OS_IPHONE
    if (self.selectedText.length > 0)
    {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [_text getCopyString];
        [_textInput insertText:@""];
    }
#else
    [self copy:nil];
#endif
}

#pragma mark - 拷贝

- (void)copy:(id)sender
{
#if TARGET_OS_IPHONE
    if (self.selectedText.length > 0) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [_text getCopyString];
    }
#else
    if (self.selectedText.length > 0) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard writeObjects:@[self.selectedText]];
    }
#endif
}

#pragma mark - 粘贴

- (void)paste:(id)sender
{
#if TARGET_OS_IPHONE
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [_textInput insertText:pasteboard.string];
    [_textInput reloadInputViews];
#endif
}

#pragma mark - 选择

- (void)select:(id)sender
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if (pasteboard.string.length) {
        _menuType = FuMenuTypeWithCut | FuMenuTypeWithCopy | FuMenuTypeWithPaste;
    } else {
        _menuType = FuMenuTypeWithCut | FuMenuTypeWithCopy;
    }

    [self doSelectAction];
    
#if TARGET_OS_IPHONE
    if (self.isEditing) {
        [self showEditingMenu];
    }
#endif
    
    [self setNeedsLayout];
}

#pragma mark - 全选

- (void)selectAll:(id)sender
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if (pasteboard.string.length) {
        _menuType = FuMenuTypeWithCut | FuMenuTypeWithCopy | FuMenuTypeWithPaste;
    } else {
        _menuType = FuMenuTypeWithCut | FuMenuTypeWithCopy;
    }
    
    _text.selectedRange = NSMakeRange(0, _text.attributedString.length);
    
#if TARGET_OS_IPHONE
    if (self.isEditing) {
        [self showEditingMenu];
    }
#endif
    
    [self setNeedsLayout];
}


- (void)doSelectAction
{
    NSInteger preLen = _preText.attributedString.string.length;
    CFIndex row = [self getLineNumWithPoint:_mouseLocation];
    CTLineRef line = CFArrayGetValueAtIndex(_contentView.lines, row);
    CFIndex tempIndex = CTLineGetStringIndexForPosition(line, _mouseLocation) - preLen;
    
    CFRange stringRange = CTLineGetStringRange(line);
    NSString *text = nil;//[_text.string substringWithRange:NSMakeRange(stringRange.location, stringRange.length)];
    if ((stringRange.location + stringRange.length) > _text.attributedString.string.length)
    {
        text = [_text.attributedString.string substringWithRange:NSMakeRange(stringRange.location, (_text.attributedString.string.length - stringRange.location))];
    } else {
        text = [_text.attributedString.string substringWithRange:NSMakeRange(stringRange.location, stringRange.length)];
    }
    CFStringRef string = (__bridge CFStringRef) text;
    CFRange range = CFRangeMake(0, CFStringGetLength(string));
    CFStringTokenizerRef tokenizer = CFStringTokenizerCreate(NULL,
                                                             string,
                                                             range,
                                                             kCFStringTokenizerUnitWordBoundary,
                                                             NULL);
    CFStringTokenizerTokenType tokenType = CFStringTokenizerGoToTokenAtIndex(tokenizer, 0);
    while (tokenType != kCFStringTokenizerTokenNone)
    {
        range = CFStringTokenizerGetCurrentTokenRange(tokenizer);
        CFIndex first = range.location  + stringRange.location;
        CFIndex second = first + range.length;
    
        if (first != kCFNotFound && first <= tempIndex && tempIndex <= second)
        {
            _text.selectedRange = NSMakeRange(first, range.length);
            break;
        }
        
        tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer);
    }
    CFRelease(tokenizer);
}


#pragma mark - 删除输入

- (void)deleteBackward
{
    [_textInput deleteBackward];
}

- (void)deleteBackwardWithRange:(NSRange)range
{
    [_textInput deleteBackwardWithRange:range];
}

#pragma mark - FuTextInput Delegate

- (void)drawViewDidScroll:(FuDrawView *)drawView
{
    if ([_delegate respondsToSelector:@selector(textViewDidScroll:)]) {
        [_delegate textViewDidScroll:self];
    }
}

- (void)textInputOfAttributedText:(FuTextInput *)textInput attributedText:(NSAttributedString *)attributedText
{
    if ([_delegate respondsToSelector:@selector(textViewDidChange:)]) {
        [_delegate textViewDidChange:self];
    }
    _inputing = YES;
    [self hideEditingMenu];
    [self setNeedsLayout];
}

- (void)textInputOfTriggerString:(FuTextInput *)textInput triggerString:(NSString *)triggerString
{
    if ([_delegate respondsToSelector:@selector(textViewDidTriggerString:triggerString:)])
    {
        [_delegate textViewDidTriggerString:self triggerString:triggerString];
    }
}

- (BOOL)textInput:(FuTextInput *)textInput shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([_delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)])
    {
        return [_delegate textView:self shouldChangeTextInRange:range replacementText:text];
    }
    return YES;
}

#pragma mark - FuDrawView Delegate

- (void)drawViewDidTouchBegin:(UITouch *)touch point:(CGPoint)point
{
    [self dealEventWithWithType:@"touchBegan" object:touch point:point];
}

- (void)drawViewDidLongPress:(UILongPressGestureRecognizer *)longPress point:(CGPoint)point
{
    [self dealEventWithWithType:@"longPress" object:longPress point:point];
}

- (void)drawViewWillBeginDragging:(FuDrawView *)drawView
{
    [self hideEditingMenu];
    if ([_delegate respondsToSelector:@selector(textViewWillBeginDragging:)]) {
        [_delegate textViewWillBeginDragging:self];
    }
}

- (void)drawViewDidEndDragging:(FuDrawView *)drawView
{
    if (_text.selectedRange.length) {
        _mouseLocation = CGPointZero;
        [self showEditingMenu];
    }
}

- (void)drawViewDidEndDecelerating:(FuDrawView *)drawView
{
    if (_text.selectedRange.length) {
        _mouseLocation = CGPointZero;
        [self showEditingMenu];
    }
}

- (void)dealEventWithWithType:(NSString *)type object:(id)object point:(CGPoint)point
{
    BOOL needUpdate = YES;
    NSUInteger testLoca = _text.selectedRange.location;
    if (testLoca > 0 && testLoca != NSNotFound && testLoca == _text.attributedString.length)
    {
        __block BOOL needChange = NO;
        [_text.attributedString enumerateAttribute:(id)kCTRunDelegateAttributeName inRange:NSMakeRange(testLoca - 1, 1) options:kNilOptions usingBlock:^(id value, NSRange range, BOOL *stop) {
            if (!value) return;
            
            CTRunDelegateRef runDelegate = (__bridge CTRunDelegateRef)value;
            FuTextRun *attachment = (__bridge FuTextRun *)CTRunDelegateGetRefCon(runDelegate);
            if (!attachment) return;
            
            if (attachment.type == FuText_view)
            {
                needChange = YES;
            }
        }];
        if (needChange && point.y <= CGRectGetMaxY(_toolManager.caretView.frame) + _edgeInsets.bottom && point.y >= CGRectGetMinY(_toolManager.caretView.frame) - _edgeInsets.top)
        {
            NSLog(@"符合条件");
            needUpdate = NO;
        }
    }
    
    if (!needUpdate)
    {
        [self dealEventWithType:type object:object lpoint:point point:CGPointZero index:testLoca caretHeight:0];
        return;
    }
    
    NSInteger row = [self getLineNumWithPoint:point];
    
    float nextHeight = [[_contentView.lineHeightDictionary objectForKey:@(row).stringValue] floatValue];
    float y = [[_contentView.lineHeightDictionary objectForKey:@(row - 1).stringValue] floatValue];
    float caretHeight = nextHeight - y;
    caretHeight = fabs(caretHeight);
    
    float x = 0;
    CFIndex index  = 0;
    if (_contentView.lines && row < _contentView.lineCount)
    {
        CTLineRef line = CFArrayGetValueAtIndex(_contentView.lines, row);
        _updateLine = line;
        index =  CTLineGetStringIndexForPosition(line, CGPointMake(point.x - self.edgeInsets.left, point.y));
        CFRange stringRange1 = CTLineGetStringRange(line);
        NSRange stringRange = NSMakeRange(stringRange1.location, stringRange1.length);
        _updateStringRange = stringRange;
        
        NSString *lastCharacter = @"";
        CFIndex lastIndex = stringRange.length - 1;
        
        NSAttributedString *aString = [_contentView.attributedText attributedSubstringFromRange:stringRange];
        
        if (lastIndex < aString.length) {
            lastCharacter = [aString.string substringWithRange:NSMakeRange(lastIndex, 1)]; // 解决手动换行
        }
        
        if (index != 0 && index != NSNotFound && [lastCharacter isEqualToString:@"\n"] && index == NSMaxRange(stringRange)) {
            index = index - 1;
        }
        
        if (index == NSNotFound)
        {
            index = stringRange.location + stringRange.length;
        }
        if (stringRange.length == 0)
        {
            index = 0;
        }
        x = CTLineGetOffsetForStringIndex(line, index, NULL);
    }

    [self dealEventWithType:type object:object lpoint:point point:CGPointMake(x, y) index:index caretHeight:caretHeight];
}


- (void)dealEventWithType:(NSString *)type object:(id)object lpoint:(CGPoint)lpoint point:(CGPoint)point index:(CFIndex)index caretHeight:(float)caretHeight
{
    if (!_toolManager.startGrabber.hidden && !_toolManager.endGrabber.hidden) // 拖动控件存在的时候
    {
        if (lpoint.x >= _toolManager.startGrabber.frame.origin.x && lpoint.x <= (_toolManager.startGrabber.frame.origin.x + _toolManager.startGrabber.frame.size.width) && lpoint.y >= _toolManager.startGrabber.frame.origin.y && lpoint.y <= (_toolManager.startGrabber.frame.origin.y + _toolManager.startGrabber.frame.size.height)) { // 忽略触击开始拖动控件
            return;
        }
        
        if (lpoint.x >= _toolManager.endGrabber.frame.origin.x && lpoint.x <= (_toolManager.endGrabber.frame.origin.x + _toolManager.endGrabber.frame.size.width) && lpoint.y >= _toolManager.endGrabber.frame.origin.y && lpoint.y <= (_toolManager.endGrabber.frame.origin.y + _toolManager.endGrabber.frame.size.height)) { // 忽略触击结尾拖动控件
            return;
        }
        if ([type isEqualToString:@"longPress"]) { // 避免长按拖动控制并移动，带来的问题
            return;
        }
    }
    
    NSUInteger preLen = self.preText.attributedString.string.length;
    if (self.text.attributedString.string.length && index >= preLen)
    {
        if (caretHeight > 0)
        {
            [_toolManager updateCaretViewWithPoint:point caretHeight:caretHeight];
        }
        
        NSUInteger location = index - preLen;
        
        NSRange hRange = self.text.markedRange;
        if (!hRange.length) {
            hRange = self.text.selectedRange;
        }
        if (hRange.location != NSNotFound && hRange.length && [type isEqualToString:@"touchBegan"])  // 存在高亮区域
        {
            [_textInput.inputDelegate selectionWillChange:_textInput];
            if (location > hRange.location && location < NSMaxRange(hRange)) // 在高亮区域
            {
                self.text.markedRange   = NSMakeRange(NSNotFound, 0);
                self.text.selectedRange = NSMakeRange(location, 0);
            } else  {                                                       // 不在高亮区域
                self.text.markedRange   = NSMakeRange(NSNotFound, 0);
                self.text.selectedRange = NSMakeRange(location, 0);
                [self hideEditingMenu];
            }
            
            [_textInput.inputDelegate selectionDidChange:_textInput];
            [self setNeedsLayout];
        } else {
            [self hideEditingMenu];
            self.text.selectedRange = NSMakeRange(location, 0);
            self.text.markedRange   = NSMakeRange(NSNotFound, 0);
            [_textInput.inputDelegate selectionDidChange:_textInput];
        }
    
    }
    
    if ([type isEqualToString:@"touchBegan"])
    {
        if ([_delegate respondsToSelector:@selector(textViewDidTouch:touch:)]) {
            [_delegate textViewDidTouch:self touch:object];
        }
    }
    
    if ([type isEqualToString:@"longPress"]) // 长按手势
    {
        if ([_delegate respondsToSelector:@selector(textViewDidLongPress:gestureRecognizer:)]) {
            [_delegate textViewDidLongPress:self gestureRecognizer:object];
        }
        _mouseLocation = lpoint;
        [self longPressGestureStateChanged:object];
    }
}

#pragma mark - 长按手势

- (void)longPressGestureStateChanged:(UILongPressGestureRecognizer *)gestureRecognizer
{
    _mouseLocation = [gestureRecognizer locationInView:_contentView.tableView];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        [_toolManager moveLookMagnifierToPoint:[gestureRecognizer locationInView:[UIApplication sharedApplication].keyWindow]];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        [self scrollToCaretPosition];
        [_toolManager moveLookMagnifierToPoint:[gestureRecognizer locationInView:[UIApplication sharedApplication].keyWindow]];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded ||
               gestureRecognizer.state == UIGestureRecognizerStateCancelled ||
               gestureRecognizer.state == UIGestureRecognizerStateFailed)
    {
        [_toolManager hideLookMagnifierToPoint:[gestureRecognizer locationInView:[UIApplication sharedApplication].keyWindow]];
        
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        if (pasteboard.string.length)
        {
            if (self.text.attributedString.string.length) {
                self.menuType = FuMenuTypeWithSelect | FuMenuTypeWithSelectAll | FuMenuTypeWithPaste;
            } else {
                self.menuType = FuMenuTypeWithPaste;
            }
            [self showEditingMenu];
        } else if (self.text.attributedString.string.length)
        {
            self.menuType = FuMenuTypeWithSelect | FuMenuTypeWithSelectAll;
            [self showEditingMenu];
        }
    }
}

#pragma mark - 点超出可视范围，则滚动到点处

- (void)scrollToPoint:(CGPoint)point
{
    [self scrollToCaretPosition];
}

#pragma mark -

- (CGRect)rectOfStringWithRange:(NSRange)range
{
    CGRect rect = CGRectZero;
    NSRange intersectionRange = NSIntersectionRange(_updateStringRange, range);
    
    if (intersectionRange.length > 0) {
        CTLineRef line = _updateLine;
        CGFloat startOffset = CTLineGetOffsetForStringIndex(line, intersectionRange.location, NULL);
        CGFloat endOffset = CTLineGetOffsetForStringIndex(line, NSMaxRange(intersectionRange), NULL);
        
        CGRect lineRect = CGRectMake(self.edgeInsets.left, self.edgeInsets.top, _contentView.tableView.bounds.size.width - self.edgeInsets.left - self.edgeInsets.right, _text.fontHeight);
        rect = lineRect;
        rect.origin.x += startOffset;
        rect.size.width -= (rect.size.width - endOffset);
        rect.size.width = rect.size.width - startOffset;
    }
    
    return rect;
}

- (float)getLineHeightFromLine:(NSInteger)line1 toLine:(NSInteger)line2
{
    NSInteger count = _contentView.lineHeightDictionary.count;
    float pre = line1 - 1;
    float next = (count - 1) < line2 ? (count - 1) : line2;
    float height1 = pre == next ? 0 : [[_contentView.lineHeightDictionary objectForKey:@(pre).stringValue] floatValue];
    float height2 = [[_contentView.lineHeightDictionary objectForKey:@(next).stringValue] floatValue];
    
    float height = height2 == 0 ? (height1 - _text.lineSpacing) : (height2 - height1 - _text.lineSpacing);
    return height;
}

@end
//
//  FuTextView.h
//  Test
//
//  Created by syq on 14-5-28.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "FuTextInput.h"
#import "FuManager.h"
#import "FuDrawTextView.h"

@class FuTextView;

///========代理类=======///

@protocol FuTextViewDelegate <NSObject, UIScrollViewDelegate>

@optional

//- (BOOL)textViewShouldBeginEditing:(FuTextView *)textView;
//- (BOOL)textViewShouldEndEditing:(FuTextView *)textView;
//
//- (void)textViewDidBeginEditing:(FuTextView *)textView;
//- (void)textViewDidEndEditing:(FuTextView *)textView;
//
- (BOOL)textView:(FuTextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
- (void)textViewDidChange:(FuTextView *)textView;

//- (void)textViewDidChangeSelection:(FuTextView *)textView;
//
//- (BOOL)textView:(FuTextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange NS_AVAILABLE_IOS(7_0);
//- (BOOL)textView:(FuTextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange NS_AVAILABLE_IOS(7_0);

- (void)textViewClickPreText:(FuTextView *)textView; // 文本前缀字段点击事件
- (void)textViewClickSufText:(FuTextView *)textView; // 文本后缀字段点击事件

- (void)textViewDidTriggerString:(FuTextView *)textView triggerString:(NSString *)triggerString; // 触发器字符（输入某个字符，触发此动作）

- (void)textViewScrollHeightDidChange:(FuTextView *)textView scrollHeight:(float)scrollHeight;   // 输入框高度发送变化

- (void)textViewDidTouch:(FuTextView *)textView touch:(UITouch *)touch;
- (void)textViewDidLongPress:(FuTextView *)textView gestureRecognizer:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)textViewDidScroll:(FuTextView *)textView;
- (void)textViewWillBeginDragging:(FuTextView *)textView;

@end


typedef enum {
    FuMenuTypeWithCopy      = 1 << 0, // 拷贝/复制
    FuMenuTypeWithPaste     = 1 << 1, // 粘贴
    FuMenuTypeWithSelect    = 1 << 2, // 选择
    FuMenuTypeWithSelectAll = 1 << 3, // 全选
    FuMenuTypeWithCut       = 1 << 4  // 剪切
} FuMenuType;

///========视图类=======///

@interface FuTextView : UIView

@property(nonatomic,weak)  id<FuTextViewDelegate> delegate;

@property (nonatomic, strong, readonly) FuTextModel *text;         // 文本字段   不支持event
@property (nonatomic, strong, readonly) FuTextModel *preText;      // 文本前缀字段  支持event
@property (nonatomic, strong, readonly) FuTextModel *sufText;      // 文本后缀字段  支持event
@property (nonatomic, strong, readonly) FuTextModel *placeHolder;  // 提示字段   不支持event

@property (nonatomic, strong, readonly) FuManager   *toolManager;          // 工具管理
@property (nonatomic, strong) FuDrawTextView      *contentView;          // 内容视图

@property (nonatomic) UIEdgeInsets      edgeInsets;        // 绘制视图与本视图的边距 默认为0
@property (nonatomic, strong) NSString *triggerString;     // 触发器字符 默认 is @  如果有多个，则以逗号拼接
@property (nonatomic) BOOL              editable;          // 默认 is YES
@property (nonatomic) BOOL              selectable;
@property (nonatomic) BOOL              scrollTop;

/**
 是否可以编辑附件，默认NO。
 当为YES时，保证调用resignFirstResponder不失去焦点。
 如果调用resignFirstResponder需要失去焦点，应保证其为NO。
*/
@property (nonatomic)            BOOL    canEditAttachments;
@property (nonatomic, readonly)  BOOL    isEditing;          // 是否正在编辑
@property (nonatomic, readwrite) NSInteger    menuType;           // 菜单类型
@property (nonatomic)          NSInteger numberOfLines; // 显示的行数 默认0 表示不限制，全部显示

@property (nonatomic) BOOL needManageScroll; // 默认NO

// 其他方法
- (void)deleteBackward;                                                      // 删除输入
- (void)deleteBackwardWithRange:(NSRange)range;
- (void)insertString:(NSString *)string;
- (void)insertTriggerString;                                                 // 插入当前触发器字符
- (void)insertAtWithName:(NSString *)name uid:(NSString *)uid;               // 插入@
- (void)insertTopicWithName:(NSString *)name topicId:(NSString *)topicId;    // 插入话题
- (void)insertFaceWithName:(NSString *)name size:(CGSize)size;               // 插入表情
- (void)insertImageWithName:(NSString *)name size:(CGSize)size;              // 插入图片


// 获得焦点时，弹出的键盘视图和键盘上边视图。默认是系统键盘
@property (readwrite, strong) UIView *inputView;          // 键盘视图
@property (readwrite, strong) UIView *inputAccessoryView; // 键盘上边视图

@property (nonatomic, strong) UIView *textHeaderView;     // 绘制视图上边视图
@property (nonatomic, strong) UIView *textFooterView;     // 绘制视图下边视图


// 系统键盘相关设置
@property(nonatomic) UITextAutocapitalizationType autocapitalizationType; // default is UITextAutocapitalizationTypeSentences
@property(nonatomic) UITextAutocorrectionType autocorrectionType;         // default is UITextAutocorrectionTypeDefault
@property(nonatomic) UITextSpellCheckingType spellCheckingType;           // default is UITextSpellCheckingTypeDefault;
@property(nonatomic) UIKeyboardType keyboardType;                         // default is UIKeyboardTypeDefault
@property(nonatomic) UIKeyboardAppearance keyboardAppearance;             // default is UIKeyboardAppearanceDefault
@property(nonatomic) UIReturnKeyType returnKeyType;                       // default is UIReturnKeyDefault (See note under UIReturnKeyType enum)
@property(nonatomic) BOOL enablesReturnKeyAutomatically;                  // default is NO (when YES, will automatically disable return key when text widget has zero-length contents, and will automatically enable when text widget has non-zero-length contents)
@property(nonatomic,getter=isSecureTextEntry) BOOL secureTextEntry;       // default is NO



- (CFIndex)getLineLocationWithPoint:(CGPoint)point;//获取此点所处于行的位置
- (CFIndex)getLineNumWithPoint:(CGPoint)point; //通过点得到行号
- (CFIndex)getLineNumWithLocation:(CFIndex)location; //通过范围得到行号 
- (CTLineRef)getLineWithlineNum:(CFIndex)lineNum; //通过行号得到行
- (BOOL)isCaretFrameOverSuper;
- (CGPoint)drawConvertPoint:(CGPoint)point;
- (void)scrollToCaretPosition; // 滚动到光标位置
- (void)scrollOfHeight:(float)height;
- (void)scrollToTop;
//- (CGRect)rectOfStringWithRange:(NSRange)range;
- (float)getLineHeightFromLine:(NSInteger)line1 toLine:(NSInteger)line2;

- (void)showEditingMenu;
- (void)hideEditingMenu;

@end

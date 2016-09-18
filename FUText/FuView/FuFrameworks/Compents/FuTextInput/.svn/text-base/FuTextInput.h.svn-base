//
//  FuTextInput.h
//  Test
//
//  Created by syq on 14-5-28.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import "FuTextModel.h"

@class FuTextView;

///========1=======///

@interface FuTextRange : UITextRange

@property (nonatomic) NSRange range;

+ (FuTextRange *)rangeWithNSRange:(NSRange)theRange;

@end

///========2=======///

@interface FuTextPosition : UITextPosition

@property (nonatomic, weak) id delegate;
@property (nonatomic) NSUInteger index;

+ (FuTextPosition *)positionWithIndex:(NSUInteger)index;

@end

@class FuTextInput;

///========代理类=======///

@protocol FuTextInputDelegate <NSObject>

@optional

- (void)textInputOfTriggerString:(FuTextInput *)textInput triggerString:(NSString *)triggerString;
- (void)textInputOfAttributedText:(FuTextInput *)textInput attributedText:(NSAttributedString *)attributedText;
- (BOOL)textInput:(FuTextInput *)textInput shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;

@end

///========3=======///

@interface FuTextInput : UIResponder<UITextInput>

/**
 @info  初始化方法
 @param textView 响应视图   必须设置
 @return 返回创建对象
 */

- (id)initWithTextView:(FuTextView *)textView;

@property (nonatomic, weak)   id<FuTextInputDelegate> delegate; // 代理

@property(nonatomic) BOOL editable;                         // 默认 is YES
@property(nonatomic) BOOL selectable;                      //
// 是否可以编辑附件，默认NO。
// 当为YES时，保证调用resignFirstResponder不失去焦点。
// 如果调用resignFirstResponder需要失去焦点，应保证其为NO
@property (nonatomic) BOOL    canEditAttachments;        // 是否可以编辑附件

@property (nonatomic, readonly) BOOL isEditing;          // 是否正在编辑

@property (nonatomic, strong) NSString *triggerString;          // 触发器字符 默认 is @  如果有多个，则以逗号拼接
@property (nonatomic, strong) NSString *currentTriggerString;   // 当前触发器字符


/// 其他方法
- (void)insertAttributedText:(NSAttributedString *)attributedText;

// 清空当前触发器字符
- (void)clearCurrentTriggerString;

- (void)deleteBackward;
- (void)deleteBackwardWithRange:(NSRange)range;

/// 重写UITextInputTraits接口的属性
@property(nonatomic) UITextAutocapitalizationType autocapitalizationType; // default is UITextAutocapitalizationTypeSentences
@property(nonatomic) UITextAutocorrectionType autocorrectionType;         // default is UITextAutocorrectionTypeDefault
@property(nonatomic) UITextSpellCheckingType spellCheckingType;           // default is UITextSpellCheckingTypeDefault;
@property(nonatomic) UIKeyboardType keyboardType;                         // default is UIKeyboardTypeDefault
@property(nonatomic) UIKeyboardAppearance keyboardAppearance;             // default is UIKeyboardAppearanceDefault
@property(nonatomic) UIReturnKeyType returnKeyType;                       // default is UIReturnKeyDefault (See note under UIReturnKeyType enum)
@property(nonatomic) BOOL enablesReturnKeyAutomatically;                  // default is NO (when YES, will automatically disable return key when text widget has zero-length contents, and will automatically enable when text widget has non-zero-length contents)
@property(nonatomic,getter=isSecureTextEntry) BOOL secureTextEntry;       // default is NO


@end

//
//  GWWTextView.h
//  GroupWenWen
//
//  Created by javalong on 16/4/7.
//  Copyright © 2016年 evan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FuTextView.h"
#import "TWFaceGridView.h"

@class GWWTextView;

@protocol GWWTextViewDelegate <NSObject>

@optional
- (void)textViewDidChange:(GWWTextView *)textView;
- (void)textViewDidTriggerString:(GWWTextView *)textView triggerString:(NSString *)triggerString; // 触发器字符（输入某个字符，触发此动作）
- (BOOL)textViewDidSend:(GWWTextView *)textView;
- (void)textViewDidPhoto:(NSInteger)index;
- (void)textViewDidRecordFinished:(NSData *)data recordTime:(NSInteger)recordTime;
- (void)textViewHeightDidChange:(GWWTextView *)textView changeHeight:(NSNumber *)height;
- (NSArray *)textViewDidShowImage:(GWWTextView *)textView;
- (void)textViewDidRemoveImage:(GWWTextView *)textView index:(NSInteger)index;
- (void)textViewDidPreImage:(GWWTextView *)textView index:(NSInteger)index;
- (void)textViewDidAddImage:(GWWTextView *)textView;
- (void)textViewDidTouch:(GWWTextView *)textView touch:(UITouch *)touch;
- (void)textViewDidScroll:(GWWTextView *)textView;
- (void)textViewWillBeginDragging:(GWWTextView *)textView;

@end

@interface GWWTextView : UIView<FuTextViewDelegate, TWFaceGridViewDelegate>

@property (nonatomic, weak) id<GWWTextViewDelegate> delegate;
@property (nonatomic, strong)           NSString *text;        // 文本
@property (nonatomic, strong)           NSString *placeHolder; // 标记文本
@property (nonatomic)                   BOOL editable;         // 默认 YES
@property (nonatomic) BOOL showAttachmen; // 显示表情键盘
@property (nonatomic) BOOL showSystem;    // 显示文本键盘

@property (nonatomic) BOOL showTriggerString;   //是否显示触发器字符（default：YES）
@property (nonatomic) BOOL canEditAttachments;  // 除系统键盘外，其他键盘是否需要光标，默认YES

// 编辑时显示的键盘 默认是系统键盘
- (void)switchKeyBoard;          // 切换系统键盘和附件键盘
- (void)showSystemKeyBoard;      // 显示系统键盘
- (void)showAttachmentKeyBoard;  // 显示附件键盘，默认是表情键盘


- (void)deleteBackward;                                                      // 删除输入
- (void)insertTriggerString;                                                 // 插入当前触发器字符（showTriggerString=YES时生效）
- (void)insertAtWithName:(NSString *)name uid:(NSString *)uid;               // 插入@
- (void)insertTopicWithName:(NSString *)name topicId:(NSString *)topicId;    // 插入话题
- (void)insertAttachmenWithPath:(NSString *)path size:(CGSize)size;          // 插入表情


@property (nonatomic, strong, readwrite) FuTextView *textView;   // 输入视图

@property (readwrite, weak)   UIView *showInputView;      // 键盘在哪个视图上显示，默认是self.superView
@property (readwrite, strong) UIView *inputView;          // 键盘视图
@property (readwrite, strong) UIView *inputAccessoryView; // 键盘上部视图

@property (strong, readonly) TWFaceGridView *emojiKeyBoard; // 表情键盘
@property (nonatomic, readonly) double    animationDuration;
@property (nonatomic, readonly) NSInteger animationCurve;
@property (nonatomic, readonly) CGRect    keyboardRect;


- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;

@end

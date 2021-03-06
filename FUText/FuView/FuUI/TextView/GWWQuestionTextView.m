//
//  GWWQuestionTextView.m
//  GroupWenWen
//
//  Created by javalong on 16/4/8.
//  Copyright © 2016年 evan. All rights reserved.
//

#import "GWWQuestionTextView.h"
#import "GWWEditButton.h"

@interface GWWQuestionTextView ()

@end

@implementation GWWQuestionTextView
{
    NSMutableArray *_showImageList;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _allowInputMax = -1;
        _needGridImage = NO;
    }
    return self;
}

- (void)layoutSubviews
{
    if (_needGridImage)
    {
        [self showGridImage];
    } else
    {
        self.textView.textFooterView = _needScrollToBarBottom ? [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 42.0)] : nil;
    }
    [super layoutSubviews];
}

#pragma mark - 九宫格显示图片s

- (void)showGridImage
{
    if (!_showImageList) {
        _showImageList = [[NSMutableArray alloc] init];
    }
    if ([self.delegate respondsToSelector:@selector(textViewDidShowImage:)])
    {
        _showImageList.array = [self.delegate textViewDidShowImage:self];
    }
    
    NSInteger maxNum = 5;
    
    NSInteger count = _showImageList.count;
    if (count > 0)
    {
        if (count < maxNum)
        {
            count += 1;
        }
        int   col   = 3;
        float left  = self.textView.edgeInsets.left;
        float right = self.textView.edgeInsets.right;
        float top   = self.textView.edgeInsets.top;
        float edge  = 3.0;
        
        float width = self.frame.size.width - left - right - (col - 1) * edge;
        width = width/(col * 1.0);
        
        int row = ceilf(count * 1.0 / (col * 1.0));
        float fheight = row * width + (row - 1) * edge + top;
        UIView *textFooterView  = self.textView.textFooterView;
        if (!textFooterView) {
            textFooterView = [[UIView alloc] init];
        }
        if (_needScrollToBarBottom)
        {
            textFooterView.frame = CGRectMake(0.0, 0.0, self.textView.bounds.size.width, fheight + 42.0);
        } else
        {
            textFooterView.frame = CGRectMake(0.0, 0.0, self.textView.bounds.size.width, fheight);
        }
        self.textView.textFooterView = textFooterView;
        
        for (NSInteger i = 0; i < count; i++)
        {
            NSInteger tag  = i + 1;
            GWWEditButton *imageButton = [textFooterView viewWithTag:tag];
            if (!imageButton)
            {
                imageButton = [[GWWEditButton alloc] init];
                [imageButton addTarget:self action:@selector(showImageWithTag:) forControlEvents:UIControlEventTouchUpInside];
                [textFooterView addSubview:imageButton];
            }
            imageButton.tag   = tag;
            float x = (i % col) * (width + edge) + left;
            float y = (i / col) * (width + edge);
            imageButton.frame = CGRectMake(x, y, width, width);
            
            if (i >= _showImageList.count)
            {
//                imageButton.backgroundColor = [UIColor colorWithString:@"#f6f6f6"];
                [imageButton setImage:[UIImage imageNamed:@"edit_addImage_normal"] forState:UIControlStateNormal];
                [imageButton setImage:[UIImage imageNamed:@"edit_addImage_light"] forState:UIControlStateHighlighted];
                imageButton.editImageView.hidden = YES;
                imageButton.closeButton.hidden = YES;
                imageButton.imageView.hidden = NO;
                continue;
            }
            imageButton.editImageView.hidden = NO;
            imageButton.closeButton.hidden = NO;
            imageButton.imageView.hidden = YES;
            NSString *path = [_showImageList objectAtIndex:i];
//            if (path.isUrl)
//            {
//                imageButton.editImageView.url = [path stringByAppendingString:@"/90"];
//            } else
//            {
//                imageButton.editImageView.image = [UIImage imageWithContentsOfFile:path.documentFilePath];
//            }
            if (!imageButton.closeButton.allTargets.count)
            {
                [imageButton.closeButton addTarget:self action:@selector(removeImage:) forControlEvents:UIControlEventTouchUpInside];
            }
            // 图片上的按钮
            tag = 999;
            imageButton.closeButton.tag = tag;
            UIImage *closeImage = [UIImage imageNamed:@"questionTextViewCloseImage"];
            [imageButton.closeButton setImage:closeImage forState:UIControlStateNormal];
            float closeEdge = 5;
            float closeX = imageButton.frame.size.width - closeEdge - closeImage.size.width;
            float closeY = closeEdge;
            imageButton.closeButton.frame = CGRectMake(closeX, closeY, closeImage.size.width, closeImage.size.height);
        }
    } else
    {
        self.textView.textFooterView = _needScrollToBarBottom ? [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 42.0)] : nil;
    }
    
    for (NSInteger i = count + 1; i < self.tag; i++)
    {
        UIView *subView = [self viewWithTag:i];
        [subView removeFromSuperview];
        subView = nil;
    }
    
    self.tag = count + 1;
}

#pragma mark - 按钮事件

- (void)removeImage:(UIButton *)sender
{
    NSInteger tag = sender.superview.tag;
    tag = tag - 1;
    [self removeImageWithTag:tag];
}

- (void)removeImageWithTag:(NSInteger)tag
{
    if (tag >= 0 && tag < _showImageList.count && _showImageList.count)
    {
        [_showImageList removeObjectAtIndex:tag];
        [self setNeedsLayout];
        [self.textView setNeedsLayout];
        if ([self.delegate respondsToSelector:@selector(textViewDidRemoveImage:index:)])
        {
            [self.delegate textViewDidRemoveImage:self index:tag];
        }
    }
}

- (void)showImageWithTag:(UIButton *)sender
{
    NSInteger tag = sender.tag;
    tag = tag - 1;
    if (tag >= _showImageList.count)
    {
        if ([self.delegate respondsToSelector:@selector(textViewDidAddImage:)])
        {
            [self.delegate textViewDidAddImage:self];
        }
        return;
    }
    if ([self.delegate respondsToSelector:@selector(textViewDidPreImage:index:)])
    {
        [self.delegate textViewDidPreImage:self index:tag];
    }

//    [TWPhotoZoomMainView showBrowserInWindow:_showImageList startPage:tag optionType:option_delete loadType:topicImage showOriginalButton:NO needBottom:YES delegate:self];
}

#pragma mark - TWPhotoZoomMainViewDelegate

- (void)willDeleteIndex:(NSInteger)index
{
    [self removeImageWithTag:index];
}

- (void)deleteSuccess
{

}

#pragma mark - delegate

- (void)textViewDidChange:(FuTextView *)textView
{
    if (_allowInputMax != -1 && textView.text.attributedString.length > _allowInputMax)
    {
        NSRange range = NSMakeRange(_allowInputMax, textView.text.attributedString.length-_allowInputMax);
        textView.text.eventColor = [UIColor redColor];//[UIColor colorWithString:@"#b2b2b2"];
        textView.text.eventFont  = textView.text.font;
        textView.text.eventRange = range;
    } else
    {
        textView.text.eventColor = nil;
        textView.text.eventFont  = nil;
        textView.text.eventRange = NSMakeRange(0, 0);
    }
    [super textViewDidChange:textView];
}

- (void)textViewScrollHeightDidChange:(FuTextView *)textView scrollHeight:(float)scrollHeight
{
//    if (!self.textView.isEditing) {
//        return;
//    }
    if ([self.delegate respondsToSelector:@selector(textViewHeightDidChange:changeHeight:)]) {
        [self.delegate textViewHeightDidChange:self changeHeight:@(scrollHeight)];
    }
}

- (void)textViewWillBeginDragging:(FuTextView *)textView
{
    [self resignFirstResponder];
}

@end

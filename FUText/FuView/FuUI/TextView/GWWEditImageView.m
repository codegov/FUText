//
//  GWWEditImageView.m
//  GroupWenWen
//
//  Created by javalong on 16/6/12.
//  Copyright © 2016年 evan. All rights reserved.
//

#import "GWWEditImageView.h"

@interface GWWEditImageView ()

//@property (nonatomic, strong) GWWImageView *editImageView;
@property (nonatomic, strong) UIButton *closeButton;

@end

@implementation GWWEditImageView

- (instancetype)init
{
    self = [super init];
    if (self) {
        _allowCliclImage = YES;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _allowCliclImage = YES;
    }
    return self;
}

//- (GWWImageView *)editImageView
//{
//    if (!_editImageView)
//    {
//        _editImageView = [[GWWImageView alloc] init];
//        _editImageView.contentMode = UIViewContentModeScaleAspectFill;
//        _editImageView.backgroundColor = [UIColor lightGrayColor];
//        _editImageView.userInteractionEnabled = _allowCliclImage;
//        _editImageView.clipsToBounds = YES;
//        [self addSubview:_editImageView];
//        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
//        [_editImageView addGestureRecognizer:tap];
//        
//        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longAction)];
//        [_editImageView addGestureRecognizer:longPress];
//    }
//    return _editImageView;
//}

- (UIButton *)closeButton
{
    if (!_closeButton)
    {
        _closeButton = [[UIButton alloc] init];
        [_closeButton addTarget:self action:@selector(deleteCustromView:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_closeButton];
    }
    return _closeButton;
}

- (void)deleteCustromView:(UIButton *)sender
{
//    if ([sender.superview isKindOfClass:[GWWEditImageView class]])
//    {
//        sender.transform = CGAffineTransformMakeScale(0.75, 0.75);
//        [UIView animateWithDuration:0.25 animations:^{
//            sender.transform = CGAffineTransformMakeScale(1, 1);
//        }];
//        GWWEditImageView *view = (GWWEditImageView *)sender.superview;
//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        if (view.editImageView.userInfo)
//        {
//            [dic setDictionary:view.editImageView.userInfo];
//        }
//        [dic setObject:@"delete" forKey:@"type"];
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"GWWImageViewImageDidChangeNotification" object:nil userInfo:dic];
//    }
}

- (void)setUserInfo:(NSDictionary *)userInfo
{
//    self.clipsToBounds = YES;
//    _userInfo      = userInfo;
//    self.editImageView.userInfo = userInfo;
//    NSString *path          = [userInfo objectForKey:@"path"];
//    NSString *imageSizeStr  = [userInfo objectForKey:@"imageSize"];
//    int showClose           = [[userInfo objectForKey:@"showClose"] intValue];
//    float imageOff          = [[userInfo objectForKey:@"imageOff"] floatValue];
//    
//    CGSize imageSize = CGSizeFromString(imageSizeStr);
//    self.editImageView.frame = CGRectMake(0, imageOff, imageSize.width, imageSize.height - 2 * imageOff);
//    
//    if (showClose)
//    {
//        UIImage *closeImage = [UIImage imageNamed:@"questionTextViewCloseImage"];
//        [self.closeButton setImage:closeImage forState:UIControlStateNormal];
//        float width  = closeImage.size.width + 10;
//        float height = closeImage.size.height + 10;
//        float closeEdge = imageOff;
//        float closeX = _editImageView.frame.size.width - closeEdge - width;
//        float closeY = closeEdge;
//        self.closeButton.frame = CGRectMake(closeX, closeY, width, height);
//    }
//    if (!path.length) return;
//    if (path.isUrl)
//    {
//        self.editImageView.url = path;
//    } else
//    {
//        self.editImageView.image = [UIImage imageWithContentsOfFile:path.documentFilePath];
//    }
}

- (void)tapAction
{
    if ([_delegate respondsToSelector:@selector(editImageViewDidScanImage:)])
    {
        [_delegate editImageViewDidScanImage:self];
    }
}

- (void)longAction
{
    
}

@end

//
//  GWWEditImageView.h
//  GroupWenWen
//
//  Created by javalong on 16/6/12.
//  Copyright © 2016年 evan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GWWEditImageView;

@protocol GWWEditImageViewDelegate <NSObject>

@optional
- (void)editImageViewDidScanImage:(GWWEditImageView *)editImageView;

@end

@interface GWWEditImageView : UIView

/**
 key包括：
 1、path         :图片路径
 2、range        :在字符串中的位置
 3、showClose    :是否显示关闭按钮
 4、imageSize    :图片视图显示大小
 5、changeSize   :图片大小
 6、type         :类型delete(关闭按钮事件)/download(图片下载成功)

 */
@property (nonatomic, strong) NSDictionary *userInfo;
@property (nonatomic, weak) id<GWWEditImageViewDelegate> delegate;
@property (nonatomic) BOOL allowCliclImage;// 默认 YES

@end

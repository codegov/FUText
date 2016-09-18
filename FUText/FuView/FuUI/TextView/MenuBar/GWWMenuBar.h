//
//  GWWQuestionMenuBar.h
//  GroupWenWen
//
//  Created by javalong on 16/4/11.
//  Copyright © 2016年 evan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    GWWMenuBarTypeWithAlbum      = 1 << 0, // 相册
    GWWMenuBarTypeWithCamera     = 1 << 1, // 相机
    GWWMenuBarTypeWithArrow      = 1 << 2, // 收键盘
    GWWMenuBarTypeWithSize       = 1 << 3, // 输入大小
    GWWMenuBarTypeWithFlexibleSpace = 1 << 4 // 空格
} GWWMenuBarType;

@class GWWMenuBar;

@protocol GWWMenuBarDelegate <NSObject>

@optional
- (GWWMenuBarType)menuBarNeedShowOfTypeWihtMenuBar:(GWWMenuBar *)menuBar;
- (void)menuBarDidSelectedType:(GWWMenuBarType)type menuBar:(GWWMenuBar *)menuBar;

@end

@interface GWWMenuBar : UIView

@property (nonatomic, weak) id<GWWMenuBarDelegate> delegate;
@property (nonatomic, readonly, strong) UILabel *sizeLabel;
@property (nonatomic, strong) NSDictionary *userInfo;

@end

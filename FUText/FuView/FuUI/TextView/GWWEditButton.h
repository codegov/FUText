//
//  GWWEditButton.h
//  GroupWenWen
//
//  Created by javalong on 16/5/5.
//  Copyright © 2016年 evan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GWWEditButton : UIButton

@property (nonatomic, readonly, strong) UIView *editImageView;
@property (nonatomic, readonly, strong) UIButton *closeButton;
@property (nonatomic, strong) NSDictionary *userInfo;

@end

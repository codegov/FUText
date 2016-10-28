//
//  FUCameraRecordView.h
//  FUText
//
//  Created by javalong on 16/10/24.
//  Copyright © 2016年 javalong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUProgressBar.h"

@interface FUCameraRecordView : UIView

@property (nonatomic, readonly, strong) UIButton    *recordButton;
@property (nonatomic, readonly, strong) FUProgressBar *progressBar;
@property (nonatomic, readonly, strong) UIButton    *cancelButton;
@property (nonatomic, readonly, strong) UIButton    *okButton;

@property (nonatomic) BOOL enabled;
@property (nonatomic) BOOL isRecording;

@end

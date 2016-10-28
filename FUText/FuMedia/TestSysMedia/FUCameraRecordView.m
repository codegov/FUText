//
//  FUCameraRecordView.m
//  FUText
//
//  Created by javalong on 16/10/24.
//  Copyright © 2016年 javalong. All rights reserved.
//

#import "FUCameraRecordView.h"

@implementation FUCameraRecordView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor blackColor];
        
        CGFloat width  = 85;
        CGFloat height = 85;
        CGFloat bottomOff = 49.0;
        CGFloat y = frame.size.height - height - bottomOff;
        CGFloat x = (frame.size.width - width)/2.0;
        _recordButton = [[UIButton alloc] initWithFrame:CGRectMake(x, y, width, height)];
        _recordButton.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:129.0/255.0 blue:74.0/255.0 alpha:0.3];
        [_recordButton setImage:[UIImage imageNamed:@"FU_Camera_Record_Nor"] forState:UIControlStateNormal];
        _recordButton.layer.cornerRadius = _recordButton.bounds.size.height/2.0;
        _recordButton.layer.borderWidth = 2;
        _recordButton.layer.borderColor = [UIColor colorWithRed:251.0/255.0 green:114.0/255.0 blue:5.0/255.0 alpha:1].CGColor;
        
        [self addSubview:_recordButton];
        
        width  = 66.0;
        height = 32.0;
        x = 30.0;
        y = y + (_recordButton.frame.size.height - height)/2.0;
        UIColor *lColor = [UIColor grayColor];
        UIColor *dColor = [UIColor colorWithWhite:1 alpha:0.5];
        _cancelButton  = [[UIButton alloc] initWithFrame:CGRectMake(x, y, width, height)];
        [_cancelButton setTitle:@" 重拍" forState:UIControlStateNormal];
        [_cancelButton setTitleColor:dColor forState:UIControlStateDisabled];
        [_cancelButton setTitleColor:lColor forState:UIControlStateHighlighted];
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_cancelButton setImage:[UIImage imageNamed:@"FU_Camera_Cancel"] forState:UIControlStateNormal];
        _cancelButton.layer.cornerRadius = _cancelButton.bounds.size.height/2.0;
        _cancelButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
        [self addSubview:_cancelButton];
        
        x = frame.size.width - width - x;
        _okButton = [[UIButton alloc] initWithFrame:CGRectMake(x, y, width, height)];
        [_okButton setTitle:@" 使用" forState:UIControlStateNormal];
        [_okButton setTitleColor:dColor forState:UIControlStateDisabled];
        [_okButton setTitleColor:lColor forState:UIControlStateHighlighted];
        _okButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_okButton setImage:[UIImage imageNamed:@"FU_Camera_Ok"] forState:UIControlStateNormal];
        _okButton.layer.cornerRadius = _okButton.bounds.size.height/2.0;
        _okButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
        [self addSubview:_okButton];
        
        width  = frame.size.width;
        height = 2;
        x = 0;
        y = 0;
        _progressBar = [FUProgressBar getInstance];
        [_progressBar setLastProgressToStyle:ProgressBarProgressStyleNormal];
        _progressBar.frame = CGRectMake(x, y, width, height);
        _progressBar.intervalView.hidden = YES;
        _progressBar.progressIndicator.hidden = YES;
        [self addSubview:_progressBar];
        
    }
    return self;
}

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    
    _recordButton.enabled = enabled;
    _cancelButton.enabled = enabled;
    _okButton.enabled = enabled;
}

- (void)setIsRecording:(BOOL)isRecording
{
    _isRecording = isRecording;
    
    if (isRecording)
    {
        [_recordButton setImage:[UIImage imageNamed:@"FU_Camera_Record_Hli"] forState:UIControlStateNormal];
        _cancelButton.enabled = NO;
        _okButton.enabled = NO;
    } else
    {
        [_recordButton setImage:[UIImage imageNamed:@"FU_Camera_Record_Nor"] forState:UIControlStateNormal];
        _cancelButton.enabled = YES;
        _okButton.enabled     = YES;
    }
}

@end

//
//  FUCameraView.m
//  FUText
//
//  Created by javalong on 16/5/3.
//  Copyright © 2016年 javalong. All rights reserved.
//

@import AVFoundation;

#import "FUCameraView.h"

@implementation FUCameraView

+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session
{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    return previewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session
{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    previewLayer.session = session;
}


@end

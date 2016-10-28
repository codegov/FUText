//
//  FUCameraCapture.h
//  FUText
//
//  Created by javalong on 16/10/24.
//  Copyright © 2016年 javalong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FUCameraView.h"
@import AVFoundation;
@import Photos;

@class FUCameraCapture;

@protocol FUCameraCaptureDelegate <NSObject>

@optional

// 摄像头会话运行起来，才能录制
- (void)cameraCapture:(FUCameraCapture *)capture isSessionRunning:(BOOL)isSessionRunning;
// 摄像头录制
- (void)cameraCapture:(FUCameraCapture *)capture didStartRecordingToOutputFileAtURL:(NSURL *)fileURL;
- (void)cameraCapture:(FUCameraCapture *)capture didSuccessRecordingToOutputFileAtURL:(NSURL *)outputFileURL;
- (void)cameraCapture:(FUCameraCapture *)capture didFailRecordingToOutputFileAtURL:(NSURL *)outputFileURL;
- (void)cameraCapture:(FUCameraCapture *)capture didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)cameraCapture:(FUCameraCapture *)capture progressOfRecording:(CGFloat)progress;
// 改变摄像头方向：前置/后置
- (void)cameraCapture:(FUCameraCapture *)capture changeCaptureDevicePosition:(AVCaptureDevicePosition)position;
// 捕获到摄像头静态图片
- (void)cameraCapture:(FUCameraCapture *)capture captureStillImageWithImgData:(NSData *)imageData;

@end

@interface FUCameraCapture : NSObject

@property (nonatomic, weak) id<FUCameraCaptureDelegate> delegate;
@property (nonatomic, readonly, strong) FUCameraView *cameraView; // 捕获显示
@property (nonatomic, readonly) BOOL   isRecording;               // 是否正在录制
@property (nonatomic)           CMTime maxRecordedDuration; // 最大录制时间  默认:180秒，每秒20帧
@property (nonatomic, readonly) CMTime recordedDuration;    // 当前录制的时间

- (void)startRunningWithViewController:(UIViewController *)viewController; // 运行摄像头
- (void)stopRunning;                 // 停止运行摄像头

- (void)startRecording;              // 录制，如果正在录制，调用则停止录制；如果停止录制，调用则开始录制
- (void)stopRecording;               // 停止录制

- (void)changeCaptureDevicePosition; // 改变摄像头方向：前置/后置
- (void)asynCaptureStillImage;       // 异步捕获摄像头静态图片

- (void)clearCapture;                // 清空捕获的视频文件

@end

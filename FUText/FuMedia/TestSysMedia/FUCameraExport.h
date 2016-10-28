//
//  FUCameraExport.h
//  FUText
//
//  Created by javalong on 16/10/21.
//  Copyright © 2016年 javalong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@import Photos;
#import "FUCameraPreExport.h"

@interface FUCameraExport : NSObject

@property (nonatomic) BOOL    needSaveToPhone;           // 导出完成，保存视频到相册 默认 YES

/**
 *  method exportAsynchronouslyWithUrl  导出视频的方法
 *  @param url:视频路径
 *  @param presetName:AVAssetExportPresetMediumQuality
 *  @param timeRange:kCMTimeRangeZero
 *  @param completionHandler     导出状态回调
 *  @return
 */
- (void)exportAsynchronouslyWithUrl:(NSURL *)url completionHandler:(void (^)(AVAssetExportSession *exportSession))handler;
/**
 *  method exportAsynchronouslyWithPresetName  导出视频的方法
 *  @param presetName:AVAssetExportPresetMediumQuality
 *  @param timeRange:kCMTimeRangeZero
 *  @param preExport             预导出
 *  @param completionHandler     导出状态回调
 *  @return
 */
- (void)exportAsynchronouslyWithPreExport:(FUCameraPreExport *)preExport completionHandler:(void (^)(AVAssetExportSession *exportSession))handler;
/**
 *  method exportAsynchronouslyWithPresetName  导出视频的方法
 *  @param presetName 压缩可选类型
 
 AVAssetExportPresetLowQuality
 AVAssetExportPresetMediumQuality
 AVAssetExportPresetHighestQuality
 AVAssetExportPreset640x480
 AVAssetExportPreset960x540
 AVAssetExportPreset1280x720
 AVAssetExportPreset1920x1080
 AVAssetExportPreset3840x2160
 
 *  @param timeRange             视频剪切的时间范围，默认是kCMTimeRangeZero 不裁剪
 *  @param preExport             预导出
 *  @param completionHandler     导出状态回调
 *  @return
 */

- (void)exportAsynchronouslyWithPresetName:(NSString *)presetName timeRange:(CMTimeRange)timeRange preExport:(FUCameraPreExport *)preExport completionHandler:(void (^)(AVAssetExportSession *exportSession))handler;


- (void)cancelExport;

/**
 *  method saveToPhotoWithFileURL  将资源保存到相册
 *  @param outputFileURL 视频路径
 *  @param resourceType  资源类型
 *  @return
 */
+ (void)saveToPhotoWithFileURL:(NSURL *)fileURL resourceType:(PHAssetResourceType)resourceType;
+ (void)saveToPhotoWithImgData:(NSData *)imageData;




/**
 *  method getFileMD5 获取视频文件的MD5
 *  @return 返回MD5
 */
+ (NSString *)getFileMD5:(NSString*)path;
/**
 *  method getFileSize 获取文件的大小
 *  @return 返回的是单位是M
 */
+ (CGFloat)getFileSize:(NSString *)path;
/**
 *  method getVideoDuration 获取视频文件的时长
 *  @return 返回的是单位是s
 */
+ (CGFloat)getVideoDuration:(NSURL *)URL;
/**
 *  method formatSeconds 格式化时间去显示
 *  @return 返回的是单位是s
 */
+ (NSString *)formatSeconds:(Float64)seconds;
+ (NSString *)formatCMTime:(CMTime)time;
/*
 CMTimeMakeWithSeconds(第几秒, 帧率)。
 CMTime time1 = CMTimeMakeWithSeconds(1.0, 1000); 当前时间为1秒
 CMTimeMake(第几帧， 帧率）。
 这么看，CMTimeMake(32，16) 和 CMTimeMake(48, 24); 这两个都表示2秒的时间。但是帧率不同。
 CMTime time2 = CMTimeMake(1, 1000);当前时间为0.001秒
 */
+ (UIImage *)getFirstImageWithURL:(NSURL *)url;
+ (UIImage *)getImageWithURL:(NSURL *)url time:(CMTime)time;

@end

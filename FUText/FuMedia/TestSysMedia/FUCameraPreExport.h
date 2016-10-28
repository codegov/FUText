//
//  FUCameraPreExport.h
//  SFFmpegIOSTranscoder
//
//  Created by javalong on 16/10/26.
//  Copyright © 2016年 Lei Xiaohua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef enum {
    FUCameraPreExportTypeVideo  = 1 << 0,    // 视频
    FUCameraPreExportTypeAudio  = 1 << 1,    // 音频
} FUCameraPreExportType;


@interface FUCameraPreExport : NSObject

@property (nonatomic)           CMTime frameDuration;      // 视频每秒帧频数 默认 CMTimeMake(1, 20)
@property (nonatomic)           CGSize renderSize;         // 视频绘制大小   默认 CGSizeMake(480.0, 480.0)
@property (nonatomic, readonly) CGSize renderScaleSize;    // renderSize等比后视频绘制的大小
@property (nonatomic) BOOL      isScale;                   // 导出的视频是否等比例显示 默认 YES
@property (nonatomic) BOOL      isShowWater;               // 是否显示水印 默认 NO
@property (nonatomic, strong)   CALayer *custormWaterLayer;// 自定义水印 默认nil
@property (nonatomic, readonly) CMTimeRange  timeRane;     // 预导出后的时间段

/**
 *  method exportMovieWithUrl  预导出视频的方法
 *  @param preExportType:FUCameraPreExportTypeVideo | FUCameraPreExportTypeAudio
 *  @param needVideoComposition:YES
 *  @return
 */
- (void)exportMovieWithUrl:(NSURL *)url;
/**
 *  method exportMovieWithUrl     预导出视频的方法
 *  @param preExportType          预导出支持的类型
 *  @param needVideoComposition   是否需要发挥属性frameDuration、renderSize、isScale、isShowWater、custormWaterLayer的作用
 *  @return
 */
- (void)exportMovieWithUrl:(NSURL *)url preExportType:(FUCameraPreExportType)preExportType needVideoComposition:(BOOL)needVideoComposition;

- (void)cancelExportMovieWithUrl:(NSURL *)url;

/**
 *  method mergeExportWithUrl  预将音频合并到预导出视频的方法
 *  @param atTime:kCMTimeZero
 *  @param isAudioFitMoive:YES
 *  @param needOriginalAudio:NO
 *  @return
 */
- (void)mergeExportWithUrl:(NSURL *)url;
/**
 *  method mergeExportWithUrl  将URL合并到预导出视频的方法
 *  @param preExportType       合并支持的类型
 *  @param atTime  时间点，从这个时间点开始，将音频合并到预导出视频中
 *  @param isFitMoive        是否播放时长与预导出视频等长
 *  @param needOriginalAudio 是否需要播放预导出视频原始声音
 *  @return
 */
- (void)mergeExportWithUrl:(NSURL *)url preExportType:(FUCameraPreExportType)preExportType atTime:(CMTime)time isFitMoive:(BOOL)isFit needOriginalAudio:(BOOL)needOriginalAudio;

- (void)cancelMergeExportWithUrl:(NSURL *)url needOriginalAudio:(BOOL)needOriginalAudio;

// 预导出，生成的混合数据
@property (nonatomic, readonly, strong) AVComposition      *assetComposition;
@property (nonatomic, readonly, strong) AVVideoComposition *videoComposition;
@property (nonatomic, readonly, strong) AVAudioMix         *audioMix;

@end

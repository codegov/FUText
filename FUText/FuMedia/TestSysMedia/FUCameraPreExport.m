//
//  FUCameraPreExport.m
//  SFFmpegIOSTranscoder
//
//  Created by javalong on 16/10/26.
//  Copyright © 2016年 Lei Xiaohua. All rights reserved.
//

#import "FUCameraPreExport.h"
#import <UIKit/UIKit.h>

@interface FUCameraExportMeta : NSObject

// 针对exportMovie
@property (nonatomic) CMTime atTime;
//@property (nonatomic) CMTimeRange timeRange;
@property (nonatomic, strong) AVVideoCompositionLayerInstruction *layerInstruction;
@property (nonatomic, strong) AVMutableAudioMixInputParameters   *audioInputParam;

// 针对mergeExport
@property (nonatomic) CMTime duration;
@property (nonatomic, strong) AVCompositionTrack *videoCompositionTrack;
@property (nonatomic, strong) AVCompositionTrack *audioCompositionTrack;

@end

@implementation FUCameraExportMeta

@end

@interface FUCameraPreExport ()

@property (nonatomic, strong) NSMutableArray            *instructionList;
@property (nonatomic, strong) NSMutableArray            *inputParamList;

@property (nonatomic) CGFloat renderScale;
@property (nonatomic) CMTime  currentTime;      // 预导出后的时间

@property (nonatomic, strong) NSMutableDictionary *metaDataDictionary;

@end

@implementation FUCameraPreExport
{
    AVMutableComposition * __assetComposition;
    BOOL                   _haveOriginalAudio;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        __assetComposition  = [[AVMutableComposition alloc] init];
        _currentTime        = kCMTimeZero;
        _instructionList    = [[NSMutableArray alloc] init];
        _inputParamList     = [[NSMutableArray alloc] init];
        _metaDataDictionary = [[NSMutableDictionary alloc] init];

        _frameDuration   = CMTimeMake(1, 20);
        _renderSize      = CGSizeMake(480.0, 480.0);
        _renderScale     = 1.0;
        _isScale         = YES;
        _isShowWater     = NO;
    }
    return self;
}

- (NSString *)pathOfUrl:(NSURL *)url
{
    NSString *path = url.fileURL ? url.filePathURL.relativePath : url.absoluteString;
    return path;
}


// 预导出
- (void)exportMovieWithUrl:(NSURL *)url
{
    [self exportMovieWithUrl:url preExportType:(FUCameraPreExportTypeAudio | FUCameraPreExportTypeVideo) needVideoComposition:YES];
}

- (void)exportMovieWithUrl:(NSURL *)url preExportType:(FUCameraPreExportType)preExportType needVideoComposition:(BOOL)needVideoComposition
{
    NSString *path = [self pathOfUrl:url];
    if (!path.length) return;
    
    CMTime oldTime    = self.currentTime;
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    CMTime newTime    = asset.duration;
    _currentTime      = CMTimeAdd(oldTime, newTime);
    
    AVAssetTrack *audioTrack = nil;
    if (preExportType & FUCameraPreExportTypeAudio)
    {
        audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    }
    AVAssetTrack *videoTrack = nil;
    if (preExportType & FUCameraPreExportTypeVideo)
    {
        videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    }
    
    CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, newTime);
    
    FUCameraExportMeta *meta = [[FUCameraExportMeta alloc] init];
    meta.atTime   = oldTime;
    meta.duration = newTime;
    [_metaDataDictionary setObject:meta forKey:path];
    if (audioTrack)
    {
        AVMutableCompositionTrack *audioCompositionTrack = [__assetComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [audioCompositionTrack insertTimeRange:timeRange ofTrack:audioTrack atTime:oldTime error:nil];
        _haveOriginalAudio = YES;
        
        AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioCompositionTrack];
        [trackMix setVolume:1 atTime:oldTime];
        [trackMix setTrackID:audioTrack.trackID];
        [_inputParamList addObject:trackMix];
        meta.audioInputParam = trackMix;
        meta.audioCompositionTrack = audioCompositionTrack;
        
    }
    if (videoTrack)
    {
        AVMutableCompositionTrack *videoCompositionTrack = [__assetComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [videoCompositionTrack insertTimeRange:timeRange ofTrack:videoTrack atTime:oldTime error:nil];
        
        if (needVideoComposition)
        {
            meta.layerInstruction = [self addLayerInstructionWithVideoTrack:videoTrack videoCompositionTrack:videoCompositionTrack];
        }
        meta.videoCompositionTrack = videoCompositionTrack;
    }
}

- (void)cancelExportMovieWithUrl:(NSURL *)url
{
    NSString *path = [self pathOfUrl:url];
    if (!path.length) return;
    
    FUCameraExportMeta *meta = [_metaDataDictionary objectForKey:path];
    if (meta.audioCompositionTrack)
    {
        [__assetComposition removeTrack:meta.audioCompositionTrack];
    }
    if (meta.videoCompositionTrack)
    {
        [__assetComposition removeTrack:meta.videoCompositionTrack];
    }
    if (meta.layerInstruction)
    {
        [self.instructionList removeObject:meta.layerInstruction];
    }
    if (meta.audioInputParam)
    {
        [self.inputParamList removeObject:meta.audioInputParam];
    }
    _currentTime = CMTimeSubtract(_currentTime, meta.duration);
    [_metaDataDictionary removeObjectForKey:path];
}


- (void)mergeExportWithUrl:(NSURL *)url
{
    [self mergeExportWithUrl:url preExportType:(FUCameraPreExportTypeAudio | FUCameraPreExportTypeVideo) atTime:kCMTimeZero isFitMoive:YES needOriginalAudio:NO];
}

- (void)mergeExportWithUrl:(NSURL *)url preExportType:(FUCameraPreExportType)preExportType atTime:(CMTime)time isFitMoive:(BOOL)isFit needOriginalAudio:(BOOL)needOriginalAudio
{
    NSString *path = [self pathOfUrl:url];
    if (!path.length) return;
    
    FUCameraExportMeta *meta = [[FUCameraExportMeta alloc] init];
    meta.duration = self.currentTime;
    
    if (_haveOriginalAudio && !needOriginalAudio)
    {
        for (FUCameraExportMeta *oldMeta in _metaDataDictionary.allValues)
        {
            if (oldMeta.audioInputParam)
            {
                [oldMeta.audioInputParam setVolume:0 atTime:oldMeta.atTime];
            }
        }
        _haveOriginalAudio = NO;
    }
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    CMTime newTime    = self.currentTime;
    if (!isFit && CMTimeCompare(newTime, asset.duration) < 0)
    {
        newTime = asset.duration;
        _currentTime = newTime;
    }
    
    AVAssetTrack *audioTrack = nil;
    AVAssetTrack *videoTrack = nil;
    
    if (preExportType & FUCameraPreExportTypeAudio)
    {
        audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    }
    if (preExportType & FUCameraPreExportTypeVideo)
    {
        videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    }
    
    if (audioTrack)
    {
        AVMutableCompositionTrack *audioCompositionTrack = [__assetComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, newTime) ofTrack:audioTrack atTime:time error:nil];
        
        meta.audioCompositionTrack = audioCompositionTrack;
    }
    if (videoTrack)
    {
        AVMutableCompositionTrack *videoCompositionTrack = [__assetComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, newTime) ofTrack:videoTrack atTime:time error:nil];
        
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [self addLayerInstructionWithVideoTrack:videoTrack videoCompositionTrack:videoCompositionTrack];
        [layerInstruction setOpacity:0.5 atTime:time];
        meta.layerInstruction      = layerInstruction;
        
        meta.videoCompositionTrack = videoCompositionTrack;
    }

    [_metaDataDictionary setObject:meta forKey:path];
}

- (void)cancelMergeExportWithUrl:(NSURL *)url needOriginalAudio:(BOOL)needOriginalAudio
{
    if (needOriginalAudio && !_haveOriginalAudio)
    {
        for (FUCameraExportMeta *oldMeta in _metaDataDictionary.allValues)
        {
            if (oldMeta.audioInputParam)
            {
                [oldMeta.audioInputParam setVolume:1 atTime:oldMeta.atTime];
            }
        }
    }
    NSString *path = [self pathOfUrl:url];
    if (!path.length) return;
    
    FUCameraExportMeta *meta = [_metaDataDictionary objectForKey:path];
    if (meta.audioCompositionTrack)
    {
        [__assetComposition removeTrack:meta.audioCompositionTrack];
    }
    if (meta.videoCompositionTrack)
    {
        [__assetComposition removeTrack:meta.videoCompositionTrack];
    }
    if (meta.layerInstruction)
    {
        [self.instructionList removeObject:meta.layerInstruction];
    }
    _currentTime = meta.duration;
    [_metaDataDictionary removeObjectForKey:path];
}





- (AVMutableVideoCompositionLayerInstruction *)addLayerInstructionWithVideoTrack:(AVAssetTrack *)videoTrack videoCompositionTrack:(AVCompositionTrack *)compositionTrack
{
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionTrack];
    
    BOOL isScale       = self.isScale;
    CGFloat videoOffY  = 0.0;
    CGFloat videoOffX  = 0.0;
    CGSize naturalSize = videoTrack.naturalSize;
    CGSize renderSize  = self.renderSize;
    UIImageOrientation imageOrientation = UIImageOrientationUp;
    CGAffineTransform mixedTransform    = CGAffineTransformIdentity;
    
    CGAffineTransform t = videoTrack.preferredTransform;
    if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0)
    {
        imageOrientation = UIImageOrientationRight;
    } else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)
    {
        imageOrientation = UIImageOrientationLeft;
    } else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0)
    {
        imageOrientation = UIImageOrientationUp;
    } else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0)
    {
        imageOrientation = UIImageOrientationDown;
    }
    
    if (isScale)
    {
        if (imageOrientation == UIImageOrientationRight || imageOrientation == UIImageOrientationLeft)
        {
            naturalSize = CGSizeMake(naturalSize.height, naturalSize.width);
        }
        renderSize = CGSizeMake(renderSize.width, renderSize.width * naturalSize.height/naturalSize.width);
    } else
    {
        if (renderSize.height < renderSize.width)
        {
            videoOffX = -(renderSize.width - renderSize.height)/2.0;
        } else
        {
            videoOffY = (renderSize.height - renderSize.width)/2.0;
        }
    }
    
    CGFloat widthScale  = renderSize.width/naturalSize.width;
    CGFloat heightScale = renderSize.height/naturalSize.height;
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(widthScale, heightScale);
    
    if (imageOrientation == UIImageOrientationRight)
    {
//        NSLog(@"视频旋转90度,home按键在左");
        mixedTransform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(renderSize.width + videoOffX, videoOffY), M_PI_2);
    } else if (imageOrientation == UIImageOrientationLeft)
    {
//        NSLog(@"视频旋转270度，home按键在右");
        mixedTransform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(videoOffX, renderSize.height + videoOffY), M_PI_2*3.0);
    } else if (imageOrientation == UIImageOrientationDown)
    {
//        NSLog(@"视频旋转180度，home按键在上");
        mixedTransform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(renderSize.width + videoOffX, renderSize.height + videoOffY), M_PI);
    }
    
    if (CGAffineTransformIsIdentity(mixedTransform))
    {
        [layerInstruction setTransform:CGAffineTransformConcat(videoTrack.preferredTransform, scaleTransform) atTime:kCMTimeZero];
    } else
    {
        [layerInstruction setTransform:CGAffineTransformConcat(scaleTransform, mixedTransform) atTime:kCMTimeZero];
    }
    
    _renderScaleSize = renderSize;
    [self.instructionList insertObject:layerInstruction atIndex:0];
    
    return layerInstruction;
}


- (CMTimeRange)timeRane
{
    return CMTimeRangeMake(kCMTimeZero, _currentTime);
}

- (AVComposition *)assetComposition
{
    return __assetComposition;
}

- (AVAudioMix *)audioMix
{
    AVMutableAudioMix *audioM = nil;
    if (_inputParamList.count)
    {
        audioM = [AVMutableAudioMix audioMix];
        audioM.inputParameters = _inputParamList;
    }
    return audioM;
}

- (AVVideoComposition *)videoComposition
{
    if (!self.instructionList.count) return nil;
    
    AVMutableVideoCompositionInstruction * instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.currentTime);
    instruction.layerInstructions = self.instructionList;
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions  = [NSArray arrayWithObject:instruction];
    videoComposition.frameDuration = self.frameDuration;  // 设置每秒帧频数
    videoComposition.renderSize    = self.renderScaleSize;// 设置视频的大小
    videoComposition.renderScale   = self.renderScale;
    if (self.isShowWater)
    {
        videoComposition.animationTool = [[self class] buildAnimationToolWithVideoSize:self.renderScaleSize custromLayer:self.custormWaterLayer]; // 水印
    }
    return videoComposition;
}

+ (AVVideoCompositionCoreAnimationTool *)buildAnimationToolWithVideoSize:(CGSize)videoSize custromLayer:(CALayer *)custromLayer
{
    // 水印
    CALayer *waterLayer = [CALayer layer];
    waterLayer.frame = CGRectMake(0.0, 0.0, videoSize.width, videoSize.height);
    waterLayer.backgroundColor = [UIColor clearColor].CGColor;
    if (!custromLayer)
    {
        // logo
        UIImage *logo = [UIImage imageNamed:@"logo"];
        CALayer *logoLayer = [CALayer layer];
        logoLayer.contents = (id)logo.CGImage ;
        logoLayer.frame = CGRectMake(15, waterLayer.bounds.size.height - logo.size.height - 15, logo.size.width, logo.size.height);
        logoLayer.opacity = 0.6f;
        // 文字
        CATextLayer *textLayer = [CATextLayer layer];
        textLayer.string = @"略懂";
        textLayer.font = (__bridge CFTypeRef)(@"Helvetica");
        textLayer.fontSize = 18.0f;
        textLayer.alignmentMode = @"center";
        textLayer.shadowOpacity = 0.6f ;
        textLayer.backgroundColor = [UIColor clearColor].CGColor ;
        textLayer.foregroundColor = [UIColor whiteColor].CGColor ;
        textLayer.frame = CGRectMake(15.0f, logoLayer.frame.origin.y - 25.0, logoLayer.frame.size.width, 20.0f);
        [waterLayer addSublayer:logoLayer];
        [waterLayer addSublayer:textLayer];
    } else
    {
        [waterLayer addSublayer:custromLayer];
    }
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer  = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame  = CGRectMake(0, 0, videoSize.width, videoSize.height);
    
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:waterLayer];
    AVVideoCompositionCoreAnimationTool *animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    return animationTool;
}

@end

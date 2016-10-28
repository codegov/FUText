//
//  FUCameraExport.m
//  FUText
//
//  Created by javalong on 16/10/21.
//  Copyright © 2016年 javalong. All rights reserved.
//

#import "FUCameraExport.h"
#include <CommonCrypto/CommonDigest.h>

#define GWWFileHashDefaultChunkSizeForReadingData 1024*8

@interface FUCameraExport ()

@property (nonatomic) float   progress;

@property (nonatomic, strong) AVAssetExportSession *exporter;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic) void (^exportBlock)(AVAssetExportSession *exportSession) ;


@end

@implementation FUCameraExport

- (void)dealloc
{
    [self cancelExport];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _needSaveToPhone = YES;
    }
    return self;
}

- (void)exportAsynchronouslyWithUrl:(NSURL *)url completionHandler:(void (^)(AVAssetExportSession *exportSession))handler
{
    FUCameraPreExport *preExport = [[FUCameraPreExport alloc] init];
    [preExport exportMovieWithUrl:url];
    [self exportAsynchronouslyWithPresetName:AVAssetExportPresetMediumQuality timeRange:kCMTimeRangeZero preExport:preExport completionHandler:handler];
}

- (void)exportAsynchronouslyWithPreExport:(FUCameraPreExport *)preExport completionHandler:(void (^)(AVAssetExportSession *exportSession))handler
{
    [self exportAsynchronouslyWithPresetName:AVAssetExportPresetMediumQuality timeRange:kCMTimeRangeZero preExport:preExport completionHandler:handler];
}

- (void)exportAsynchronouslyWithPresetName:(NSString *)presetName timeRange:(CMTimeRange)timeRange preExport:(FUCameraPreExport *)preExport completionHandler:(void (^)(AVAssetExportSession *exportSession))handler
{
    if (self.exporter)
    {
        [self cancelExport];
    }
    presetName = presetName.length ? presetName : AVAssetExportPresetMediumQuality;
    
    BOOL isPassthrough = [presetName isEqualToString:AVAssetExportPresetPassthrough];
    NSURL *url = [NSURL fileURLWithPath:[[self class] getPathWithName:@"moive.mp4"]];
    NSLog(@"url===%@", url.absoluteString);
    self.exporter = [[AVAssetExportSession alloc] initWithAsset:preExport.assetComposition presetName:presetName];
    self.exporter.outputURL        = url;
    self.exporter.outputFileType   = isPassthrough ? AVFileTypeQuickTimeMovie : AVFileTypeMPEG4;
    if (!isPassthrough)
    {
        self.exporter.videoComposition = preExport.videoComposition;
    }
    self.exporter.audioMix = preExport.audioMix;
    if (!CMTimeRangeEqual(kCMTimeRangeZero, timeRange))
    {
        self.exporter.timeRange = timeRange;
    }
    self.exporter.shouldOptimizeForNetworkUse = YES;
    self.exportBlock = handler;
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(doAction:)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    __weak typeof(&*self)weakSelf = self;
    [self.exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            FUCameraExport *c = weakSelf;
            if (c.exporter.status == AVAssetExportSessionStatusCompleted || c.exporter.status == AVAssetExportSessionStatusFailed || c.exporter.status == AVAssetExportSessionStatusCancelled || c.exporter.status == AVAssetExportSessionStatusUnknown)
            {
                if (c.exporter.status == AVAssetExportSessionStatusCompleted)
                {
                    [c saveToPhotoWithFileURL:c.exporter.outputURL];
                }
                [c cancelExport];
            }
            if (c.exportBlock) c.exportBlock(c.exporter);
        });
    }];

}

- (void)doAction:(CADisplayLink *)sender
{
    if (_progress == self.exporter.progress) return;
    _progress = self.exporter.progress;
    FUCameraExport *c = self;
    if (c.exporter.status == AVAssetExportSessionStatusCompleted || c.exporter.status == AVAssetExportSessionStatusFailed || c.exporter.status == AVAssetExportSessionStatusCancelled || c.exporter.status == AVAssetExportSessionStatusUnknown)
    {
        
    } else
    {
        if (self.exportBlock) self.exportBlock(self.exporter);
    }
}

- (void)cancelExport
{
    [self.exporter cancelExport];
    _progress = 0;
    if (_displayLink)
    {
        _displayLink.paused = YES;
        [_displayLink invalidate];
        _displayLink = nil;
    }
}

+ (NSString *)getPathWithName:(NSString *)name
{
    NSString *doc =  [NSHomeDirectory() stringByAppendingFormat:@"/Documents/GWWCompressionVideo"];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isExists = [manager fileExistsAtPath:doc];
    if (!isExists)
    {
        [manager createDirectoryAtPath:doc withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *resultPath = [doc stringByAppendingPathComponent:name];
    [manager removeItemAtPath:resultPath error:nil];
    return resultPath;
}

- (void)saveToPhotoWithFileURL:(NSURL *)fileURL
{
    if (!_needSaveToPhone) return;
    [FUCameraExport saveToPhotoWithFileURL:fileURL resourceType:PHAssetResourceTypeVideo];
}

+ (void)saveToPhotoWithFileURL:(NSURL *)fileURL resourceType:(PHAssetResourceType)resourceType
{
    [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
        if ( status == PHAuthorizationStatusAuthorized )
        {
            // Save the movie file to the photo library and cleanup.
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                // In iOS 9 and later, it's possible to move the file into the photo library without duplicating the file data.
                // This avoids using double the disk space during save, which can make a difference on devices with limited free disk space.
                if ([PHAssetResourceCreationOptions class])
                {
                    PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                    options.shouldMoveFile = NO;
                    PHAssetCreationRequest *changeRequest = [PHAssetCreationRequest creationRequestForAsset];
                    [changeRequest addResourceWithType:resourceType fileURL:fileURL options:options];
                } else
                {
                    if (resourceType == PHAssetResourceTypeVideo)
                    {
                        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL];
                    } else if (resourceType == PHAssetMediaTypeImage)
                    {
                        [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:fileURL];
                    }
                    
                }
            } completionHandler:^( BOOL success, NSError *error ) {
                if (!success )
                {
                    NSLog( @"Could not save movie to photo library: %@", error );
                }
            }];
        } else
        {
            
        }
    }];
}

+ (void)saveToPhotoWithImgData:(NSData *)imageData
{
    [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
        if ( status == PHAuthorizationStatusAuthorized ) {
            // To preserve the metadata, we create an asset from the JPEG NSData representation.
            // Note that creating an asset from a UIImage discards the metadata.
            // In iOS 9, we can use -[PHAssetCreationRequest addResourceWithType:data:options].
            // In iOS 8, we save the image to a temporary file and use +[PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:].
            if ([PHAssetCreationRequest class])
            {
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];
                } completionHandler:^( BOOL success, NSError *error ) {
                    if ( ! success ) {
                        NSLog( @"Error occurred while saving image to photo library: %@", error );
                    }
                }];
            } else
            {
                NSString *temporaryFileName = [NSProcessInfo processInfo].globallyUniqueString;
                NSString *temporaryFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[temporaryFileName stringByAppendingPathExtension:@"jpg"]];
                NSURL *temporaryFileURL = [NSURL fileURLWithPath:temporaryFilePath];
                
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    NSError *error = nil;
                    [imageData writeToURL:temporaryFileURL options:NSDataWritingAtomic error:&error];
                    if (error) {
                        NSLog( @"Error occured while writing image data to a temporary file: %@", error );
                    } else {
                        [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:temporaryFileURL];
                    }
                } completionHandler:^( BOOL success, NSError *error ) {
                    if ( ! success ) {
                        NSLog( @"Error occurred while saving image to photo library: %@", error );
                    }
                    // Delete the temporary file.
                    [[NSFileManager defaultManager] removeItemAtURL:temporaryFileURL error:nil];
                }];
            }
        }
    }];
}










//获取文件的大小，返回的是单位是M。
+ (CGFloat)getFileSize:(NSString *)path
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    float filesize = -1.0;
    if ([fileManager fileExistsAtPath:path]) {
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:nil];//获取文件的属性
        NSLog(@"fileDic===%@", fileDic);
        unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
        filesize = 1.0*size/1024 / 1024;
    }
    return filesize;
}

//获取视频文件的时长，返回的是单位是s。
+ (CGFloat)getVideoDuration:(NSURL *)URL
{
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:URL options:opts];
    CGFloat second = urlAsset.duration.value/urlAsset.duration.timescale;
    return second;
}

// 格式化时间去显示
+ (NSString *)formatSeconds:(Float64)seconds
{
    NSInteger t = ceil(seconds);
    NSInteger h = t/3600;
    NSString *hv = h < 10 ? [@"0" stringByAppendingString:@(h).stringValue] : @(h).stringValue;
    t = t%3600;
    NSInteger m = t/60;
    NSString *mv = m < 10 ? [@"0" stringByAppendingString:@(m).stringValue] : @(m).stringValue;
    NSInteger s = t%60;
    NSString *sv = s < 10 ? [@"0" stringByAppendingString:@(s).stringValue] : @(s).stringValue;
    //    NSInteger ms = (NSInteger)(seconds * 1000)%1000;
    //    NSString *msv = ms < 10 ? [@"0" stringByAppendingString:@(ms).stringValue] : @(ms).stringValue;
    
    return [NSString stringWithFormat:@"%@:%@:%@", hv, mv, sv];
}
+ (NSString *)formatCMTime:(CMTime)time
{
    return [[self class] formatSeconds:CMTimeGetSeconds(time)];
}

//获取视频文件的MD5
+ (NSString*)getFileMD5:(NSString*)path
{
    return (__bridge_transfer NSString *)FileMD5HashCreateWithPath((__bridge CFStringRef)path, GWWFileHashDefaultChunkSizeForReadingData);
}

static CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath,size_t chunkSizeForReadingData) {
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    if (!fileURL) goto done;
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = GWWFileHashDefaultChunkSizeForReadingData;
    }
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,(UInt8 *)buffer,(CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    // Abort if the read operation failed
    if (!didSucceed) goto done;
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,(const char *)hash,kCFStringEncodingUTF8);
    
done:
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}


+ (UIImage *)getFirstImageWithURL:(NSURL *)url
{
    if (!url) return nil;
    
    AVAssetTrack *videoTrack = nil;
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    Float64 durationSeconds = CMTimeGetSeconds(asset.duration);
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if ([videoTracks count] > 0)
        videoTrack = [videoTracks objectAtIndex:0];
    
    CGSize trackDimensions = [videoTrack naturalSize];
    
    int width = trackDimensions.width;
    int height = trackDimensions.height;
    NSLog(@"Resolution = %d X %d",width ,height);
    float frameRate = [videoTrack nominalFrameRate];//获取帧率
    frameRate = frameRate <= 0 ? 600 : frameRate;
    float bps = [videoTrack estimatedDataRate];//获取比特率
    NSLog(@"Frame rate == %f",frameRate);
    NSLog(@"bps rate == %f",bps);
    
    return [self getImageWithURL:url time:CMTimeMake(durationSeconds/2.0, frameRate)];
}

+ (UIImage *)getImageWithURL:(NSURL *)url time:(CMTime)time
{
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;//按正确方向对视频进行截图,关键点是将AVAssetImageGrnerator对象的appliesPreferredTrackTransform属性设置为YES。
    NSError *error    = nil;
    CMTime actualTime = kCMTimeZero;
    CGImageRef halfWayImage = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *image = nil;
    if (halfWayImage != NULL)
    {
        CFStringRef stringRef = CMTimeCopyDescription(NULL, actualTime);
        NSString *actualTimeString = (__bridge NSString *)stringRef;
        CFBridgingRelease(stringRef);
        
        CFStringRef stringRef2 = CMTimeCopyDescription(NULL, time);
        NSString *requestedTimeString = (__bridge NSString *)stringRef2;
        CFBridgingRelease(stringRef2);
        
        NSLog(@"Got halfWayImage: Asked for %@, got %@", requestedTimeString, actualTimeString);
        
        image = [UIImage imageWithCGImage:halfWayImage];
        // Do something interesting with the image.
        CGImageRelease(halfWayImage);
    }
    
    [self saveImage:image name:@"output.png"];
    
    return image;
}

+ (void)saveImage:(UIImage *)image name:(NSString *)name
{
    NSString *resultPath = [self getPathWithName:name];
    NSData *imgData = UIImagePNGRepresentation(image);
    [imgData writeToFile:resultPath atomically:YES];
}

+ (void)getAudioInfoWithAudioUrl:(NSURL *)audioUrl
{
    AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audioUrl options:nil];
    [audioAsset loadValuesAsynchronouslyForKeys:@[@"commonMetadata"] completionHandler:^{
        // 获取数据
        NSArray *artworks = [AVMetadataItem metadataItemsFromArray:audioAsset.commonMetadata
                                                           withKey:AVMetadataCommonKeyArtwork
                                                          keySpace:AVMetadataKeySpaceCommon];
        NSInteger i = 0;
        for (AVMetadataItem *item in artworks)
        {
            i++;
            if ([item.keySpace isEqualToString:AVMetadataKeySpaceID3])
            {
                NSDictionary *dict = [item.value copyWithZone:nil];
                UIImage  *image = [UIImage imageWithData:[dict objectForKey:@"data"]];
                [self saveImage:image name:[NSString stringWithFormat:@"output_%@.png", @(i)]];
            }
            if ([item.keySpace isEqualToString:AVMetadataKeySpaceiTunes])
            {
                UIImage *image = [UIImage imageWithData:[item.value copyWithZone:nil]];
                [self saveImage:image name:[NSString stringWithFormat:@"output_%@.png", @(i)]];
            }
        }
    }];
    
    NSLog(@"commonMetadata===%@", [audioAsset commonMetadata]);
    
    NSInteger i = 100;
    for (NSString *format in [audioAsset availableMetadataFormats])
    {
        i ++;
        NSLog(@"formatString: %@",format);
        for (AVMetadataItem *metadataitem in [audioAsset metadataForFormat:format])
        {
            NSLog(@"commonKey = %@",metadataitem.commonKey);
            if ([metadataitem.commonKey isEqualToString:@"artwork"])
            {
                NSData *data = [(NSDictionary *)metadataitem.value objectForKey:@"data"];
                NSString *mime = [(NSDictionary *)metadataitem.value objectForKey:@"MIME"];
                [self saveImage:[UIImage imageWithData:data] name:[NSString stringWithFormat:@"output_%@__.png", @(i)]];
                NSLog(@"mime: %@",mime);
                break;
            }
            else if([metadataitem.commonKey isEqualToString:@"title"])
            {
                NSString *title = (NSString *)metadataitem.value;
                NSLog(@"title: %@",title);
            }
            else if([metadataitem.commonKey isEqualToString:@"artist"])
            {
                NSString *artist = (NSString *)metadataitem.value;
                NSLog(@"artist: %@",artist);
            }
            else if([metadataitem.commonKey isEqualToString:@"albumName"])
            {
                NSString *albumName = (NSString *)metadataitem.value;
                NSLog(@"albumName: %@",albumName);
            }
        }
    }
    CMTime durationTime = audioAsset.duration;
    CGFloat duration = CMTimeGetSeconds(durationTime);
    NSLog(@"音频总时间：%f",duration);
}







// 备注 不公开 不使用
+ (void)exportAsynchronouslyMergeWithAudioUrl:(NSURL *)audioUrl videoUrl:(NSURL *)videoUrl completionHandler:(void (^)(AVAssetExportSession *exportSession))handler
{
    AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audioUrl options:nil];
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:videoUrl options:nil];
    
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *cAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                         preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *cVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                         preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *audioTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    AVAssetTrack *videoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    [cAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:audioTrack atTime:kCMTimeZero error:nil];
    [cVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
    
    AVAssetExportSession* exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                           presetName:AVAssetExportPresetPassthrough];
    NSString *resultPath = [self getPathWithName:@"mergeAudioToVideo.mp4"];
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;//合成成功 //AVFileTypeAppleM4V;//失败  AVFileTypeMPEG4;//合成失败
    exportSession.outputURL = [NSURL fileURLWithPath:resultPath];
    exportSession.shouldOptimizeForNetworkUse = YES;
    NSLog(@"开始合成");
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void ) {
        if (handler) handler(exportSession);
    }];
}

@end

//
//  TestGPPlayViewController.m
//  FUText
//
//  Created by javalong on 16/5/18.
//  Copyright © 2016年 javalong. All rights reserved.
//

#import "TestGPPlayViewController.h"
#import "GPUImage.h"
#import "GPUImageMovieEx.h"

@implementation TestGPPlayViewController
{
    GPUImageMovieEx *movieFile;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
    NSTimer * timer;
    
    UIButton *_recordButton;
    UIButton *_nextButton;
    GPUImageView *previewView;
    UISlider *slider;
    
    AVPlayer *mainPlayer;
    AVPlayerItem *playerItem;
    
    CMTime pausedTime;
    
    BOOL isPlaying;
}

- (void)dealloc
{
    NSLog(@"dealloc===");
    [self clear];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    self.view.backgroundColor = [UIColor whiteColor];
    // UI
    float bottomHeight = 216.0;
    previewView = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height - bottomHeight - 64)];
    previewView.backgroundColor = [UIColor brownColor];
    previewView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    [self.view addSubview:previewView];
    
    float y = previewView.frame.size.height + previewView.frame.origin.y;
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0.0, y, self.view.frame.size.width, bottomHeight)];
    bottomView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.25];
    [self.view addSubview:bottomView];
    
    float width = 100.0;
    y = bottomView.frame.size.height/2.0 - width/2.0;
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(bottomView.frame.size.width/2.0 - width/2.0, y, width, width)];
    [button setTitle:@"播放" forState:UIControlStateNormal];
    button.layer.cornerRadius = width/2.0;
    button.layer.masksToBounds = YES;
    button.layer.borderWidth = 1;
    button.layer.borderColor = [UIColor whiteColor].CGColor;
    [button addTarget:self action:@selector(startPlaying:) forControlEvents:UIControlEventTouchUpInside];
    button.backgroundColor = [UIColor blueColor];
    [bottomView addSubview:button];
    
    _recordButton = button;
    
    width = 80.0;
    _nextButton = [[UIButton alloc] initWithFrame:CGRectMake(bottomView.frame.size.width - width - 10.0, bottomView.frame.size.height/2.0 - width/2.0, width, width)];
    [_nextButton setTitle:@"下一步" forState:UIControlStateNormal];
    [_nextButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [_nextButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [_nextButton addTarget:self action:@selector(compactMovie:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:_nextButton];
    
    y = bottomView.frame.size.height - 40.0;
    slider = [[UISlider alloc] initWithFrame:CGRectMake(10.0, y, bottomView.frame.size.width - 20.0, 40.0)];
    slider.maximumValue = 100;
    slider.minimumValue = 1;
    [slider addTarget:self action:@selector(updatePixelWidth:) forControlEvents:UIControlEventValueChanged];
    [bottomView addSubview:slider];
    
    [self loadPlayTool];
}

- (void)loadPlayTool
{
    pausedTime = kCMTimeZero;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    mainPlayer = [[AVPlayer alloc] init];
    
    playerItem = [[AVPlayerItem alloc] initWithURL:_url];
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];// 监听status属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)clear
{
    if (playerItem)
    {
        [playerItem removeObserver:self forKeyPath:@"status"];
        [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        playerItem = nil;
    }
}

- (void)loadGPTool
{
    [mainPlayer replaceCurrentItemWithPlayerItem:playerItem];
    
    movieFile  = [[GPUImageMovieEx alloc] initWithPlayerItem:playerItem];//[[GPUImageMovie alloc] initWithURL:_url];
    movieFile.runBenchmark = YES;
    movieFile.playAtActualSpeed = YES;
    movieFile.shouldRepeat = YES;
    movieFile.presetSize = CGSizeMake(480, 640);
    // 滤镜
    // filter = [[GPUImagePixellateFilter alloc] init];
    // filter = [[GPUImageUnsharpMaskFilter alloc] init];
    filter = [[GPUImageSepiaFilter alloc] init];
    [filter addTarget:previewView];
    [movieFile addTarget:filter];
    
    // 输出
//    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/PlayMovie.m4v"];
//    unlink([pathToMovie UTF8String]);
//    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
//    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:previewView.bounds.size];
//    // Configure this for video from the movie file, where we want to preserve all video frames and audio samples
//    movieWriter.shouldPassthroughAudio = YES;
//
//    [filter addTarget:movieWriter];
//    
//    movieFile.audioEncodingTarget = movieWriter;
//    [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
}

- (void)playbackFinished:(NSNotification *)notification
{
    [self end];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    AVPlayerItem *playerItem1 = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"])
    {
        if ([playerItem1 status] == AVPlayerStatusReadyToPlay)
        {
            NSLog(@"AVPlayerStatusReadyToPlay");
            CMTime duration = playerItem1.duration;// 获取视频总长度
            CGFloat totalSecond = playerItem1.duration.value / playerItem1.duration.timescale;// 转换成秒
            NSString *totalTime = [self convertTime:totalSecond];// 转换成播放时间
            NSLog(@"播放时间==%@", totalTime);
            NSLog(@"movie total duration:%f",CMTimeGetSeconds(duration));
        } else if ([playerItem status] == AVPlayerStatusFailed)
        {
            NSLog(@"AVPlayerStatusFailed");
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
        NSLog(@"Time Interval:%f",timeInterval);
        CMTime duration = playerItem1.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        float progress = timeInterval / totalDuration;
        NSLog(@"计算缓冲进度==%@", @(progress).stringValue);
    }
}

- (void)end
{
    isPlaying = NO;
    NSLog(@"==end==");
    [self changePlayButtonWithPasue:YES];
    pausedTime = kCMTimeZero;
    [movieFile cancelProcessing];
}

- (void)pasue
{
    isPlaying = NO;
    NSLog(@"==pasue==");
    [mainPlayer pause];
    
    if (CMTimeCompare(pausedTime, mainPlayer.currentItem.asset.duration)) {
        pausedTime = mainPlayer.currentTime;
    } else {
        pausedTime = kCMTimeZero;
    }
    
    // [movieWriter setPaused:YES];
    [movieFile cancelProcessing];
}

- (void)play
{
    isPlaying = YES;
    [self loadGPTool];
    if (CMTimeCompare(pausedTime, mainPlayer.currentItem.asset.duration) != 0) {
        [mainPlayer seekToTime:pausedTime];
    }
    [mainPlayer play];
    NSLog(@"==play==");
    // [movieWriter setPaused:NO];
    // [movieWriter startRecording];
    [movieFile startProcessing];
}

- (void)startPlaying:(UIButton *)sender
{
    BOOL pause = sender && isPlaying;
    sender.transform = CGAffineTransformMakeScale(0.75, 0.75);
    [UIView animateWithDuration:0.25 animations:^{
        sender.transform = CGAffineTransformMakeScale(1, 1);
        [self changePlayButtonWithPasue:pause];
    }];
    if (pause)
    {
        [self pasue];
    } else
    {
        [self play];
    }
}

- (void)changePlayButtonWithPasue:(BOOL)pasue
{
    if (pasue)
    {
        [_recordButton setTitle:@"播放" forState:UIControlStateNormal];
        _recordButton.backgroundColor = [UIColor blueColor];
    } else
    {
        [_recordButton setTitle:@"暂停" forState:UIControlStateNormal];
        _recordButton.backgroundColor = [UIColor redColor];
    }
}

- (void)compactMovie:(UIButton *)sender
{
   
}

- (void)updatePixelWidth:(id)sender
{
    [(GPUImageSepiaFilter *)filter setIntensity:[(UISlider *)sender value]];
    //    [(GPUImageUnsharpMaskFilter *)filter setIntensity:[(UISlider *)sender value]];
    //    [(GPUImagePixellateFilter *)filter setFractionalWidthOfAPixel:[(UISlider *)sender value]];
}

- (NSTimeInterval)availableDuration
{
    NSArray *loadedTimeRanges = [[mainPlayer currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

- (NSString *)convertTime:(CGFloat)second
{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (second/3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [formatter stringFromDate:d];
    return showtimeNew;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end

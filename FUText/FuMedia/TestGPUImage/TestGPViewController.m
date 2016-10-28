//
//  TestGPViewController.m
//  FUText
//
//  Created by javalong on 16/5/18.
//  Copyright © 2016年 javalong. All rights reserved.
//

#import "TestGPViewController.h"
#import <AssetsLibrary/ALAssetsLibrary.h>
#import "GPUImageMovieWriterEx.h"
#import "FuMoviePlayerController.h"
#import "TestGPPlayViewController.h"

#import "FUProgressBar.h"
#import "DeleteButton.h"

@interface TestGPViewController ()<GPUImageVideoCameraDelegate>

@end

@implementation TestGPViewController
{
    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriterEx *movieWriter;
    
    NSTimer *_timer;
    NSTimeInterval _totalTime;
    NSTimeInterval _time;
    NSDate *_beginDate;
    
    Float64 _currentTime;
    NSMutableArray *_timeArray;
    
    NSURL *movieURL;
    
    UIButton *_recordButton;
    UIButton *_nextButton;
    FUProgressBar  *_progressBar;
    DeleteButton *_deleteButton;
    
    GPUImageView *previewView;
}

- (void)doTestAction
{
    [videoCamera rotateCamera];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    _totalTime = 60;
    _timeArray = [[NSMutableArray alloc] init];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem *rightBar = [[UIBarButtonItem alloc] initWithTitle:@"TEST" style:UIBarButtonItemStylePlain target:self action:@selector(doTestAction)];
    self.navigationItem.rightBarButtonItems = @[rightBar];
    
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
    
    _progressBar = [FUProgressBar getInstance];
    CGRect frame = _progressBar.frame;
    frame.origin.y = y;
    _progressBar.frame = frame;
    [self.view addSubview:_progressBar];
    
    _deleteButton = [DeleteButton getInstance];
    [_deleteButton setButtonStyle:DeleteButtonStyleDisable];
    [_deleteButton addTarget:self action:@selector(pressDeleteButton) forControlEvents:UIControlEventTouchUpInside];
    frame = _deleteButton.frame;
    frame.origin.x = 15.0;
    frame.origin.y = (bottomView.frame.size.height - frame.size.height)/2.0;
    [bottomView addSubview:_deleteButton];
    
    float width = 100.0;
    y = bottomView.frame.size.height/2.0 - width/2.0;
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(bottomView.frame.size.width/2.0 - width/2.0, y, width, width)];
    [button setTitle:@"录像" forState:UIControlStateNormal];
    button.layer.cornerRadius = width/2.0;
    button.layer.masksToBounds = YES;
    button.layer.borderWidth = 1;
    button.layer.borderColor = [UIColor whiteColor].CGColor;
    [button addTarget:self action:@selector(startRecording:) forControlEvents:UIControlEventTouchUpInside];
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
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(10.0, y, bottomView.frame.size.width - 20.0, 40.0)];
    slider.maximumValue = 100;
    slider.minimumValue = 1;
    [slider addTarget:self action:@selector(updateSliderValue:) forControlEvents:UIControlEventValueChanged];
    [bottomView addSubview:slider];
    

    // Record a movie for 10 s and store it in /Documents, visible via iTunes file sharing
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    movieURL = [NSURL fileURLWithPath:pathToMovie];
    movieWriter = [[GPUImageMovieWriterEx alloc] initWithMovieURL:movieURL size:previewView.bounds.size];
    movieWriter.encodingLiveVideo = YES;
    // 滤镜
    filter = [[GPUImageSepiaFilter alloc] init];
    [filter addTarget:movieWriter];
    [filter addTarget:previewView];
    // 录像
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    videoCamera.horizontallyMirrorRearFacingCamera = NO;
    videoCamera.audioEncodingTarget = movieWriter;
    [videoCamera addTarget:filter];
    [videoCamera startCameraCapture];
}

#pragma mark - GPUImageVideoCameraDelegate

- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    _currentTime = CMTimeGetSeconds(currentTime);
    dispatch_async(dispatch_get_main_queue(), ^{
         [self updateProgress];
    });
}

- (void)updateProgress
{
    _time = [[NSDate date] timeIntervalSinceDate:_beginDate];
    [_progressBar setLastProgressToWidth:_time / _totalTime * _progressBar.frame.size.width];
}

- (void)pressDeleteButton
{
    if (_deleteButton.style == DeleteButtonStyleNormal) {//第一次按下删除按钮
        [_progressBar setLastProgressToStyle:ProgressBarProgressStyleDelete];
        [_deleteButton setButtonStyle:DeleteButtonStyleDelete];
    } else if (_deleteButton.style == DeleteButtonStyleDelete) {//第二次按下删除按钮
//        [self deleteLastVideo];
        [_progressBar deleteLastProgress];
    }
}

- (void)startRecording:(UIButton *)sender
{
    sender.transform = CGAffineTransformMakeScale(0.75, 0.75);
    [UIView animateWithDuration:0.25 animations:^{
        sender.transform = CGAffineTransformMakeScale(1, 1);
    }];
    
    if (![movieWriter started])
    {
        NSLog(@"==startRecording");
        [sender setTitle:@"暂停" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor redColor];
        videoCamera.delegate = self;
        [movieWriter startRecording];
        _beginDate = [NSDate date];
        [_progressBar addProgressView];
    } else if ([movieWriter isPaused])
    {
        NSLog(@"==resumeRecording");
        [sender setTitle:@"暂停" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor redColor];
        videoCamera.delegate = self;
        [movieWriter resumeRecording];
        _beginDate = [NSDate date];
        [_progressBar addProgressView];
    } else
    {
        NSLog(@"==pauseRecording");
        [sender setTitle:@"摄像" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor blueColor];
        videoCamera.delegate = nil;
        [_timeArray addObject:@(_currentTime)];
        [movieWriter pauseRecording];
    }
}

- (void)compactMovie:(UIButton *)sender
{
    videoCamera.delegate = nil;
    [filter removeTarget:movieWriter];
    videoCamera.audioEncodingTarget = nil;
    [movieWriter finishRecording];
    NSLog(@"Movie completed");
    
    TestGPPlayViewController *player = [[TestGPPlayViewController alloc] init];
    player.url = movieURL;
    [self.navigationController pushViewController:player animated:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // Map UIDeviceOrientation to UIInterfaceOrientation.
    UIInterfaceOrientation orient = UIInterfaceOrientationPortrait;
    switch ([[UIDevice currentDevice] orientation])
    {
        case UIDeviceOrientationLandscapeLeft:
            orient = UIInterfaceOrientationLandscapeLeft;
            break;
            
        case UIDeviceOrientationLandscapeRight:
            orient = UIInterfaceOrientationLandscapeRight;
            break;
            
        case UIDeviceOrientationPortrait:
            orient = UIInterfaceOrientationPortrait;
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            orient = UIInterfaceOrientationPortraitUpsideDown;
            break;
            
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationUnknown:
            // When in doubt, stay the same.
            orient = fromInterfaceOrientation;
            break;
    }
    videoCamera.outputImageOrientation = orient;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES; // Support all orientations.
}

- (void)updateSliderValue:(id)sender
{
    [(GPUImageSepiaFilter *)filter setIntensity:[(UISlider *)sender value]];
}


@end

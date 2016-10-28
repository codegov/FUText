//
//  FUCameraViewController.m
//  FUText
//
//  Created by javalong on 16/5/3.
//  Copyright © 2016年 javalong. All rights reserved.
//

#import "FUCameraViewController.h"
#import "FUCameraRecordView.h"
#import "FUCameraCapture.h"
#import "FUCameraPreExport.h"
#import "FUCameraExport.h"
#import "FuMoviePlayerController.h"

typedef enum {
    FUCameraTypeTotal  = 0,    // 完整
    FUCameraTypeSplit  = 1,    // 分段
} FUCameraType;

typedef enum {
    FUCameraCancelTypeNone  = 0,    // 没有取消操作
    FUCameraCancelTypeWill  = 1     // 将要取消
} FUCameraCancelType;

@interface FUCameraMeta : NSObject

@property (nonatomic, strong) NSURL *url;
@property (nonatomic) CMTime recordedDuration;

@end

@implementation FUCameraMeta

@end

@interface FUCameraViewController () <FUCameraCaptureDelegate>

@property (nonatomic, strong) FUCameraRecordView *recordView;
@property (nonatomic, strong) FUCameraCapture    *cameraCapture;
@property (nonatomic, strong) FUCameraPreExport  *preExport;
@property (nonatomic) CMTime  currentRecordedDuration;

@property (nonatomic) FUCameraCancelType cancelType;
@property (nonatomic) FUCameraType type;
@property (nonatomic, strong) NSMutableArray *cameraMetaList;

@end

@implementation FUCameraViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Disable UI. The UI is enabled if and only if the session starts running.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.view.backgroundColor = [UIColor colorWithRed:126.0/255.0 green:126.0/255.0 blue:126.0/255.0 alpha:1];
    self.title = @"00:00:00";
    
    _type = FUCameraTypeTotal;
    _cameraMetaList = [[NSMutableArray alloc] init];
    _preExport = [[FUCameraPreExport alloc] init];
    _currentRecordedDuration = kCMTimeZero;
    
    _cameraCapture = [[FUCameraCapture alloc] init];
    _cameraCapture.delegate = self;
    float bottomHeight = 232.0;
    _cameraCapture.cameraView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-bottomHeight-64);
    [self.view addSubview:_cameraCapture.cameraView];
    
    _recordView = [[FUCameraRecordView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_cameraCapture.cameraView.frame), self.view.frame.size.width, bottomHeight)];
    [self.view addSubview:_recordView];
    
    [_recordView.recordButton addTarget:self action:@selector(autoRecord:) forControlEvents:UIControlEventTouchUpInside];
    [_recordView.okButton addTarget:self action:@selector(selectOutputURL:) forControlEvents:UIControlEventTouchUpInside];
    [_recordView.cancelButton addTarget:self action:@selector(reReord:) forControlEvents:UIControlEventTouchUpInside];
    _recordView.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_cameraCapture startRunningWithViewController:self];
    self.navigationController.navigationBar.translucent  = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBar.translucent  = YES;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor blackColor], NSForegroundColorAttributeName, nil]];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [_cameraCapture stopRunning];
    [super viewDidDisappear:animated];
}

// 使用
- (void)selectOutputURL:(id)sender
{
    _recordView.isRecording = YES;
    [self resumeCancelType];
    __weak typeof (&*self)weakSelf = self;
    FUCameraExport *export = [[FUCameraExport alloc] init];
    [export exportAsynchronouslyWithPreExport:_preExport completionHandler:^(AVAssetExportSession *exportSession) {
        NSLog(@"progress=%@", @(exportSession.progress));
        if (exportSession.status == AVAssetExportSessionStatusCompleted)
        {
            weakSelf.recordView.isRecording = NO;
            FuMoviePlayerController *play = [[FuMoviePlayerController alloc] init];
            play.url = exportSession.outputURL;
            [weakSelf.navigationController pushViewController:play animated:YES];
        }
    }];
}

- (void)autoRecord:(id)sender
{
    [self resumeCancelType];
    [_cameraCapture startRecording];
}

- (void)reReord:(id)sender
{
    if (_cancelType == FUCameraCancelTypeNone)
    {
        _cancelType = FUCameraCancelTypeWill;
        [_recordView.progressBar setLastProgressToStyle:ProgressBarProgressStyleDelete];
    } else if (_cancelType == FUCameraCancelTypeWill)
    {
        _cancelType = FUCameraCancelTypeNone;
        [_recordView.progressBar deleteLastProgress];
        if (_cameraMetaList.count)
        {
            FUCameraMeta *meta = _cameraMetaList.lastObject;
            _currentRecordedDuration = CMTimeSubtract(_currentRecordedDuration, meta.recordedDuration);
            [_preExport cancelExportMovieWithUrl:meta.url];
            [[NSFileManager defaultManager] removeItemAtPath:meta.url.path error:nil];
            [_cameraMetaList removeObject:meta];
            self.title = [FUCameraExport formatCMTime:_currentRecordedDuration];
        }
    }
    _recordView.isRecording = _cameraMetaList.count <= 0;
}

- (void)resumeCancelType
{
    if (_cancelType == FUCameraCancelTypeWill)
    {
        _cancelType = FUCameraCancelTypeNone;
        [_recordView.progressBar setLastProgressToStyle:ProgressBarProgressStyleNormal];
    }
}

#pragma mark FUCameraCaptureDelegate

- (void)cameraCapture:(FUCameraCapture *)capture isSessionRunning:(BOOL)isSessionRunning
{
    _recordView.enabled = isSessionRunning;
}

- (void)cameraCapture:(FUCameraCapture *)capture didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
{
    NSLog(@"didStartRecordingToOutputFileAtURL===%@", fileURL);
    [_recordView.progressBar addProgressView];
    _recordView.isRecording = YES;
}
- (void)cameraCapture:(FUCameraCapture *)capture didSuccessRecordingToOutputFileAtURL:(NSURL *)outputFileURL
{
    NSLog(@"didSuccessRecordingToOutputFileAtURL==%@", outputFileURL);
    
    FUCameraMeta *meta = [[FUCameraMeta alloc] init];
    meta.recordedDuration = _cameraCapture.recordedDuration;
    meta.url = outputFileURL;
    [_cameraMetaList addObject:meta];
    
    _recordView.isRecording = NO;
    _currentRecordedDuration = CMTimeAdd(_currentRecordedDuration, _cameraCapture.recordedDuration);
    [_preExport exportMovieWithUrl:outputFileURL];
    
    _recordView.recordButton.enabled = YES;
    if (_type == FUCameraTypeTotal)
    {
        _recordView.recordButton.enabled = NO;
    }
}
- (void)cameraCapture:(FUCameraCapture *)capture didFailRecordingToOutputFileAtURL:(NSURL *)outputFileURL
{
    _recordView.isRecording = NO;
}

- (void)cameraCapture:(FUCameraCapture *)capture progressOfRecording:(CGFloat)progress
{
    self.title = [FUCameraExport formatCMTime:CMTimeAdd(_currentRecordedDuration, _cameraCapture.recordedDuration)];
    [_recordView.progressBar setLastProgressToWidth:progress * _recordView.progressBar.frame.size.width];
}

- (void)cameraCapture:(FUCameraCapture *)capture changeCaptureDevicePosition:(AVCaptureDevicePosition)position
{}
- (void)cameraCapture:(FUCameraCapture *)capture captureStillImageWithImgData:(NSData *)imageData
{}

#pragma mark Orientation

- (BOOL)shouldAutorotate
{
    // Disable autorotation of the interface when recording is in progress.
    return !_cameraCapture.isRecording;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Note that the app delegate controls the device orientation notifications required to use the device orientation.
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if ( UIDeviceOrientationIsPortrait( deviceOrientation ) || UIDeviceOrientationIsLandscape( deviceOrientation ) )
    {
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)_cameraCapture.cameraView.layer;
        previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
}

@end

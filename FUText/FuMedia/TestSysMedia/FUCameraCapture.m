//
//  FUCameraCapture.m
//  FUText
//
//  Created by javalong on 16/10/24.
//  Copyright © 2016年 javalong. All rights reserved.
//

#import "FUCameraCapture.h"
#import "FUCameraExport.h"

static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningContext      = &SessionRunningContext;

typedef NS_ENUM( NSInteger, AVCamSetupResult )
{
    AVCamSetupResultSuccess,
    AVCamSetupResultCameraNotAuthorized,
    AVCamSetupResultSessionConfigurationFailed
};

@interface FUCameraCapture () <AVCaptureFileOutputRecordingDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput      *videoDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput  *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) CADisplayLink     *displayLink;
@property (nonatomic) float progress;
@property (nonatomic) BOOL isHaveAddObservers;

// Utilities.
@property (nonatomic) AVCamSetupResult setupResult;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

@end

@implementation FUCameraCapture

- (void)dealloc
{
    NSLog(@"FUCameraCapture===dealloc");
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _maxRecordedDuration = CMTimeMakeWithSeconds(180, 20);
        _cameraView = [[FUCameraView alloc] init];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusAndExposeTap:)];
        [_cameraView addGestureRecognizer:tap];
        
        AVCaptureVideoPreviewLayer * l = (AVCaptureVideoPreviewLayer *)_cameraView.layer;
        [l setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        // Create the AVCaptureSession.
        self.session = [[AVCaptureSession alloc] init];
        
        // Setup the preview view.
        self.cameraView.session = self.session;
        
        // Communicate with the session and other session objects on this queue.
        self.sessionQueue = dispatch_queue_create( "FUCameraSessionQueue", DISPATCH_QUEUE_SERIAL);
        self.setupResult  = AVCamSetupResultSuccess;
        
        // Check video authorization status. Video access is required and audio access is optional.
        // If audio access is denied, audio is not recorded during movie recording.
        switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
        {
            case AVAuthorizationStatusAuthorized:
            {
                // The user has previously granted access to the camera.
                break;
            }
            case AVAuthorizationStatusNotDetermined:
            {
                // The user has not yet been presented with the option to grant video access.
                // We suspend the session queue to delay session setup until the access request has completed to avoid
                // asking the user for audio access if video access is denied.
                // Note that audio access will be implicitly requested when we create an AVCaptureDeviceInput for audio during session setup.
                dispatch_suspend( self.sessionQueue );
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                    if ( ! granted ) {
                        self.setupResult = AVCamSetupResultCameraNotAuthorized;
                    }
                    dispatch_resume( self.sessionQueue );
                }];
                break;
            }
            default:
            {
                // The user has previously denied access.
                self.setupResult = AVCamSetupResultCameraNotAuthorized;
                break;
            }
        }
        
        // Setup the capture session.
        // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
        // Why not do all of this on the main queue?
        // Because -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue
        // so that the main queue isn't blocked, which keeps the UI responsive.
        dispatch_async( self.sessionQueue, ^{
            if ( self.setupResult != AVCamSetupResultSuccess )
            {
                return;
            }
            
            self.backgroundRecordingID = UIBackgroundTaskInvalid;
            NSError *error = nil;
            
            AVCaptureDevice *videoDevice = [FUCameraCapture deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
            AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
            
            if (!videoDeviceInput)
            {
                NSLog( @"Could not create video device input: %@", error );
            }
            
            [self.session beginConfiguration];
            
            if ([self.session canAddInput:videoDeviceInput])
            {
                [self.session addInput:videoDeviceInput];
                self.videoDeviceInput = videoDeviceInput;
                
                dispatch_async( dispatch_get_main_queue(), ^{
                    // Why are we dispatching this to the main queue?
                    // Because AVCaptureVideoPreviewLayer is the backing layer for AAPLPreviewView and UIView
                    // can only be manipulated on the main thread.
                    // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                    // on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                    
                    // Use the status bar orientation as the initial video orientation. Subsequent orientation changes are handled by
                    // -[viewWillTransitionToSize:withTransitionCoordinator:].
                    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
                    AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
                    if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
                        initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
                    }
                    
                    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.cameraView.layer;
                    previewLayer.connection.videoOrientation = initialVideoOrientation;
                } );
            } else
            {
                NSLog( @"Could not add video device input to the session" );
                self.setupResult = AVCamSetupResultSessionConfigurationFailed;
            }
            
            AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
            AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
            
            if (! audioDeviceInput) {
                NSLog( @"Could not create audio device input: %@", error );
            }
            
            if ([self.session canAddInput:audioDeviceInput])
            {
                [self.session addInput:audioDeviceInput];
            } else
            {
                NSLog( @"Could not add audio device input to the session" );
            }
            
            AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
            movieFileOutput.maxRecordedDuration   = _maxRecordedDuration;
            movieFileOutput.minFreeDiskSpaceLimit = 1024 * 1024;
            if ([self.session canAddOutput:movieFileOutput])
            {
                [self.session addOutput:movieFileOutput];
                AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
                if ( connection.isVideoStabilizationSupported )
                {
                    connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
                }
                self.movieFileOutput = movieFileOutput;
            } else
            {
                NSLog( @"Could not add movie file output to the session" );
                self.setupResult = AVCamSetupResultSessionConfigurationFailed;
            }
            
            AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
            if ([self.session canAddOutput:stillImageOutput])
            {
                stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
                [self.session addOutput:stillImageOutput];
                self.stillImageOutput = stillImageOutput;
            } else
            {
                NSLog( @"Could not add still image output to the session" );
                self.setupResult = AVCamSetupResultSessionConfigurationFailed;
            }
            [self.session commitConfiguration];
        } );
    }
    return self;
}

- (void)startRunningWithViewController:(UIViewController *)viewController
{
    __weak typeof (&*viewController)weakController = viewController;
    dispatch_async( self.sessionQueue, ^{
        switch ( self.setupResult )
        {
            case AVCamSetupResultSuccess:
            {
                // Only setup observers and start the session running if setup succeeded.
                [self addObservers];
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
                break;
            }
            case AVCamSetupResultCameraNotAuthorized:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"AVCam doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    // Provide quick access to Settings.
                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    }];
                    [alertController addAction:settingsAction];
                    [weakController presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
            case AVCamSetupResultSessionConfigurationFailed:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    [weakController presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
        }
    } );
}

- (void)stopRunning
{
    dispatch_async( self.sessionQueue, ^{
        if ( self.setupResult == AVCamSetupResultSuccess ) {
            [self.session stopRunning];
            [self removeObservers];
            [self stopRecording];
        }
    } );
}

#pragma mark KVO and Notifications

- (void)addObservers
{
    if (_isHaveAddObservers) return;
    _isHaveAddObservers = YES;
    [self.session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
    [self.stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:CapturingStillImageContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDeviceInput.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
    // A session can only run when the app is full screen. It will be interrupted in a multi-app layout, introduced in iOS 9,
    // see also the documentation of AVCaptureSessionInterruptionReason. Add observers to handle these session interruptions
    // and show a preview is paused message. See the documentation of AVCaptureSessionWasInterruptedNotification for other
    // interruption reasons.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:self.session];
}

- (void)removeObservers
{
    if (!_isHaveAddObservers) return;
    _isHaveAddObservers = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.session removeObserver:self forKeyPath:@"running" context:SessionRunningContext];
    [self.stillImageOutput removeObserver:self forKeyPath:@"capturingStillImage" context:CapturingStillImageContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == CapturingStillImageContext ) {
        BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
        if ( isCapturingStillImage )
        {
            dispatch_async( dispatch_get_main_queue(), ^{
                self.cameraView.layer.opacity = 0.0;
                [UIView animateWithDuration:0.25 animations:^{
                    self.cameraView.layer.opacity = 1.0;
                }];
            } );
        }
    } else if ( context == SessionRunningContext )
    {
        BOOL isSessionRunning = [change[NSKeyValueChangeNewKey] boolValue];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            // Only enable the ability to change camera if the device has more than one camera.
            //            self.cameraButton.enabled = isSessionRunning && ( [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count > 1 );
            //            self.recordButton.enabled = isSessionRunning;
            //            self.stillButton.enabled = isSessionRunning;
            
            BOOL isR = isSessionRunning && ( [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count > 1 );
            if ([_delegate respondsToSelector:@selector(cameraCapture:isSessionRunning:)])
            {
                [_delegate cameraCapture:self isSessionRunning:isR];
            }
        } );
    } else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake(0.5, 0.5);
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

- (void)sessionRuntimeError:(NSNotification *)notification
{
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    NSLog( @"Capture session runtime error: %@", error );
    
    // Automatically try to restart the session running if media services were reset and the last start running succeeded.
    // Otherwise, enable the user to try to resume the session running.
    if (error.code == AVErrorMediaServicesWereReset)
    {
        dispatch_async( self.sessionQueue, ^{
            if (self.isSessionRunning)
            {
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
            } else
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    //                    self.resumeButton.hidden = NO;
                } );
            }
        } );
    } else {
        //        self.resumeButton.hidden = NO;
    }
}

- (void)sessionWasInterrupted:(NSNotification *)notification
{
    NSLog(@"=====sessionWasInterrupted======");
    // In some scenarios we want to enable the user to resume the session running.
    // For example, if music playback is initiated via control center while using AVCam,
    // then the user can let AVCam resume the session running, which will stop music playback.
    // Note that stopping music playback in control center will not automatically resume the session running.
    // Also note that it is not always possible to resume, see -[resumeInterruptedSession:].
    BOOL showResumeButton = NO;
    
    // In iOS 9 and later, the userInfo dictionary contains information on why the session was interrupted.
    if ( &AVCaptureSessionInterruptionReasonKey )
    {
        AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
        NSLog( @"Capture session was interrupted with reason %ld", (long)reason );
        
        if ( reason == AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient ||
            reason == AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient )
        {
            showResumeButton = YES;
        } else if ( reason == AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps )
        {
            // Simply fade-in a label to inform the user that the camera is unavailable.
            //            self.cameraUnavailableLabel.hidden = NO;
            //            self.cameraUnavailableLabel.alpha = 0.0;
            //            [UIView animateWithDuration:0.25 animations:^{
            //                self.cameraUnavailableLabel.alpha = 1.0;
            //            }];
        }
    } else
    {
        NSLog( @"Capture session was interrupted" );
        showResumeButton = ( [UIApplication sharedApplication].applicationState == UIApplicationStateInactive );
    }
    
    if ( showResumeButton )
    {
        // Simply fade-in a button to enable the user to try to resume the session running.
        //        self.resumeButton.hidden = NO;
        //        self.resumeButton.alpha = 0.0;
        //        [UIView animateWithDuration:0.25 animations:^{
        //            self.resumeButton.alpha = 1.0;
        //        }];
    }
}

- (void)sessionInterruptionEnded:(NSNotification *)notification
{
    NSLog(@"======sessionInterruptionEnded====");
    
    //    if ( ! self.resumeButton.hidden ) {
    //        [UIView animateWithDuration:0.25 animations:^{
    //            self.resumeButton.alpha = 0.0;
    //        } completion:^( BOOL finished ) {
    //            self.resumeButton.hidden = YES;
    //        }];
    //    }
    //    if ( ! self.cameraUnavailableLabel.hidden ) {
    //        [UIView animateWithDuration:0.25 animations:^{
    //            self.cameraUnavailableLabel.alpha = 0.0;
    //        } completion:^( BOOL finished ) {
    //            self.cameraUnavailableLabel.hidden = YES;
    //        }];
    //    }
}

#pragma mark Actions

- (void)resumeInterruptedSession
{
    dispatch_async( self.sessionQueue, ^{
        // The session might fail to start running, e.g., if a phone or FaceTime call is still using audio or video.
        // A failure to start the session running will be communicated via a session runtime error notification.
        // To avoid repeatedly failing to start the session running, we only try to restart the session running in the
        // session runtime error handler if we aren't trying to resume the session running.
        [self.session startRunning];
        self.sessionRunning = self.session.isRunning;
        if (!self.session.isRunning ) {
            dispatch_async( dispatch_get_main_queue(), ^{
//                NSString *message = NSLocalizedString( @"Unable to resume", @"Alert message when unable to resume the session running" );
//                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
//                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
//                [alertController addAction:cancelAction];
//                [self presentViewController:alertController animated:YES completion:nil];
            } );
        } else {
            dispatch_async( dispatch_get_main_queue(), ^{
                //                self.resumeButton.hidden = YES;
            } );
        }
    } );
}

- (void)startRecording
{
    // Disable the Camera button until recording finishes, and disable the Record button until recording starts or finishes. See the
    // AVCaptureFileOutputRecordingDelegate methods.
    //    self.cameraButton.enabled = NO;
    //    self.recordButton.enabled = NO;
    
    dispatch_async( self.sessionQueue, ^{
        [self stopDisplayLink];
        if (!self.movieFileOutput.isRecording )
        {
            if ( [UIDevice currentDevice].isMultitaskingSupported ) {
                // Setup background task. This is needed because the -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:]
                // callback is not received until AVCam returns to the foreground unless you request background execution time.
                // This also ensures that there will be time to write the file to the photo library when AVCam is backgrounded.
                // To conclude this background execution, -endBackgroundTask is called in
                // -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:] after the recorded file has been saved.
                self.backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
            }
            // Update the orientation on the movie file output video connection before starting recording.
            AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.cameraView.layer;
            connection.videoOrientation = previewLayer.connection.videoOrientation;
            
            // Turn OFF flash for video recording.
            [FUCameraCapture setFlashMode:AVCaptureFlashModeOff forDevice:self.videoDeviceInput.device];
            
            // Start recording to a temporary file.
            NSString *outputFileName = [NSProcessInfo processInfo].globallyUniqueString;
            
            NSString *doc =  [NSTemporaryDirectory() stringByAppendingFormat:@"/GWWCompressionVideo"];
            NSFileManager *manager = [NSFileManager defaultManager];
            BOOL isExists = [manager fileExistsAtPath:doc];
            if (!isExists)
            {
                [manager createDirectoryAtPath:doc withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            NSString *outputFilePath = [doc stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mp4"]];
            [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
        } else
        {
            [self.movieFileOutput stopRecording];
        }
    } );
}

- (void)clearCapture
{
    NSString *doc =  [NSTemporaryDirectory() stringByAppendingFormat:@"/GWWCompressionVideo"];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isExists = [manager fileExistsAtPath:doc];
    if (isExists) {
        [manager removeItemAtPath:doc error:nil];
    }
}

- (void)stopRecording
{
    dispatch_async( self.sessionQueue, ^{
        if (self.movieFileOutput.isRecording )
        {
            [self.movieFileOutput stopRecording];
        }
        [self stopDisplayLink];
    } );
}

- (void)startDisplayLink
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_displayLink)
        {
            [_displayLink invalidate];
            _displayLink = nil;
        }
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(doAction:)];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    });
}

- (void)stopDisplayLink
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_displayLink)
        {
            [_displayLink invalidate];
            _displayLink = nil;
        }
    });
}

- (void)doAction:(CADisplayLink *)sender
{
    Float64 second = CMTimeGetSeconds(self.movieFileOutput.recordedDuration);
    Float64 allSec = CMTimeGetSeconds(self.movieFileOutput.maxRecordedDuration);
    Float64 progress = 0;
    if (allSec > 0)
    {
        progress = second / allSec;
    }
    if (_progress == progress) return;
    _progress = progress;
    if ([_delegate respondsToSelector:@selector(cameraCapture:progressOfRecording:)])
    {
        [_delegate cameraCapture:self progressOfRecording:progress];
    }
}

// 改变摄像头为前置/后置
- (void)changeCaptureDevicePosition
{
    //    self.cameraButton.enabled = NO;
    //    self.recordButton.enabled = NO;
    //    self.stillButton.enabled = NO;
    
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *currentVideoDevice = self.videoDeviceInput.device;
        AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
        AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
        
        switch ( currentPosition )
        {
            case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionFront:
                preferredPosition = AVCaptureDevicePositionBack;
                break;
            case AVCaptureDevicePositionBack:
                preferredPosition = AVCaptureDevicePositionFront;
                break;
        }
        
        AVCaptureDevice *videoDevice = [FUCameraCapture deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
        
        [self.session beginConfiguration];
        
        // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
        [self.session removeInput:self.videoDeviceInput];
        
        if ( [self.session canAddInput:videoDeviceInput] ) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
            
            [FUCameraCapture setFlashMode:AVCaptureFlashModeAuto forDevice:videoDevice];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:videoDevice];
            
            [self.session addInput:videoDeviceInput];
            self.videoDeviceInput = videoDeviceInput;
        } else {
            [self.session addInput:self.videoDeviceInput];
        }
        
        AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ( connection.isVideoStabilizationSupported ) {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        
        [self.session commitConfiguration];
        
        __weak typeof (&*self)weakSelf = self;
        dispatch_async( dispatch_get_main_queue(), ^{
            //            self.cameraButton.enabled = YES;
            //            self.recordButton.enabled = YES;
            //            self.stillButton.enabled = YES;
            if ([weakSelf.delegate respondsToSelector:@selector(cameraCapture:changeCaptureDevicePosition:)])
            {
                [weakSelf.delegate cameraCapture:weakSelf changeCaptureDevicePosition:preferredPosition];
            }
        } );
    } );
}

// 截获静态图片
- (void)asynCaptureStillImage
{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.cameraView.layer;
        
        // Update the orientation on the still image output video connection before capturing.
        connection.videoOrientation = previewLayer.connection.videoOrientation;
        
        // Flash set to Auto for Still Capture.
        [FUCameraCapture setFlashMode:AVCaptureFlashModeAuto forDevice:self.videoDeviceInput.device];
        
        // Capture a still image.
        __weak typeof (&*self)weakSelf = self;
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^( CMSampleBufferRef imageDataSampleBuffer, NSError *error ) {
            NSData *imageData = nil;
            if (imageDataSampleBuffer)
            {
                // The sample buffer is not retained. Create image data before saving the still image to the photo library asynchronously.
                imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                [FUCameraExport saveToPhotoWithImgData:imageData];
            } else
            {
                NSLog( @"Could not capture still image: %@", error );
            }
            if ([weakSelf.delegate respondsToSelector:@selector(cameraCapture:captureStillImageWithImgData:)])
            {
                [weakSelf.delegate cameraCapture:weakSelf captureStillImageWithImgData:imageData];
            }
        }];
    } );
}

- (void)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)self.cameraView.layer captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:gestureRecognizer.view]];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

#pragma mark File Output Recording Delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    __weak typeof (&*self)weakSelf = self;
    dispatch_async( dispatch_get_main_queue(), ^{
        if ([weakSelf.delegate respondsToSelector:@selector(cameraCapture:didOutputSampleBuffer:)])
        {
            [weakSelf.delegate cameraCapture:weakSelf didOutputSampleBuffer:sampleBuffer];
        }
    });
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    // Enable the Record button to let the user stop the recording.
    __weak typeof (&*self)weakSelf = self;
    dispatch_async( dispatch_get_main_queue(), ^{
        [self startDisplayLink];
        //        self.recordButton.enabled = YES;
        //        [self.recordButton setTitle:NSLocalizedString( @"停止", @"Recording button stop title") forState:UIControlStateNormal];
        if ([weakSelf.delegate respondsToSelector:@selector(cameraCapture:didStartRecordingToOutputFileAtURL:)])
        {
            [weakSelf.delegate cameraCapture:weakSelf didStartRecordingToOutputFileAtURL:fileURL];
        }
    });
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    // Note that currentBackgroundRecordingID is used to end the background task associated with this recording.
    // This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's isRecording property
    // is back to NO — which happens sometime after this method returns.
    // Note: Since we use a unique file path for each recording, a new recording will not overwrite a recording currently being saved.
    UIBackgroundTaskIdentifier currentBackgroundRecordingID = self.backgroundRecordingID;
    self.backgroundRecordingID = UIBackgroundTaskInvalid;
    
    dispatch_block_t cleanup = ^{
        //        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
        if ( currentBackgroundRecordingID != UIBackgroundTaskInvalid ) {
            [[UIApplication sharedApplication] endBackgroundTask:currentBackgroundRecordingID];
        }
    };
    
    BOOL success = YES;
    if (error)
    {
        NSLog( @"Movie file finishing error: %@", error );
        success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
    }
    NSLog(@"============%@", @(CMTimeGetSeconds(captureOutput.recordedDuration)));
    cleanup();
    [self stopRecording];
    __weak typeof (&*self)weakSelf = self;
    // Enable the Camera and Record buttons to let the user switch camera and start another recording.
    dispatch_async( dispatch_get_main_queue(), ^{
        // Only enable the ability to change camera if the device has more than one camera.
        //        self.cameraButton.enabled = ( [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count > 1 );
        //        self.recordButton.enabled = YES;
        //        [self.recordButton setTitle:NSLocalizedString( @"录像", @"Recording button record title" ) forState:UIControlStateNormal];
        if (success)
        {
            if ([weakSelf.delegate respondsToSelector:@selector(cameraCapture:didSuccessRecordingToOutputFileAtURL:)])
            {
                [weakSelf.delegate cameraCapture:weakSelf didSuccessRecordingToOutputFileAtURL:outputFileURL];
            }
        } else
        {
            if ([weakSelf.delegate respondsToSelector:@selector(cameraCapture:didFailRecordingToOutputFileAtURL:)])
            {
                [weakSelf.delegate cameraCapture:weakSelf didFailRecordingToOutputFileAtURL:outputFileURL];
            }
        }
    });
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = self.videoDeviceInput.device;
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            // Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
            // Call -set(Focus/Exposure)Mode: to apply the new point of interest.
            if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        } else
        {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    } );
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
    if (device.hasFlash && [device isFlashModeSupported:flashMode])
    {
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            device.flashMode = flashMode;
            [device unlockForConfiguration];
        } else
        {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    }
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for (AVCaptureDevice *device in devices)
    {
        if (device.position == position)
        {
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}


- (BOOL)isRecording
{
    return self.movieFileOutput.isRecording;
}

- (void)setMaxRecordedDuration:(CMTime)maxRecordedDuration
{
    _maxRecordedDuration = maxRecordedDuration;
    self.movieFileOutput.maxRecordedDuration = maxRecordedDuration;
}

- (CMTime)recordedDuration
{
    return self.movieFileOutput.recordedDuration;
}

@end

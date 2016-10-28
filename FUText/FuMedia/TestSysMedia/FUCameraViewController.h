//
//  FUCameraViewController.h
//  FUText
//
//  Created by javalong on 16/5/3.
//  Copyright © 2016年 javalong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FUCameraViewController;

@protocol FUCameraViewControllerDelegate <NSObject>

@optional
- (void)cameraViewController:(FUCameraViewController *)controller selectOutputURL:(NSURL *)url;
- (void)cameraViewController:(FUCameraViewController *)controller playOutputURL:(NSURL *)url;

@end

@interface FUCameraViewController : UIViewController

@property (nonatomic, weak) id<FUCameraViewControllerDelegate> delegate;

@end

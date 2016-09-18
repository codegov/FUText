//
//  TWFaceGridView.h
//  LearnTest
//
//  Created by syq on 15/10/31.
//  Copyright © 2015年 com.chanjet. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TWFaceGridView;

@protocol TWFaceGridViewDelegate <NSObject>

- (void)faceGridViewDidInputFace:(NSString *)face;

- (void)faceGridViewDidDelete;

- (void)faceGridViewDidSend;

@end

@interface TWFaceGridView : UIView

@property (nonatomic , weak) id<TWFaceGridViewDelegate> delegate;

@property (nonatomic) BOOL showSend;

@end

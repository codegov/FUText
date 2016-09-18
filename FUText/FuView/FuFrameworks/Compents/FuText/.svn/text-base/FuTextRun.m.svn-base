//
//  FuTextRun.m
//  Test
//
//  Created by syq on 14/8/20.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuTextRun.h"

static void RunDelegateDeallocateCallback(void *refCon)
{
    FuTextRun *object = (__bridge_transfer FuTextRun *)refCon;
    object = nil; // release
}

static CGFloat RunDelegateGetAscentCallback(void *refCon)
{
    FuTextRun *object = (__bridge FuTextRun *)refCon;
    return object.runSize.height;
}

static CGFloat RunDelegateGetDescentCallback(void *refCon)
{
    return 0.0f;
}

static CGFloat RunDelegateGetWidthCallback(void *refCon)
{
    FuTextRun *object = (__bridge FuTextRun *)refCon;
    if (object.type == FuText_img) {
        return object.runSize.width + FUTEXT_IMG_EDGE * 2;
    }
    return object.runSize.width;
}

@implementation FuTextRun

- (CTRunDelegateCallbacks)callbacks
{
    CTRunDelegateCallbacks callbacks;
    callbacks.version    = kCTRunDelegateCurrentVersion;
    callbacks.dealloc    = RunDelegateDeallocateCallback;
    callbacks.getAscent  = RunDelegateGetAscentCallback;
    callbacks.getDescent = RunDelegateGetDescentCallback;
    callbacks.getWidth   = RunDelegateGetWidthCallback;
    return callbacks;
}

@end

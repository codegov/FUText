//
//  FuDrawLineLayoutView.m
//  Test
//
//  Created by syq on 14/7/23.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuDrawLineLayoutView.h"
#import "FuLineLayout.h"
#import "FuTextRun.h"
#import "NSString+FuFace.h"
#import "GWWEditImageView.h"

@implementation FuDrawLineLayoutView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setLine:(FuLineLayout *)line
{
    _line = line;
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
#if TARGET_OS_IPHONE
    CGContextRef context = UIGraphicsGetCurrentContext();
#else
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
#endif
    
    [self drawTextAttachmentsInContext:context];
    
#if TARGET_OS_IPHONE
    CGContextScaleCTM(context, 1.0, -1.0);
#endif
    
    CGContextSetTextPosition(context, 0.0, -_line.metrics.ascent);
    CTLineDraw(_line.line, context);
    
}


- (void)drawTextAttachmentsInContext:(CGContextRef)context
{
    __weak FuDrawLineLayoutView *weakSelf = self;
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [_line.attributedString enumerateAttribute:(id)kCTRunDelegateAttributeName inRange:NSMakeRange(0, _line.attributedString.length) options:kNilOptions usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (!value) {
            return;
        }
        CTRunDelegateRef runDelegate = (__bridge CTRunDelegateRef)value;
        FuTextRun *attachment = (__bridge FuTextRun *)CTRunDelegateGetRefCon(runDelegate);
        
        if (!attachment) {
            return;
        }
        
        CGRect rect = [_line rectOfStringWithRange:range];
        if (attachment.type == FuText_img)
        {
            UIImage *image = [UIImage imageNamed:[attachment.string faceFormat]];
            rect.size = attachment.size;
            rect.origin.x += (FUTEXT_IMG_EDGE);
            rect.origin.y += (_line.rect.size.height - rect.size.height)/2.0;
#if TARGET_OS_IPHONE
            [image drawInRect:rect];
#else
            [image drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
#endif
        } else if (attachment.type == FuText_view)
        {
            NSRange vRange = NSMakeRange(_line.stringRange.location + range.location, range.length);
            rect.size = CGSizeMake(_line.rect.size.width, attachment.size.height);
            rect.origin.y += (_line.rect.size.height - attachment.size.height)/2.0;
            NSString *imageSize = NSStringFromCGSize(attachment.size);
            GWWEditImageView *view = [[GWWEditImageView alloc] initWithFrame:rect];
            view.allowCliclImage = NO;
            view.userInfo = @{@"path": attachment.string,
                              @"range": NSStringFromRange(vRange),
                              @"imageSize": imageSize,
                              @"showClose": @(YES)};
            [weakSelf addSubview:view];
        }
    }];
}

@end

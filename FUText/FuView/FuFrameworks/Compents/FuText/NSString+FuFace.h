//
//  NSString+Filter.h
//  teamwork
//
//  Created by sunlin on 14-4-28.
//  Copyright (c) 2014年 chanjet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (FuFace)

+ (NSArray *)faceArray;
- (NSString *)faceFormat;
- (NSString *)faceFormatToCh;
+ (NSString *)faceNameOfIndex:(NSInteger)index;
+ (NSString *)facePlaceholderOfIndex:(NSInteger)index;
- (BOOL)isExistFace;
- (BOOL)isUrl;

@end

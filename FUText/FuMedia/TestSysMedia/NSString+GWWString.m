//
//  NSString+GWWString.m
//  GroupWenWen
//
//  Created by javalong on 16/4/26.
//  Copyright © 2016年 evan. All rights reserved.
//

#import "NSString+GWWString.h"

@implementation NSString (GWWString)

/*转换为沙箱Documents文件夹下的路径*/
- (NSString *)documentFilePath
{
    NSString *tempPath = [self hasPrefix:@"Documents/"] ? self : [NSString stringWithFormat:@"Documents/%@", self];
    return [self hasPrefix:NSHomeDirectory()] ? self : [NSHomeDirectory() stringByAppendingPathComponent:tempPath];
}

/*是否为沙箱Documents文件夹下的路径*/
- (BOOL)isDocumentFilePath
{
    return [self hasPrefix:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/"]];
}

/*转换为沙箱Library/Cache文件夹下的路径*/
- (NSString *)cacheFilePath
{
    return [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Library/Caches/%@", self]];
}

/*是否为沙箱Library/Cache文件夹下的路径*/
- (BOOL)isCacheFilePath
{
    return [self hasPrefix:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/"]];
}


@end

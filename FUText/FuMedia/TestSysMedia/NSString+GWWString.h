//
//  NSString+GWWString.h
//  GroupWenWen
//
//  Created by javalong on 16/4/26.
//  Copyright © 2016年 evan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (GWWString)

- (NSString *)documentFilePath;             //转换为沙箱Documents文件夹下的路径
- (BOOL)isDocumentFilePath;                 //是否为沙箱Documents文件夹下的路径

- (NSString *)cacheFilePath;                //转换为沙箱Library/Cache文件夹下的路径
- (BOOL)isCacheFilePath;                    //是否为沙箱Library/Cache文件夹下的路径

@end

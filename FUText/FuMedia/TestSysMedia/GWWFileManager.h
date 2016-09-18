//
//  GWWFileManager.h
//  GroupWenWen
//
//  Created by javalong on 16/4/13.
//  Copyright © 2016年 evan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+GWWString.h"

@interface GWWFileManager : NSObject

+ (UIImage *)loadImage:(NSString *)path;
+ (UIImage *)loadCacheImage:(NSString *)path;/*读取图片(Library/Caches文件夹下)*/
+ (id)loadObject:(NSString *)path;
+ (NSMutableArray *)loadArray:(NSString *)path;
+ (NSMutableDictionary *)loadDictionary:(NSString *)path;

+ (BOOL)saveObject:(id)object filePath:(NSString *)path;
+ (BOOL)saveCacheObject:(id)object filePath:(NSString *)path;/*存储序列化对象(Library/Caches文件夹下)*/
+ (BOOL)saveData:(NSData *)data filePath:(NSString *)path;/*存储数据(Documents文件夹下)*/

+ (BOOL)fileExistsAtPath:(NSString *)path;//是否存在指定文件(Documents文件夹下)
+ (BOOL)createDirectoryAtPath:(NSString *)path;/*创建指定路径文件夹(Documents文件夹下)*/
+ (BOOL)deleteFile:(NSString *)path;

@end

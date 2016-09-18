//
//  GWWTextCache.m
//  GroupWenWen
//
//  Created by javalong on 16/7/25.
//  Copyright © 2016年 evan. All rights reserved.
//

#import "GWWTextCache.h"

@implementation GWWTextCache

+ (id)instance
{
    static GWWTextCache *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[GWWTextCache alloc] init];
    });
    
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _cache = [[NSCache alloc] init];
        _cache.countLimit = 300;
    }
    return self;
}

@end

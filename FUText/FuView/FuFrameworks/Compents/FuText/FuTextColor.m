//
//  FuTextColor.m
//  Test
//
//  Created by syq on 14/8/20.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuTextColor.h"

@implementation FuTextColor

- (id)init
{
    self = [super init];
    if (self)
    {
        _color              = [UIColor colorWithRed:0x40/255.0 green:0x40/255.0 blue:0x40/255.0 alpha:1];
        _color_topic        = [UIColor colorWithRed:0x70/255.0 green:0xd2/255.0 blue:0xdb/255.0 alpha:1];
        _color_at           = [UIColor colorWithRed:0x70/255.0 green:0xd2/255.0 blue:0xdb/255.0 alpha:1];
        _color_url          = [UIColor colorWithRed:0x70/255.0 green:0xd2/255.0 blue:0xdb/255.0 alpha:1];
        _color_number       = [UIColor colorWithRed:0x70/255.0 green:0xd2/255.0 blue:0xdb/255.0 alpha:1];
        _color_highlight    = [UIColor colorWithRed:0.654656 green:0.792518 blue:0.999198 alpha:1.0];
    }
    return self;
}

@end

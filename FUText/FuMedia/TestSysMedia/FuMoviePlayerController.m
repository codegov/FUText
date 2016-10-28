//
//  FuMoviePlayerController.m
//  FUText
//
//  Created by javalong on 16/5/3.
//  Copyright © 2016年 javalong. All rights reserved.
//

#import "FuMoviePlayerController.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation FuMoviePlayerController
{
    MPMoviePlayerController *_player;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (!_url) return;
    
    _player = [[MPMoviePlayerController alloc] initWithContentURL:_url];
    
    [_player setScalingMode:MPMovieScalingModeAspectFill];
    [_player setControlStyle:MPMovieControlStyleEmbedded];
    [_player.view setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 216)];
    [self.view addSubview:_player.view];
    
    [_player prepareToPlay];
    _player.initialPlaybackTime = 1.0;
    [_player play];
}

@end

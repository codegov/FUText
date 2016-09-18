//
//  FuDrawViewCell.m
//  Test
//
//  Created by syq on 14/6/17.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuDrawViewCell.h"
#import "FuTextModel.h"
#import "FuDrawHighlightView.h"
#import "FuDrawLineLayoutView.h"

@interface FuDrawViewCell()
{
    FuDrawLineLayoutView *_lineView;
    FuDrawHighlightView  *_highlightView;
}

@end

@implementation FuDrawViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier edgeInsets:(UIEdgeInsets)edgeInsets;
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        CGRect lineFrame = CGRectMake(edgeInsets.left, 0.0, self.bounds.size.width  - edgeInsets.left - edgeInsets.right, self.bounds.size.height);
        _lineView = [[FuDrawLineLayoutView alloc] initWithFrame:lineFrame];
        _lineView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _lineView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_lineView];
        
        _highlightView = [[FuDrawHighlightView alloc] initWithFrame:lineFrame];
        _highlightView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _highlightView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_highlightView];
    }
    return self;
}

- (void)setLine:(FuLineLayout *)line
{
    _line = line;
    _highlightView.highlightView.frame = line.highlightRect;
    _lineView.line = line;
}

@end


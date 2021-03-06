//
//  TWFaceGridView.m
//  LearnTest
//
//  Created by syq on 15/10/31.
//  Copyright © 2015年 com.chanjet. All rights reserved.
//

#import "TWFaceGridView.h"
#import "FUGridView.h"
#import "TWFaceScrollView.h"
#import "NSString+FuFace.h"

@interface TWFaceGridView()<FUGridViewDelegate, UIScrollViewDelegate>
{
    TWFaceScrollView *_scrollView;
    UIView           *_bottomView;
    
    UIView           *_pinView;
    
    UIPageControl *_pageController;
    NSInteger      _pageCount;
}
@end

@implementation TWFaceGridView

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _showSend = YES;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _showSend = YES;
    }
    return self;
}

#pragma mark - data

- (void)setShowSend:(BOOL)showSend
{
    _showSend = showSend;
    [self setNeedsLayout];
}

#pragma mark - view

- (void)layoutSubviews
{

//    self.backgroundColor = [UIColor colorWithString:@"#f9f9f9"];
    float bottomHeight = _showSend ? 60.0 : 15.0;
    if (!_scrollView)
    {
        _scrollView = [self createTopViewWithFrame:CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height - bottomHeight)];
        [self addSubview:_scrollView];
    }
    _scrollView.frame = CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height - bottomHeight);
    
    if (!_pageController)
    {
        _pageController = [[UIPageControl alloc] initWithFrame:CGRectMake(0.0, _scrollView.frame.origin.y + _scrollView.frame.size.height, self.frame.size.width, 15)];
        _pageController.numberOfPages = _pageCount;
        _pageController.currentPage = 0;
//        _pageController.pageIndicatorTintColor = [UIColor colorWithString:@"#E2E0E0"];
//        _pageController.currentPageIndicatorTintColor = [UIColor colorWithString:@"#9A9A9A"];
        [_pageController addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:_pageController];
    }
    
    if (!_bottomView)
    {
        _bottomView = [self createBottomViewWithFrame:CGRectMake(0.0, _pageController.frame.origin.y + _pageController.frame.size.height, self.bounds.size.width, bottomHeight - _pageController.bounds.size.height)];
        [self addSubview:_bottomView];
    }
    _bottomView.hidden = !_showSend;

    [super layoutSubviews];
}

#pragma mark - 顶部视图

- (TWFaceScrollView *)createTopViewWithFrame:(CGRect)frame
{
    float edge = 10.0;
    float estimateWidth = 40.0;
    float gridWidth = frame.size.width - 2 * edge;
    float gridHeight = frame.size.height - edge/2.0;
    int row = gridHeight/estimateWidth;
    int col = gridWidth/estimateWidth;
    int count = row * col - 1;
    _pageCount = ([NSString faceArray].count + count - 1)/count;
    
    TWFaceScrollView *scrollView = [[TWFaceScrollView alloc] initWithFrame:frame];
    scrollView.contentSize = CGSizeMake(_pageCount * scrollView.bounds.size.width, scrollView.bounds.size.height);
    scrollView.pagingEnabled = YES;
    scrollView.directionalLockEnabled = YES;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.delegate = self;
    scrollView.canCancelContentTouches = YES;
    scrollView.delaysContentTouches = NO;
    
    for (int i = 0; i < _pageCount; i++)
    {
        float x = i * scrollView.bounds.size.width;
        FUGridView *gridView = [[FUGridView alloc] initWithFrame:CGRectMake(x, 0.0, frame.size.width, frame.size.height)];
        gridView.delegate = self;
        gridView.dotMatrix = [self createDotMatrixWithFrame:gridView.frame row:row col:col page:i edge:edge];
        [scrollView addSubview:gridView];
    }
    return scrollView;
}

#pragma mark - 底部视图

- (UIView *)createBottomViewWithFrame:(CGRect)frame
{
    UIView *view = [[UIView alloc] initWithFrame:frame];
    
    float y = 0.0;
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0.0, y, view.frame.size.width, 1)];
//    lineView.backgroundColor = [UIColor colorWithString:@"#e1e1e1"];
    [view addSubview:lineView];
    
    y = lineView.frame.origin.y + lineView.frame.size.height;
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0.0, y, view.frame.size.width, view.frame.size.height - y)];
//    bottomView.backgroundColor = [UIColor colorWithString:@"#f9f9f9"];
    [view addSubview:bottomView];
    
    UIButton *faceButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 56.0, bottomView.frame.size.height)];
    [faceButton setImage:[UIImage imageNamed:@"im_input_keybo_face"] forState:UIControlStateNormal];
    [faceButton setImage:[UIImage imageNamed:@"im_input_keybo_face"] forState:UIControlStateHighlighted];
//    faceButton.backgroundColor = [UIColor colorWithString:@"#b1b2b1"];
    [bottomView addSubview:faceButton];
    
    UIButton *sendButton = [[UIButton alloc] initWithFrame:CGRectMake(bottomView.frame.size.width - 56.0, 0, 56.0, bottomView.frame.size.height)];
    [sendButton setTitle:@"发送" forState:UIControlStateNormal];
    [sendButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [sendButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    [sendButton addTarget:self action:@selector(sendAction) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:sendButton];
    
    UIView *b_line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, sendButton.frame.size.height)];
//    b_line.backgroundColor = [UIColor colorWithString:@"#e1e1e1"];
    [sendButton addSubview:b_line];
    
    return view;
}

- (void)sendAction
{
    if ([_delegate respondsToSelector:@selector(faceGridViewDidSend)])
    {
        [_delegate faceGridViewDidSend];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = scrollView.contentOffset.x / pageWidth;
    _pageController.currentPage = page;
}

- (void)changePage:(UIPageControl *)pageControll
{
    int page = (int)pageControll.currentPage;
    CGRect frame = _scrollView.frame;
    frame.origin.x = frame.size.width * page;
    [_scrollView scrollRectToVisible:frame animated:YES];
}

#pragma mark - 创建点阵

- (FUDotMatrix *)createDotMatrixWithFrame:(CGRect)frame row:(int)row col:(int)col page:(int)page edge:(float)edge
{
    int count = row * col - 1;
    float width = (frame.size.width - 2 * edge)/(col * 1.0);
    float height = (frame.size.height - edge)/(row * 1.0);
    NSMutableArray *dotArray = [[NSMutableArray alloc] init];
    float y = 0;
    for (int i = 0; i < row; i++)
    {
        float x = 0.0;
        float tHeight = height;
        float offY = 0;
        if (i == 0 || i == row - 1)
        {
            tHeight = height + edge/2.0;
            offY = i == 0 ? edge/2.0 : -edge/2.0;
        }
        for (int j = 0; j < col; j++)
        {
            float tWidth = width;
            float offX = 0;
            if (j == 0 || j == col - 1)
            {
                tWidth = width + edge;
                offX = j == 0 ? edge : -edge;
            }
            FUGridDot *dot = [[FUGridDot alloc] init];
            dot.dotFrame = CGRectMake(x, y, tWidth, tHeight);
            if (i == row - 1 && j == col - 1)
            {
                dot.dotView = [self createDotDelViewWithFrame:dot.dotFrame offX:offX offY:offY];
            } else
            {
                int tag = page * count + i * col + j;
                dot.userInfo = @{@"index": @(tag), @"offX": @(offX), @"offY": @(offY)};
                dot.dotView = [self createDotViewWithFrame:dot.dotFrame tag:tag offX:offX offY:offY];
            }
            [dotArray addObject:dot];
            x += tWidth;
        }
        y += tHeight;
    }
    FUDotMatrix *dotMatrix = [[FUDotMatrix alloc] init];
    dotMatrix.dotArray = dotArray;
    return dotMatrix;
}

#pragma mark - 创建点视图

- (UIView *)createDotViewWithFrame:(CGRect)frame tag:(int)tag offX:(float)offX offY:(float)offY
{
    UIView *view = [[UIView alloc] initWithFrame:frame];
    
    NSString *name = [NSString faceNameOfIndex:tag];
    UIImage*face = name.length ? [UIImage imageNamed:name] : nil;
    CGRect buttonFrame = view.bounds;
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    [button setImage:face forState:UIControlStateNormal];
    button.tag = tag;
    button.imageEdgeInsets = UIEdgeInsetsMake(offY, offX, 0.0, 0.0);
    [button addTarget:self action:@selector(selectFace:) forControlEvents:UIControlEventTouchUpInside];
    
    [view addSubview:button];
    
    return view;
}

- (UIView *)createDotDelViewWithFrame:(CGRect)frame offX:(float)offX offY:(float)offY
{
    UIView *view = [[UIView alloc] initWithFrame:frame];
    
    UIImage*face = [UIImage imageNamed:@"im_input_keybo_del"];
    CGRect buttonFrame = view.bounds;
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    [button setImage:face forState:UIControlStateNormal];
    button.imageEdgeInsets = UIEdgeInsetsMake(offY, offX, 0.0, 0.0);
    [button addTarget:self action:@selector(delFace:) forControlEvents:UIControlEventTouchUpInside];
    
    [view addSubview:button];
    
    return view;
}

- (void)selectFace:(UIButton *)sender
{
    [self selectFaceWithIndex:sender.tag];
}

- (void)selectFaceWithIndex:(NSInteger)index
{
    NSString *p = [NSString facePlaceholderOfIndex:index];
    if (p.length && [_delegate respondsToSelector:@selector(faceGridViewDidInputFace:)])
    {
        [_delegate faceGridViewDidInputFace:p];
    }
}

- (void)delFace:(UIButton *)sender
{
    if ([_delegate respondsToSelector:@selector(faceGridViewDidDelete)])
    {
        [_delegate faceGridViewDidDelete];
    }
}

#pragma mark - 创建大头针视图

- (UIView *)createPinViewWithFrame:(CGRect)frame faceName:(NSString *)name facePlaceholder:(NSString *)place
{
    UIView *view = [[UIView alloc] initWithFrame:frame];
    
    UIImageView *tipImageView = [[UIImageView alloc] initWithFrame:view.bounds];
    tipImageView.image = [UIImage imageNamed:@"TWFace_EmoticonTips"];
    [view addSubview:tipImageView];
    
    float edge = 12.0;
    UIImage *face = [UIImage imageNamed:name];
    float faceWidth = tipImageView.image.size.width - 2 * edge; //face.size.width * 1.5;
    float faceHieght = face.size.width > 0 ? faceWidth * face.size.height / face.size.width : faceWidth;//face.size.height * 1.5;
    UIImageView *faceImageView = [[UIImageView alloc] initWithImage:face];
    faceImageView.frame = CGRectMake((frame.size.width - faceWidth)/2.0, edge, faceWidth, faceHieght);
    [view addSubview:faceImageView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, faceImageView.frame.origin.y + faceImageView.frame.size.height + 2.0, frame.size.width, 20.0)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:14.0];
    label.textColor = [UIColor lightGrayColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = place;
    [view addSubview:label];
    
    return view;
}

#pragma mark - FUGridView Delegate

- (void)gridView:(FUGridView *)gridView changeToDot:(FUGridDot *)dot moveGesture:(UIGestureRecognizer *)gesture
{
    [_pinView removeFromSuperview];
    _pinView = nil;
    
    if (!dot) return;
    
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateFailed || gesture.state == UIGestureRecognizerStateCancelled)
    {
        if (dot.userInfo)
        {
            [self selectFaceWithIndex:[[dot.userInfo objectForKey:@"index"] integerValue]];
        }
    } else if (dot.userInfo)
    {
        NSInteger index = [[dot.userInfo objectForKey:@"index"] integerValue];
        float     offX  = [[dot.userInfo objectForKey:@"offX"] integerValue];
        float     offY  = [[dot.userInfo objectForKey:@"offY"] integerValue];
        NSString *name = [NSString faceNameOfIndex:index];
        NSString *plac = [NSString facePlaceholderOfIndex:index];
        if (name.length && plac.length)
        {
            UIImage *tip = [UIImage imageNamed:@"TWFace_EmoticonTips"];
            float tipWidth = tip.size.width;
            float tipHeight = tip.size.height;
            float x = dot.dotFrame.origin.x + (dot.dotFrame.size.width - tipWidth)/2.0 + offX;
            float y = dot.dotFrame.origin.y + dot.dotFrame.size.height - tipHeight + offY;
            CGRect frame = CGRectMake(x, y, tipWidth, tipHeight);
            frame = [gridView convertRect:frame toView:[UIApplication sharedApplication].keyWindow];
            _pinView = [self createPinViewWithFrame:frame faceName:name facePlaceholder:plac];
            [[UIApplication sharedApplication].keyWindow addSubview:_pinView];
        }
    }
}

@end

//
//  ViewController.m
//  FUText
//
//  Created by javalong on 16/4/28.
//  Copyright © 2016年 javalong. All rights reserved.
//

#import "ViewController.h"
#import "FuTextView.h"
#import "FUCameraViewController.h"
#import "TestMediaViewController.h"
#import "TestGPViewController.h"

@interface ViewController ()
{
    FuTextView *_textView;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"富视图";

    _textView = [[FuTextView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 216)];
    _textView.backgroundColor = [UIColor brownColor];
    _textView.edgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    [self.view addSubview:_textView];
    
    [_textView becomeFirstResponder];
    
    float y = _textView.frame.size.height + 10.0;
    float x = 10.0;
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(10.0, y, 60, 40)];
    [button setTitle:@"GP" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button.layer.borderWidth = 1;
    [button addTarget:self action:@selector(addImageAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    x += (10 + button.frame.size.width);
    button = [[UIButton alloc] initWithFrame:CGRectMake(x, y, 60, 40)];
    [button setTitle:@"FF" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button.layer.borderWidth = 1;
    [button addTarget:self action:@selector(addFFMPEGAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    x += (10 + button.frame.size.width);
    button = [[UIButton alloc] initWithFrame:CGRectMake(x, y, 60, 40)];
    [button setTitle:@"SYS" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button.layer.borderWidth = 1;
    [button addTarget:self action:@selector(addSystemAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)addImageAction
{
    TestGPViewController *gp = [[TestGPViewController alloc] init];
    [self.navigationController pushViewController:gp animated:YES];
}

- (void)addFFMPEGAction
{
    TestMediaViewController *test = [[TestMediaViewController alloc] init];
    [self.navigationController pushViewController:test animated:YES];
}

- (void)addSystemAction
{
    FUCameraViewController *cc = [[FUCameraViewController alloc] init];
    [self.navigationController pushViewController:cc animated:YES];
}




- (void)test
{
    NSString *text = @"<video src=\"http://www.baidu.com\"><p>Image 1:<video width=\"199\" src=\"_image/12/label\" alt=\"\"/> Image 2: <video width=\"199\" src=\"_image/12/label\" alt=\"\"/><video width=\"199\" src=\"_image/12/label\" alt=\"\"/></p>";// @"fsdfdsf<img src=\"q\" type=1/>";//@"fsdfdsf<img src=q2 dsdss src=\"q\"/>";//
    NSString *regString = @"<video[^>]+src\\s*=\\s*['\"]([^'\"]+)['\"][^>]*>";//@"<img[^>]+src\\s*=\\s*['\"]([^'\"]+)['\"][^>]*>";
    
//    NSString *text = @"wewewwehttp://p.qpic.cn/wenwenpic/0/20160527145844-1440352223//10 fsdfsd";//@"http://pic.wenwen.soso.com/p/20160606/20160606101202-2129340660.jpgd";
//    NSString *regString = @"http://p.qpic.cn/wenwenpic/0/([\\d]+-[\\d]+)(/[\\d]+)?";//@"http://pic.wenwen.soso.com/p/\\d{8}/(\\d{1,}-\\d{1,}).jpg";
    
    [self testWithRegString:regString text:text needCon:YES];
}

- (void)testWithRegString:(NSString *)reg text:(NSString *)text needCon:(BOOL)needCon
{
    NSRegularExpression *richTextExp = [[NSRegularExpression alloc] initWithPattern:reg options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators error:nil];
    NSArray *array = [richTextExp matchesInString:text options:0 range:NSMakeRange(0, [text length])];
    NSInteger index = 0;
    NSLog(@"count====%@", @(array.count));
    for (NSTextCheckingResult *result in array)
    {
        if (result.range.location < index) continue;
        if (result.range.location >= text.length) break;
        NSString *normalStr = [text substringWithRange:NSMakeRange(index, result.range.location - index)];
        index = result.range.location;
        NSLog(@"====%@", normalStr);
        NSString *OKStr = [text substringWithRange:result.range];
        NSLog(@"----%@ %@", OKStr, [OKStr componentsSeparatedByString:@"\""]);
        if (needCon)
        {
            //            NSString *reg2 = @"src\\s*=\\s*\"?(.*?)(\"|>|\\s+)";
            //            [self testWithRegString:reg2 text:OKStr needCon:NO];
        }
        index = result.range.location + result.range.length;
    }
    if (index < text.length)
    {
        NSString *normalStr = [text substringWithRange:NSMakeRange(index, text.length-index)];
        NSLog(@"====%@", normalStr);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

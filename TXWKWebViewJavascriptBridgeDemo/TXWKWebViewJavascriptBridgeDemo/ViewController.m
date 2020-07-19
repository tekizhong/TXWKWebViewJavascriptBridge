//
//  ViewController.m
//  TXWKWebViewJavascriptBridgeDemo
//
//  Created by ztx on 2020/7/18.
//  Copyright © 2020 ztx. All rights reserved.
//
#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "TXWKWebViewJavascriptBridge.h"

@interface ViewController ()<WKNavigationDelegate>
/** <#statements#> */
@property (nonatomic, strong) WKWebView *webView;
/** <#statements#> */
@property (nonatomic, strong) TXWKWebViewJavaScriptBridge *bridge;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.webView];
    self.webView.frame = self.view.bounds;
    self.webView.navigationDelegate = self;
    
    UIButton *callButton = [UIButton buttonWithType:UIButtonTypeCustom];
    callButton.backgroundColor = [UIColor lightGrayColor];
    [callButton setTitle:@"CallHandler" forState:UIControlStateNormal];
    [callButton  addTarget:self action:@selector(callHandler) forControlEvents:UIControlEventTouchUpInside];
    callButton.frame = CGRectMake(10, self.view.frame.size.height - 80, self.view.frame.size.width * 0.4, 35);
    [self.view insertSubview:callButton aboveSubview:self.webView];
    
    UIButton *reloadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    reloadBtn.backgroundColor = [UIColor redColor];
    [reloadBtn setTitle:@"Reload WebView" forState:UIControlStateNormal];
    [reloadBtn addTarget:self action:@selector(reloadWebView) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:reloadBtn aboveSubview:self.webView];
    reloadBtn.frame = CGRectMake(self.view.frame.size.width * 0.6 - 10, self.view.frame.size.height - 80, self.view.frame.size.width *0.4, 35);

    self.bridge = [[TXWKWebViewJavaScriptBridge alloc] initWithWebview:self.webView];
    self.bridge.isOpenLog = YES;
    
    [self.bridge registerH5HandlerName:@"testiOSCallback" handler:^(NSDictionary * _Nonnull parameters, Callback  _Nonnull callback) {
        NSLog(@"testiOSCallback called:%@",parameters);
        if (callback) {
            callback(@"Response from testiOSCallback");
        }
    }];
    
    [self.bridge callH5HandlerName:@"testJavascriptHandler" data:@{@"foo":@"before ready"} callback:^(id  _Nonnull responseData) {
        NSLog(@"testJavascriptHandler :%@",responseData);
    }];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self callHandler];
//    });
    
    // Do any additional setup after loading the view.
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadDemoPage];
}


- (void)loadDemoPage {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Demo" ofType:@"html"];
    NSString *pageHtml = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL URLWithString:pageHtml];
    [self.webView loadHTMLString:pageHtml baseURL:baseURL];
}


- (void)callHandler {
    NSDictionary *data = @{@"greetingFromiOS": @"Hi there, JS!"};
    [self.bridge callH5HandlerName:@"testJavascriptHandler" data:data callback:^(id  _Nonnull responseData) {
        NSLog(@"testJavascriptHandler response:%@",responseData);
    }];
    
}

- (void)reloadWebView {
    [self loadDemoPage];
}


#pragma mark -  WKNavigationDelegate
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"webViewDidStartLoad");
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"webViewDidFinishLoad");
}



#pragma mark -  setter and getter
- (WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[[WKWebViewConfiguration alloc] init]];
    }
    return _webView;
}

@end

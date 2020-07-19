//
//  TXWKWebViewJavascriptBridge.m
//  TXWKWebViewJavascriptBridgeDemo
//
//  Created by ztx on 2020/7/18.
//  Copyright © 2020 ztx. All rights reserved.
//

#import "TXWKWebViewJavascriptBridge.h"
/** 避免内存泄漏 */
@interface LeakAvoider: NSObject<WKScriptMessageHandler>
/** <#statements#> */
@property (nonatomic, weak) id<WKScriptMessageHandler> delegate;

@end


@implementation LeakAvoider
- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate {
    if (self = [super init]) {
        self.delegate = delegate;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (self.delegate && [self.delegate respondsToSelector:@selector(userContentController:didReceiveScriptMessage:)]) {
        [self.delegate userContentController:userContentController didReceiveScriptMessage:message];
    }
}

@end

@interface TXWKWebViewJavaScriptBridge()<TXWKWebViewJavaScriptBridgeBaseDelegate,WKScriptMessageHandler>
- (void)addScriptMessageHandlers;
- (void)removeScriptMessageHandlers;
- (void)flushMessageQueue;
@end

@implementation TXWKWebViewJavaScriptBridge
- (instancetype)initWithWebview:(WKWebView *)webView {
    self = [super init];
    if (self) {
        _webView = webView;
        _base = [[TXWKWebViewJavascriptBridgeBase alloc] init];
        _base.delegate = self;
        [self addScriptMessageHandlers];
        _isOpenLog = NO;
    }
    return  self;
}

- (void)setIsOpenLog:(BOOL)isOpenLog {
    _isOpenLog = isOpenLog;
    _base.isOpenLog = isOpenLog;
}

- (void)dealloc {
    [self removeScriptMessageHandlers];
}

#pragma mark -  Public
- (void)reset {
    [self.base reset];
}


- (void)registerH5HandlerName:(NSString *)handlerName handler:(Handler)handler {
    self.base.messageHandlers[handlerName] = handler;
}

/// FIXME:已修改
- (void)removeHandlerName:(NSString *)handlerName {
    [self.base.messageHandlers removeObjectForKey:handlerName];
}

- (void)callH5HandlerName:(NSString *)handlername data:(id)data callback:(Callback)callback {
    [self.base sendHandleName:handlername data:data callback:callback];
}

#pragma mark -  Private methods
- (void)flushMessageQueue {
    __weak __typeof(self)weakSelf = self;
    [self.webView evaluateJavaScript:@"WKWebViewJavascriptBridge._fetchQueue();" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (error != nil) {
            if (strongSelf.isOpenLog) {
                TXLog(@"WKWebViewJavascriptBridge: WARNING: Error when trying to fetch data from WKWebView: %@",error);
            }
        }
        if (result) {
            [self.base flushMessageQueueString:result];
        }
    }];
}

- (void)addScriptMessageHandlers {
    [_webView.configuration.userContentController addScriptMessageHandler:[[LeakAvoider alloc] initWithDelegate:self] name:iOS_Native_InjectJavascript];
    [_webView.configuration.userContentController addScriptMessageHandler:[[LeakAvoider alloc] initWithDelegate:self] name:iOS_Native_FlushMessageQueue];
}

- (void)removeScriptMessageHandlers {
    [_webView.configuration.userContentController removeScriptMessageHandlerForName:iOS_Native_InjectJavascript];
    [_webView.configuration.userContentController removeScriptMessageHandlerForName:iOS_Native_FlushMessageQueue];
}


#pragma mark -  WKWebViewJavascriptBridgeBaseDelegate
- (void)evaluateJavascript:(NSString *)javascript {
    [self.webView evaluateJavaScript:javascript completionHandler:nil];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (message.name == iOS_Native_InjectJavascript) {
        [self.base injectJavascriptFile];
    }
    
    if (message.name == iOS_Native_FlushMessageQueue) {
        [self flushMessageQueue];
    }
}

@end


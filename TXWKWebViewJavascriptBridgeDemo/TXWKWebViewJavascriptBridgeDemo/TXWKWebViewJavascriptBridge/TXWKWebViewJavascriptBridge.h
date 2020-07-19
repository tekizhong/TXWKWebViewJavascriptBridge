//
//  TXWKWebViewJavascriptBridge.h
//  TXWKWebViewJavascriptBridgeDemo
//
//  Created by ztx on 2020/7/18.
//  Copyright © 2020 ztx. All rights reserved.
//
/**
 使用方法：
 
 1. 用 WKWebView 实例化 WKWebViewJavascriptBridge ：

 bridge = WKWebViewJavascriptBridge(webView: webView)
 
 2. 在 Native 中注册 Handler，调用 JS Handler ：

 bridge.register(handlerName: "testiOSCallback") { (paramters, callback) in
     print("testiOSCallback called: \(String(describing: paramters))")
     callback?("Response from testiOSCallback")
 }

 bridge.call(handlerName: "testJavascriptHandler", data: ["foo": "before ready"], callback: nil)
 
 3. 复制并粘贴 setupWKWebViewJavascriptBridge 到你的 JS 中：

 function setupWKWebViewJavascriptBridge(callback) {
     if (window.WKWebViewJavascriptBridge) { return callback(WKWebViewJavascriptBridge); }
     if (window.WKWVJBCallbacks) { return window.WKWVJBCallbacks.push(callback); }
     window.WKWVJBCallbacks = [callback];
     window.webkit.messageHandlers.iOS_Native_InjectJavascript.postMessage(null)
 }
 4. 最后，调用 setupWKWebViewJavascriptBridge 之后用 Bridge 来注册 Handlers 以及调用 Native Handlers ：

 setupWKWebViewJavascriptBridge(function(bridge) {

     // Initialize your app here
     bridge.registerHandler('testJavascriptHandler', function(data, responseCallback) {
         console.log('iOS called testJavascriptHandler with', data)
         responseCallback({ 'Javascript Says':'Right back atcha!' })
     })

     bridge.callHandler('testiOSCallback', {'foo': 'bar'}, function(response) {
         console.log('JS got response', response)
     })
 })
 */


#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "TXWKWebViewJavascriptBridgeBase.h"

NS_ASSUME_NONNULL_BEGIN
static NSString *iOS_Native_InjectJavascript = @"iOS_Native_InjectJavascript";
static NSString *iOS_Native_FlushMessageQueue = @"iOS_Native_FlushMessageQueue";


@interface TXWKWebViewJavaScriptBridge : NSObject
/** 桥接的webView */
@property (nonatomic, weak) WKWebView *webView;
/**  */
@property (nonatomic, strong) TXWKWebViewJavascriptBridgeBase *base;

/** 是否开启日志打印 默认否 */
@property (nonatomic, assign) BOOL isOpenLog;

- (instancetype)initWithWebview:(WKWebView *)webView;

- (void)reset;

/// 注册H5方法
/// @param handlerName H5方法名
/// @param handler (^Handler)(NSDictionary *parameters,Callback callback); parameters是H5传过来的参数 callback是回调给H5的数据
- (void)registerH5HandlerName:(NSString *)handlerName handler:(Handler)handler;

- (void)removeHandlerName:(NSString *)handlerName;

/// 调用H5方法
/// @param handlername 将被调起的H5方法名
/// @param data 传给H5那边的参数
/// @param callback H5给的回调
- (void)callH5HandlerName:(NSString *)handlername data:(id)data callback:(Callback)callback;


@end

NS_ASSUME_NONNULL_END

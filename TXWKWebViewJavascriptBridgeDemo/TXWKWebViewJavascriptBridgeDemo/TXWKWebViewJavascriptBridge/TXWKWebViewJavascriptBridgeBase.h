//
//  TXWKWebViewJavascriptBridgeBase.h
//  TXWKWebViewJavascriptBridgeDemo
//
//  Created by ztx on 2020/7/18.
//  Copyright © 2020 ztx. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef DEBUG
#define TXLog(...) printf("[%s] %s [第%d行]: %s\n", __TIME__ ,__PRETTY_FUNCTION__ ,__LINE__, [[NSString stringWithFormat:__VA_ARGS__] UTF8String])
#else
#define TXLog(...)
#endif

@protocol TXWKWebViewJavaScriptBridgeBaseDelegate <NSObject>

- (void)evaluateJavascript:(NSString *)javascript;


@end

typedef void(^Callback)(id responseData);
typedef void(^Handler)(NSDictionary *parameters,Callback callback);


@interface TXWKWebViewJavascriptBridgeBase : NSObject

/** 代理 */
@property (nonatomic, weak) id<TXWKWebViewJavaScriptBridgeBaseDelegate> delegate;
/** 是否开启日志打印 */
@property (nonatomic, assign) BOOL isOpenLog;

/** <#statements#> */
@property (nonatomic, strong) NSMutableDictionary *messageHandlers;

- (void)reset;

- (void)sendHandleName:(NSString *)handlerName data:(id)data  callback:(Callback)callback;

- (void)injectJavascriptFile;

- (void)flushMessageQueueString:(NSString *)messageQueueString;



@end

NS_ASSUME_NONNULL_END



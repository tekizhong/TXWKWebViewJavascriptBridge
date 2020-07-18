//
//  TXWKWebViewJavascriptBridgeBase.m
//  TXWKWebViewJavascriptBridgeDemo
//
//  Created by ztx on 2020/7/18.
//  Copyright © 2020 ztx. All rights reserved.
//

#import "TXWKWebViewJavascriptBridgeBase.h"
#import "TXWKWebViewJavascriptBridgeJS.h"

@interface TXWKWebViewJavascriptBridgeBase() {
    NSInteger uniqueId;
}

/** statements */
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *startupMessageQueue;
/** <#statements#> */
@property (nonatomic, strong) NSMutableDictionary *responseCallbacks;
@end

@implementation TXWKWebViewJavascriptBridgeBase
- (instancetype)init {
    if (self = [super init]) {
        [self reset];
    }
    return self;
}

- (void)reset {
    uniqueId = 0;
    _isOpenLog = NO;
    _startupMessageQueue = [[NSMutableArray alloc] initWithCapacity:0];
    _responseCallbacks = [[NSMutableDictionary alloc] initWithCapacity:0];
    _messageHandlers = [[NSMutableDictionary alloc] initWithCapacity:0];
}

- (void)sendHandleName:(NSString *)handlerName data:(id)data  callback:(Callback)callback  {
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    message[@"handlerName"] = handlerName;
    if (data != nil) {
        message[@"data"] = data;
    }
    
    if (callback != nil) {
        uniqueId += 1;
        NSString *callbakID = [NSString stringWithFormat:@"native_iOS_cb_%ld",uniqueId];
        _responseCallbacks[callbakID] = callback;
        message[@"callbackID"] = callbakID;
    }
    [self queueMessage:message];
    
}

- (void)flushMessageQueueString:(NSString *)messageQueueString {
    NSArray *messages = [self deserializeMessageJSON:messageQueueString];
    if (messages.count == 0) {
        if (self.isOpenLog) {TXLog(@"解析数据为空");}
        return;
    }
    
    for (NSDictionary *message in messages ) {
        if (self.isOpenLog) {TXLog(@"message:%@",message);}
        NSString *responseID = message[@"responseID"];
        if (responseID) { //这里是
            Callback callback = self.responseCallbacks[responseID];
            if (callback) {
                callback(message[@"responseData"]);
            }
            // 将本次的回调事件移除
            [self.responseCallbacks removeObjectForKey:responseID];
        }else {
            NSString *callbackID = message[@"callbackID"];
            Callback callback = nil;
            if (callbackID) {
                callback = ^(id responseData) {
                    if (responseData) {
                        NSDictionary *msg = @{@"responseID": callbackID,@"responseData":responseData};
                        [self queueMessage:msg];
                    }
                };
            }
            NSString *handlerName = message[@"handlerName"];
            if (handlerName.length == 0) {return;}
            Handler handler = self.messageHandlers[handlerName];
            if (!handler) {
                if (self.isOpenLog) {
                    TXLog(@"NoHandlerException, No handler for message from JS: %@",message);
                }
                return;
            }
            handler(message[@"data"],callback);
        }
        
    }
}

- (void)injectJavascriptFile {

    NSError *error = nil;
    NSString *js = TXWebViewJavascriptBridge_js();
    if (!error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(evaluateJavascript:)]) {
            [self.delegate evaluateJavascript:js];
        }
    }else{
        if (self.isOpenLog) {
            TXLog(@"读取js失败");
        }
    }
}

#pragma mark -  private
- (void)queueMessage:(NSDictionary *)message {
    if (_startupMessageQueue.count == 0) {
        [self dispatchMessage:message];
    }else {
        [_startupMessageQueue addObject:message];
    }
}

- (void)dispatchMessage:(NSDictionary *)message {
    NSString *messageJSON = [self serializeMessage:message pretty:NO];
    
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\u{000C}" withString:@"\\f"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\u{2028}" withString:@"\\\u2028"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\u{2029}" withString:@"\\\u2029"];
    
    NSString *javascriptCommand =  [NSString stringWithFormat:@"WKWebViewJavascriptBridge._handleMessageFromiOS('%@');",messageJSON];
    if ([[NSThread currentThread] isMainThread]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(evaluateJavascript:)]) {
            [self.delegate evaluateJavascript:javascriptCommand];
        }
    }else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(evaluateJavascript:)]) {
                [self.delegate evaluateJavascript:javascriptCommand];
            }
        });
    }
    
}

#pragma mark -  JSON
- (NSString *)serializeMessage:(NSDictionary *)message pretty:(BOOL)pretty {
    NSString *result = @"";
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:message options:pretty?NSJSONWritingPrettyPrinted:NSJSONWritingFragmentsAllowed error:&error];
    if (error) {
        if (self.isOpenLog) {
            TXLog(@"JSON序列化出错");
        }
    }
    result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return result;
    
}

- (NSArray *)deserializeMessageJSON:(NSString *)messageJSON {
    NSData *data = [messageJSON dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        if (self.isOpenLog) {
            TXLog(@"JSON反序列化失败");
        }
    }
    return array;
}

@end

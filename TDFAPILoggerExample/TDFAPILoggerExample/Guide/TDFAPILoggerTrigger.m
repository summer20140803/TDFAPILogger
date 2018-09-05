//
//  TDFAPILoggerTrigger.m
//  Pods
//
//  Created by 开不了口的猫 on 2017/9/8.
//
//

#import "TDFAPILoggerTrigger.h"
#import "TDFAPILogger.h"
#import <UIKit/UIKit.h>

@implementation TDFAPILoggerTrigger

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __weak __typeof(NSNotificationCenter *) center = [NSNotificationCenter defaultCenter];
        __block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            // 这里开始定制API日志输出的元素组成
//            [TDFAPILogger sharedInstance].requestLoggerElements = \
//                            TDFAPILoggerRequestElementTakeOffTime |
//                            TDFAPILoggerRequestElementMethod |
//                            TDFAPILoggerRequestElementVaildURL |
//                            TDFAPILoggerRequestElementHeaderFields |
//                            TDFAPILoggerRequestElementHTTPBody |
//                            TDFAPILoggerRequestElementTaskIdentifier;
//
//            [TDFAPILogger sharedInstance].responseLoggerElements = \
//                            TDFAPILoggerResponseElementLandTime |
//                            TDFAPILoggerResponseElementTimeConsuming |
//                            TDFAPILoggerResponseElementMethod |
//                            TDFAPILoggerResponseElementVaildURL |
//                            TDFAPILoggerResponseElementHeaderFields |
//                            TDFAPILoggerResponseElementStatusCode |
//                            TDFAPILoggerResponseElementResponse |
//                            TDFAPILoggerResponseElementTaskIdentifier;
            
            // 这里开始定制API日志筛选规则
            [TDFAPILogger sharedInstance].loggerFilter = ^BOOL(__kindof NSURLRequest const *request) {
                /*
                 if (不满足输出的条件) {
                     return NO;
                 }
                 */
                return YES;
            };
            
            // 这里开始定制API日志状态分割线的字符
//            TDFAPILoggerRequestLogIcon = "⚽️";
//            TDFAPILoggerResponseLogIcon = "🏀";
//            TDFAPILoggerErrorLogIcon = "🏓";
            
            // 这里开始添加请求URL的server path白名单，不在白名单的都会被屏蔽
//            [TDFAPILogger sharedInstance].serverModuleWhiteList = @[@"server_path1", @"server_path2"];
            
            // 这里开始设置每个API默认的taskDescription的拥有者
            [TDFAPILogger sharedInstance].defaultTaskDescriptionObj = nil;
            
            // 这里开启API日志
            // 现已默认会开启日志系统，可以使用TDFAPILogger#close方法手动关闭
//            [[TDFAPILogger sharedInstance] open];
            
            [center removeObserver:observer name:UIApplicationDidFinishLaunchingNotification object:nil];
        }];
    });
}

@end

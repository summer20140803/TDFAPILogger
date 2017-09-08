//
//  TDFAPILoggerTrigger.m
//  Pods
//
//  Created by 开不了口的猫 on 2017/9/8.
//
//

#import "TDFAPILoggerTrigger.h"
#import "TDFAPILogger.h"
//#import "TDFHTTPClient.h"

@implementation TDFAPILoggerTrigger

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
//        [TDFAPILogger sharedInstance].requestLoggerElements = TDFAPILoggerRequestElementHTTPBody;
//        [TDFAPILogger sharedInstance].responseLoggerElements = TDFAPILoggerResponseElementResponse;

//        [TDFAPILogger sharedInstance].loggerFilter = ^BOOL(__kindof NSURLRequest const *request) {
//            return YES;
//        };
//        TDFAPILoggerRequestLogIcon = "⚽️";
//        TDFAPILoggerResponseLogIcon = "🏀";
//        TDFAPILoggerErrorLogIcon = "🏓";
//        [TDFAPILogger sharedInstance].serverModuleWhiteList = @[@"customer_manager", @"income"];
//        [TDFAPILogger sharedInstance].defaultTaskDescriptionObj = [TDFHTTPClient sharedInstance];
//        [[TDFAPILogger sharedInstance] open];
    });
}

@end

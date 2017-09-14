//
//  TDFAPILogger.m
//  Pods
//
//  Created by 开不了口的猫 on 2017/9/5.
//
//

#import "TDFAPILogger.h"
#import <AFNetworking/AFURLSessionManager.h>
#import <objc/runtime.h>

typedef void (^tdfJsonResponsePrettyPrintFormatBlock)(id betterResponseString);
typedef void (^tdfHttpBodyStreamParseBlock)(NSData *streamData);
static dispatch_queue_t _tdfJsonResponseFormatQueue;

BOOL   TDFAPILoggerEnabled         = YES;
char  *TDFAPILoggerRequestLogIcon  = "✈️";
char  *TDFAPILoggerResponseLogIcon = "☀️";
char  *TDFAPILoggerErrorLogIcon    = "❌";


static NSURLRequest * TDFAPILoggerRequestFromAFNNotification(NSNotification *notification) {
    NSURLSessionTask *task = notification.object;
    NSURLRequest *request = task.originalRequest ?: task.currentRequest;
    return request;
}

static NSURLResponse * TDFAPILoggerResponseFromAFNNotification(NSNotification *notification) {
    NSURLSessionTask *task = notification.object;
    NSURLResponse *response = task.response;
    return response;
}

static NSError * TDFAPILoggerErrorFromAFNNotification(NSNotification *notification) {
    NSURLSessionTask *task = notification.object;
    NSError *error = task.error ?: notification.userInfo[AFNetworkingTaskDidCompleteErrorKey];
    return error;
}

static NSString * TDFAPILoggerTaskIdentifierFromAFNNotification(NSNotification *notification) {
    NSURLSessionTask *task = notification.object;
    NSString *taskIdentifier = @(task.taskIdentifier).stringValue;
    return taskIdentifier;
}

static const char* TDFAPILoggerMarkedLine(char* c, uint length) {
    NSMutableString *foldLeft = @"".mutableCopy;
    [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, length)] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [foldLeft appendString:[NSString stringWithUTF8String:c]];
    }];
    return [[foldLeft copy] UTF8String];
}

static void TDFAPILoggerAsyncJsonResponsePrettyFormat(id response, tdfJsonResponsePrettyPrintFormatBlock block) {
    if (![NSJSONSerialization isValidJSONObject:response]) {
        !block ?: block(response);
        return;
    }
    dispatch_barrier_async(_tdfJsonResponseFormatQueue, ^{
        NSError *formatError = nil;
        NSString *prettyJsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:response options:NSJSONWritingPrettyPrinted error:&formatError] encoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            id better = formatError ? response : prettyJsonString;
            !block ?: block(better);
        });
    });
}

static void TDFAPILoggerAsyncHttpBodyStreamParse(NSInputStream *originBodyStream, tdfHttpBodyStreamParseBlock block) {
    
    // this is a bug may cause image can't upload when other thread read the same bodystream
    // copy origin body stream and use the new can avoid this issure
    NSInputStream *bodyStream = [originBodyStream copy];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [bodyStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [bodyStream open];
        
        uint8_t *buffer = NULL;
        NSMutableData *streamData = [NSMutableData data];
        
        while ([bodyStream hasBytesAvailable]) {
            buffer = (uint8_t *)malloc(sizeof(uint8_t) * 1024);
            NSInteger length = [bodyStream read:buffer maxLength:sizeof(uint8_t) * 1024];
            if (bodyStream.streamError || length <= 0) {
                break;
            }
            [streamData appendBytes:buffer length:length];
            free(buffer);
        }
        [bodyStream close];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            !block ?: block([streamData copy]);
        });
    });
}

static void TDFAPILoggerShowRequest(NSString *fmrtStr) {
#if DEBUG
    if (TDFAPILoggerEnabled) {
        printf("\n%s", TDFAPILoggerMarkedLine(TDFAPILoggerRequestLogIcon, 17));
        printf("  ← 请求日志 →  ");
        printf("%s\n", TDFAPILoggerMarkedLine(TDFAPILoggerRequestLogIcon, 17));
        printf("%s\n", [fmrtStr UTF8String]);
        printf("\n%s\n", TDFAPILoggerMarkedLine(TDFAPILoggerRequestLogIcon, 40));
    }
#endif
}

static void TDFAPILoggerShowResponse(NSString *fmrtStr) {
#if DEBUG
    if (TDFAPILoggerEnabled) {
        printf("\n%s", TDFAPILoggerMarkedLine(TDFAPILoggerResponseLogIcon, 17));
        printf("  ← 响应日志 →  ");
        printf("%s\n", TDFAPILoggerMarkedLine(TDFAPILoggerResponseLogIcon, 17));
        printf("%s\n", [fmrtStr UTF8String]);
        printf("\n%s\n", TDFAPILoggerMarkedLine(TDFAPILoggerResponseLogIcon, 40));
    }
#endif
}

static void TDFAPILoggerShowError(NSString *fmrtStr) {
#if DEBUG
    if (TDFAPILoggerEnabled) {
        printf("\n%s", TDFAPILoggerMarkedLine(TDFAPILoggerErrorLogIcon, 17));
        printf("  ← 异常日志 →  ");
        printf("%s\n", TDFAPILoggerMarkedLine(TDFAPILoggerErrorLogIcon, 17));
        printf("%s\n", [fmrtStr UTF8String]);
        printf("\n%s\n", TDFAPILoggerMarkedLine(TDFAPILoggerErrorLogIcon, 40));
    }
#endif
}

@implementation TDFAPILogger

+ (instancetype)sharedInstance {
    static TDFAPILogger *logger = nil;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        logger = [[self alloc] init];
        _tdfJsonResponseFormatQueue = dispatch_queue_create("TDFAPILogger.JsonResponsePrettyFormat", DISPATCH_QUEUE_CONCURRENT);
    });
    return logger;
}

- (instancetype)init {
    if (self = [super init]) {
        // default settings..
        _requestLoggerElements =
        TDFAPILoggerRequestElementTakeOffTime |
        TDFAPILoggerRequestElementMethod |
        TDFAPILoggerRequestElementVaildURL |
        TDFAPILoggerRequestElementHeaderFields |
        TDFAPILoggerRequestElementHTTPBody |
        TDFAPILoggerRequestElementTaskIdentifier;
        _responseLoggerElements =
        TDFAPILoggerResponseElementLandTime |
        TDFAPILoggerResponseElementTimeConsuming |
        TDFAPILoggerResponseElementMethod |
        TDFAPILoggerResponseElementVaildURL |
        TDFAPILoggerResponseElementHeaderFields |
        TDFAPILoggerResponseElementStatusCode |
        TDFAPILoggerResponseElementResponse |
        TDFAPILoggerResponseElementTaskIdentifier;
    }
    return self;
}

- (void)dealloc {
    [self close];
}

- (void)open {
#if DEBUG
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apiDidTakeOff:) name:AFNetworkingTaskDidResumeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apiDidLand:) name:AFNetworkingTaskDidCompleteNotification object:nil];
#endif
}

- (void)close {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - callback

static void * TDFAPILoggerTakeOffDate = &TDFAPILoggerTakeOffDate;

- (void)apiDidTakeOff:(NSNotification *)notification {
    NSURLRequest *request = TDFAPILoggerRequestFromAFNNotification(notification);
    
    if (!request && !(self.requestLoggerElements & 0x00) && (!self.loggerFilter || self.loggerFilter(request))) return;
    
    // In addition，check whiteList for shielding some needless api log..
    if (self.serverModuleWhiteList && self.serverModuleWhiteList.count) {
        NSString *urlStr = [request.URL absoluteString];
        
        for (NSString *whiteModule in self.serverModuleWhiteList) {
            if (whiteModule &&
                [whiteModule isKindOfClass:[NSString class]] &&
                [whiteModule stringByReplacingOccurrencesOfString:@" " withString:@""].length) {
                
                NSString *serverModule = [NSString stringWithFormat:@"/%@/", whiteModule];
                if ([urlStr containsString:serverModule]) {
                    goto nextStep_Req;
                }
            }
        }
        return;
    }
    
nextStep_Req:;
    objc_setAssociatedObject(notification.object, TDFAPILoggerTakeOffDate, [NSDate date], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    NSMutableString *frmtString = @"".mutableCopy;
    
    if (self.requestLoggerElements & TDFAPILoggerRequestElementTaskIdentifier) {
        NSString *taskIdentifier = TDFAPILoggerTaskIdentifierFromAFNNotification(notification);
        [frmtString appendFormat:@"\n<API序列号> %@", taskIdentifier];
    }
    
    NSURLSessionTask *task = (NSURLSessionTask *)notification.object;
    NSUInteger taskDescLength = [task.taskDescription stringByReplacingOccurrencesOfString:@" " withString:@""].length;
    if (self.defaultTaskDescriptionObj) {
        NSString *taskDescriptionSetByAFN = [NSString stringWithFormat:@"%p", self.defaultTaskDescriptionObj];
        if (taskDescLength && ![task.taskDescription isEqualToString:taskDescriptionSetByAFN]) {
            [frmtString appendFormat:@"\n<API描述>    %@", task.taskDescription];
        }
    } else {
        if (taskDescLength) {
            [frmtString appendFormat:@"\n<API描述>    %@", task.taskDescription];
        }
    }
    
    if (self.requestLoggerElements & TDFAPILoggerRequestElementTakeOffTime) {
        NSDateFormatter * df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *timeStr = [df stringFromDate:objc_getAssociatedObject(notification.object, TDFAPILoggerTakeOffDate)];
        [frmtString appendFormat:@"\n<起飞时间>  %@", timeStr];
    }
    
    if (self.requestLoggerElements & TDFAPILoggerRequestElementMethod) {
        [frmtString appendFormat:@"\n<请求方式>  %@", request.HTTPMethod];
    }
    
    if (self.requestLoggerElements & TDFAPILoggerRequestElementVaildURL) {
        [frmtString appendFormat:@"\n<请求地址>  %@", [request.URL absoluteString]];
    }
    
    if (self.requestLoggerElements & TDFAPILoggerRequestElementHeaderFields) {
        NSDictionary *headerFields = request.allHTTPHeaderFields;
        NSMutableString *headerFieldFrmtStr = @"".mutableCopy;
        [headerFields enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [headerFieldFrmtStr appendFormat:@"\n\t\"%@\" = \"%@\"", key, obj];
        }];
        [frmtString appendFormat:@"\n<HeaderFields>%@", headerFieldFrmtStr];
    }
    
    if (self.requestLoggerElements & TDFAPILoggerRequestElementHTTPBody) {
        __block id httpBody = nil;
        
        if ([request HTTPBody]) {
            httpBody = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
        }
        // if a request does not set HTTPBody, so here it's need to check HTTPBodyStream
        else if ([request HTTPBodyStream]) {
            NSInputStream *httpBodyStream = request.HTTPBodyStream;
            
            TDFAPILoggerAsyncHttpBodyStreamParse(httpBodyStream, ^(NSData *streamData) {
                httpBody = streamData;
                [frmtString appendFormat:@"\n<Body>\n\t%@", httpBody];
                
                TDFAPILoggerShowRequest([frmtString copy]);
                
                !self.requestLogReporter ?: self.requestLogReporter([frmtString copy]);
            });
            return;
        }
        
        if ([httpBody isKindOfClass:[NSString class]] && [(NSString *)httpBody length]) {
            NSMutableString *httpBodyStr = @"".mutableCopy;
            
            NSArray *params = [httpBody componentsSeparatedByString:@"&"];
            [params enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSArray *pair = [obj componentsSeparatedByString:@"="];
                
                NSString *key = nil;
                if ([pair.firstObject respondsToSelector:@selector(stringByRemovingPercentEncoding)]) {
                    key = [pair.firstObject stringByRemovingPercentEncoding];
                }else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                    key = [pair.firstObject stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
                }
                
                NSString *value = nil;
                if ([pair.lastObject respondsToSelector:@selector(stringByRemovingPercentEncoding)]) {
                    value = [pair.lastObject stringByRemovingPercentEncoding];
                }else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                    value = [pair.lastObject stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
                }
                value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
                
                [httpBodyStr appendFormat:@"\n\t\"%@\" = \"%@\"", key, value];
            }];
            
            [frmtString appendFormat:@"\n<Body>%@", httpBodyStr];
        }
    }
    
    TDFAPILoggerShowRequest([frmtString copy]);
    
    !self.requestLogReporter ?: self.requestLogReporter([frmtString copy]);
}

- (void)apiDidLand:(NSNotification *)notification {
    NSURLRequest *request = TDFAPILoggerRequestFromAFNNotification(notification);
    NSURLResponse *response = TDFAPILoggerResponseFromAFNNotification(notification);
    NSError *error = TDFAPILoggerErrorFromAFNNotification(notification);
    
    if (!request && !response && !(self.responseLoggerElements & 0x00) && (!self.loggerFilter || self.loggerFilter(request))) return;
    
    // In addition，check whiteList for shielding some needless api log..
    if (self.serverModuleWhiteList && self.serverModuleWhiteList.count) {
        NSString *urlStr = [request.URL absoluteString];
        
        for (NSString *whiteModule in self.serverModuleWhiteList) {
            if (whiteModule &&
                [whiteModule isKindOfClass:[NSString class]] &&
                [whiteModule stringByReplacingOccurrencesOfString:@" " withString:@""].length) {
                
                NSString *serverModule = [NSString stringWithFormat:@"/%@/", whiteModule];
                if ([urlStr containsString:serverModule]) {
                    goto nextStep_Resp;
                }
            }
        }
        return;
    }
    
nextStep_Resp:;
    NSInteger responseStatusCode = 0;
    NSDictionary *responseHeaderFields = nil;
    // NSHTTPURLResponse inherit NSURLResponse，it has statusCode and allHeaderFields prop..
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        responseStatusCode = [(NSHTTPURLResponse *)response statusCode];
        responseHeaderFields = [(NSHTTPURLResponse *)response allHeaderFields];
    }
    
    NSMutableString *frmtString = @"".mutableCopy;
    // avoid compile time deviation..
    NSDate *landDate = [NSDate date];
    
    if (self.responseLoggerElements & TDFAPILoggerResponseElementTaskIdentifier) {
        NSString *taskIdentifier = TDFAPILoggerTaskIdentifierFromAFNNotification(notification);
        [frmtString appendFormat:@"\n<API序列号> %@", taskIdentifier];
    }
    
    NSURLSessionTask *task = (NSURLSessionTask *)notification.object;
    NSUInteger taskDescLength = [task.taskDescription stringByReplacingOccurrencesOfString:@" " withString:@""].length;
    if (self.defaultTaskDescriptionObj) {
        NSString *taskDescriptionSetByAFN = [NSString stringWithFormat:@"%p", self.defaultTaskDescriptionObj];
        if (taskDescLength && ![task.taskDescription isEqualToString:taskDescriptionSetByAFN]) {
            [frmtString appendFormat:@"\n<API描述>    %@", task.taskDescription];
        }
    } else {
        if (taskDescLength) {
            [frmtString appendFormat:@"\n<API描述>    %@", task.taskDescription];
        }
    }
    
    if (self.responseLoggerElements & TDFAPILoggerResponseElementLandTime) {
        NSDateFormatter * df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *timeStr = [df stringFromDate:landDate];
        [frmtString appendFormat:@"\n<着陆时间>  %@", timeStr];
    }
    
    if (self.responseLoggerElements & TDFAPILoggerResponseElementTimeConsuming) {
        NSTimeInterval timeConsuming = [landDate timeIntervalSinceDate:objc_getAssociatedObject(notification.object, TDFAPILoggerTakeOffDate)];
        NSString *secondConsuming = [NSString stringWithFormat:@"%.3f秒", timeConsuming];
        [frmtString appendFormat:@"\n<请求耗时>  %@", secondConsuming];
    }
    
    if (self.responseLoggerElements & TDFAPILoggerResponseElementMethod) {
        [frmtString appendFormat:@"\n<请求方式>  %@", request.HTTPMethod];
    }
    
    if (self.responseLoggerElements & TDFAPILoggerResponseElementStatusCode) {
        if (responseStatusCode) {
            [frmtString appendFormat:@"\n<状态码>     %ld", responseStatusCode];
        }
    }
    
    if (self.responseLoggerElements & TDFAPILoggerResponseElementVaildURL) {
        [frmtString appendFormat:@"\n<请求地址>  %@", [request.URL absoluteString]];
    }
    
    if (self.responseLoggerElements & TDFAPILoggerResponseElementHeaderFields) {
        if (responseHeaderFields) {
            NSMutableString *headerFieldFrmtStr = @"".mutableCopy;
            [responseHeaderFields enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [headerFieldFrmtStr appendFormat:@"\n\t\"%@\" = \"%@\"", key, obj];
            }];
            [frmtString appendFormat:@"\n<HeaderFields>%@", headerFieldFrmtStr];
        }
    }
    
    if (self.responseLoggerElements & TDFAPILoggerResponseElementResponse) {
        if (error) {
            [frmtString appendFormat:@"\n<Error>\n\tErrorDomain = %@\n\tCode = %ld\n\tLocalizedDescription = %@", error.domain, error.code, error.localizedDescription];
        } else {
            // JSON pretty print format, by async to improve performance..
            id serializedResponse = notification.userInfo[AFNetworkingTaskDidCompleteSerializedResponseKey];
            
            __weak __typeof(self) w_self = self;
            TDFAPILoggerAsyncJsonResponsePrettyFormat(serializedResponse, ^(id betterResponseString) {
                __strong __typeof(w_self) s_self = w_self;
                [frmtString appendFormat:@"\n<Response>\n%@", betterResponseString];
                
                TDFAPILoggerShowResponse([frmtString copy]);
                !s_self.responseLogReporter ?: s_self.responseLogReporter([frmtString copy]);
            });
            return;
        }
    }
    
    if (error) {
        TDFAPILoggerShowError([frmtString copy]);
        !self.errorLogReporter ?: self.errorLogReporter([frmtString copy]);
    } else {
        TDFAPILoggerShowResponse([frmtString copy]);
        !self.responseLogReporter ?: self.responseLogReporter([frmtString copy]);
    }
}

@end

//
//  CMAMNetworkManager.m
//  CMMediaCallDemo
//
//  Created by yao on 2018/1/31.
//  Copyright © 2018年 王智垚. All rights reserved.
//

#import "CMAMNetworkManager.h"

@implementation CMAMNetworkManager
+ (void)postWithUrlString:(NSString *)url parameters:(id)parameters success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock {
    if (parameters == nil) {
        return;
    }
    NSURL *nsurl = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsurl];
    
    //设置请求类型
    request.HTTPMethod = @"POST";
    
    NSMutableString *postStr = [NSMutableString stringWithFormat:@""];
    
    if ([parameters allKeys]) {
        
        for (id key in parameters) {
            NSString *value = [[parameters objectForKey:key] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [postStr appendString:[NSString stringWithFormat:@"%@=%@&", key, value]];
        }
    }
    
    //把参数放到请求体内
    request.HTTPBody = [postStr dataUsingEncoding:NSUTF8StringEncoding];
    NSURLSession *session
    = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                    delegate:nil
                               delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *returnCode = nil;
        NSString *errorMessage = nil;
        NSDictionary *bean = nil;
        if (data) {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            returnCode = dic[@"returnCode"];
            bean = dic[@"bean"];
            errorMessage = dic[@"returnMessage"];
        }
        
        if (!error && [returnCode isEqualToString:@"0"]) {
            //请求成功
            successBlock(bean,(NSHTTPURLResponse *) response);
        }else{
            //请求失败
            failureBlock(error,(NSHTTPURLResponse *) response);
        }
    }];
    [dataTask resume];  //开始请求
}
@end

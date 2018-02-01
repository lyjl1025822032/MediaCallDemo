//
//  CMAMNetworkManager.h
//  CMMediaCallDemo
//
//  Created by yao on 2018/1/31.
//  Copyright © 2018年 王智垚. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^SuccessBlock)(NSDictionary *bean,NSHTTPURLResponse *httpResponse);
typedef void (^FailureBlock)(NSError *error,NSHTTPURLResponse *httpResponse);

@interface CMAMNetworkManager : NSObject<NSURLSessionDelegate>
/**
 post请求
 
 @param url 请求地址
 @param parameters 参数
 @param successBlock 成功回调
 @param failureBlock 失败回调
 */
+ (void)postWithUrlString:(NSString *)url
               parameters:(id)parameters
                  success:(SuccessBlock)successBlock
                  failure:(FailureBlock)failureBlock;
@end

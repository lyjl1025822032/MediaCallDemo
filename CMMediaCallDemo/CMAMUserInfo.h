//
//  CMAMUserInfo.h
//  CMMediaCallDemo
//
//  Created by yao on 2018/1/31.
//  Copyright © 2018年 王智垚. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CMAMUserInfo : NSObject <NSCoding>
@property (nonatomic,copy) NSString *agentNo;
@property (nonatomic,copy) NSString *agentPassword;
@property (nonatomic,copy) NSString *enablevideo;    //  是否支持voip
@property (nonatomic,copy) NSString *sipport;
@property (nonatomic,copy) NSString *sipurl;
@property (nonatomic,copy) NSString *voipCallNo;
@property (nonatomic,copy) NSString *videoCallNo;

- (BOOL)isSupportVoip; // 是否支持voip
@end

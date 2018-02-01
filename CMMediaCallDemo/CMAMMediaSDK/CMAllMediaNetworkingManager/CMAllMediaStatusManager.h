//
//  CMAllMediaStatusManager.h
//  CmosAllMediaVoip
//
//  Created by yao on 2018/1/11.
//  Copyright © 2018年 liangscofield. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMAllMediaReachability.h"

@interface CMAllMediaStatusManager : NSObject
+ (instancetype)shareInstance;

- (void)startObserveNetworkStatus;

@property (nonatomic, copy)void(^netStatusBlock)(CMAllMediaNetworkStatus netStatus);

@property (nonatomic, assign)CMAllMediaNetworkStatus netStatus;

- (void)stopObserveNetworkiStatus;
@end

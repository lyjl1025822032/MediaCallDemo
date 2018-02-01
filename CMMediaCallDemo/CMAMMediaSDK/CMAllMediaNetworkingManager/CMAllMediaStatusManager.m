//
//  CMAllMediaStatusManager.m
//  CmosAllMediaVoip
//
//  Created by yao on 2018/1/11.
//  Copyright © 2018年 liangscofield. All rights reserved.
//

#import "CMAllMediaStatusManager.h"

@interface CMAllMediaStatusManager ()
@property (nonatomic) CMAllMediaReachability *reachability;
@end

@implementation CMAllMediaStatusManager
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static CMAllMediaStatusManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[CMAllMediaStatusManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)startObserveNetworkStatus {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kCMAllMediaReachabilityChangedNotification object:nil];
    self.reachability = [CMAllMediaReachability reachabilityForInternetConnection];
    [self.reachability startNotifier];
    [self updateInterfaceWithReachability:self.reachability];
}

- (void)reachabilityChanged:(NSNotification*)notifi {
    CMAllMediaReachability *reachability = [notifi object];
    NSParameterAssert([reachability isKindOfClass:[CMAllMediaReachability class]]);
    [self updateInterfaceWithReachability:reachability];
}

- (void)updateInterfaceWithReachability:(CMAllMediaReachability *)reachability {
    CMAllMediaNetworkStatus netStatus = [reachability currentReachabilityStatus];
    if (self.netStatusBlock) {
        self.netStatusBlock(netStatus);
    }
    self.netStatus = netStatus;
}

- (void)stopObserveNetworkiStatus {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCMAllMediaReachabilityChangedNotification object:nil];
    [self.reachability stopNotifier];
}
@end

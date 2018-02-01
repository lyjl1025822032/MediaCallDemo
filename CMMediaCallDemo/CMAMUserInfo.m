//
//  CMAMUserInfo.m
//  CMMediaCallDemo
//
//  Created by yao on 2018/1/31.
//  Copyright © 2018年 王智垚. All rights reserved.
//

#import "CMAMUserInfo.h"

@implementation CMAMUserInfo
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.agentNo = [aDecoder decodeObjectForKey:@"agentNo"];
        self.agentPassword = [aDecoder decodeObjectForKey:@"agentPassword"];
        self.enablevideo = [aDecoder decodeObjectForKey:@"enablevideo"];
        self.sipport = [aDecoder decodeObjectForKey:@"sipport"];
        self.sipurl = [aDecoder decodeObjectForKey:@"sipurl"];
        self.voipCallNo = [aDecoder decodeObjectForKey:@"voipCallNo"];
        self.videoCallNo = [aDecoder decodeObjectForKey:@"videoCallNo"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.agentNo forKey:@"agentNo"];
    [aCoder encodeObject:self.agentPassword forKey:@"agentPassword"];
    [aCoder encodeObject:self.enablevideo forKey:@"enablevideo"];
    [aCoder encodeObject:self.sipport forKey:@"sipport"];
    [aCoder encodeObject:self.sipurl forKey:@"sipurl"];
    [aCoder encodeObject:self.voipCallNo forKey:@"voipCallNo"];
    [aCoder encodeObject:self.videoCallNo forKey:@"videoCallNo"];
}

- (BOOL)isSupportVoip {
    return [self.enablevideo isEqualToString:@"1"];
}
@end

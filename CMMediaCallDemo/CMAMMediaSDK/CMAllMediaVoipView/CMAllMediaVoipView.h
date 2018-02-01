//
//  CMAllMediaVoipView.h
//  CmosAllMediaUI
//
//  Created by 王智垚 on 2017/9/12.
//  Copyright © 2017年 cmos. All rights reserved.
//  语音通话界面

#import <UIKit/UIKit.h>
#import "CMAllMediaRTCChatManager.h"

@interface CMAllMediaVoipView : UIView
/**
 * 语音通信回调
 *
 * @param state   语音通话状态
 * @param timeStr 通话时长
*/
@property(nonatomic, copy)void(^agoraVoipBlock)(CMAMRTCState state,NSString *timeStr);
//ws未连接
@property(nonatomic, copy)void(^wsLoseBlock)(void);
//点击了悬浮球放大
@property(nonatomic, copy)void(^enlargeBlock)(void);

//拨打语音通话
- (void)callVoipPhoneWithWithNumber:(NSString *)phoneNumber;
@end

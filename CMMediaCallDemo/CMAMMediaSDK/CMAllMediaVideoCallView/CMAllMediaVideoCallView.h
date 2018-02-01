//
//  CMAllMediaVideoCallView.h
//  CmosAllMedia
//
//  Created by yao on 2017/12/26.
//  Copyright © 2017年 liangscofield. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CMAllMediaRTCChatManager.h"

@protocol CMAllMediaVideoCallViewDelegate <NSObject>
/**
 * 语音通信回调
 *
 * @param state   语音通话状态
 * @param timeStr 通话时长
 */
- (void)videoCallFinishWithTimeLength:(NSString *)timeLength andState:(CMAMRTCState)state;
//ws未连接
- (void)webSocketLosingConnect;
//点击了悬浮球放大
- (void)handleEnlarge;
@end

@interface CMAllMediaVideoCallView : UIView
@property (nonatomic, weak)id <CMAllMediaVideoCallViewDelegate>delegate;

//发起视频通话
- (void)callVideoPhoneWithNumber:(NSString *)phoneNumber;
@end

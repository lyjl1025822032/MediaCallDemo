//
//  CMAllMediaRTCChatManager.h
//  CmosAllMedia
//
//  Created by yao on 2017/12/26.
//  Copyright © 2017年 liangscofield. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CMAMRTCState) {
    /** 1.发起语音 */
    //一.音频通话
    CMAMRTCStateAudioCalling = 1   ,
    //二.视频通话
    CMAMRTCStateVideoCalling       ,
    /** 2.语音来电 */
    //一.音频来电
    CMAMRTCStateAudioIncoming      ,
    //二.视频来电
    CMAMRTCStateVideoIncoming      ,
    /** 3.响铃中 */
    CMAMRTCStateEarly              ,
    /** 4.正连接通话 */
    CMAMRTCStateConnecting         ,
    /** 5.正通话中 */
    //一.远程正常
    CMAMRTCStateNormalConfirm      ,
    //二.远程无画面
    CMAMRTCStateNoRemoteConfirm    ,
    /** 6.挂断通话 */
    CMAMRTCStateDisconnect         ,
    /** 7.对方无应答 */
    CMAMRTCStateNoResponse         ,
};

@interface CMAllMediaRTCChatManager : NSObject
/** 初始化单例 **/
+ (CMAllMediaRTCChatManager *)sharedInstance;

//websocket连接回调
@property (nonatomic, copy) void(^wsConnectBlock)(BOOL resultFlag);

/** 语音通话状态回调 **/
@property (nonatomic, copy)void(^voipBlock)(CMAMRTCState state);
/** 语音通话状态回调 **/
@property (nonatomic, copy)void(^videoCallBlock)(CMAMRTCState state);

/** 语音是否接入正常 **/
@property (nonatomic, assign)BOOL isVoipNormal;

/** 上次通话是否存在 **/
@property (nonatomic, assign)BOOL isCallingFlag;

/** 重新连接WebSocket服务 注:websocket必须连接 */
- (void)reconnectWebSocketServer;

#pragma mark public
/**
 *  连接WebSocket服务并登录账号
 *
 *  @param webSocketDomain   domain
 *  @param domainPort        port
 *  @param username          用户名
 *  @param password          密码
 *  @param companyID         租户id
 *  @param completionBlock   登录回调
 */
- (void)connectWebSocketServerWithWebSocketDomain:(NSString *)webSocketDomain
                                    AndDomainPort:(NSString *)domainPort
                                      AndUsername:(NSString *)username
                                         password:(NSString *)password
                                        companyID:(NSString *)companyID
                                       completion:(void (^)(BOOL result, NSInteger errorCode))completionBlock;

//发起通话请求
- (void)callUserWithUserNumber:(NSString *)remoteNumber isVideoCall:(BOOL)isVideoCall repairOrderNumber:(NSString *)repairOrderNumber andSetupLargerPreview:(UIView *)largerPreview andShrinkView:(UIView *)shrinkView;

//收到通话来电
- (void)receiveAgoraCallIsVideoCall:(BOOL)isVideoCall andSetupLargerPreview:(UIView *)largerPreview andShrinkView:(UIView *)shrinkView;

//接受音视频来电
- (void)acceptIncomingAgoraCall;

/** 挂断语音 **/
- (void)hangupAgoraCallConnect;

/** 切换摄像头 */
- (void)switchLocalCamera;

/** 语音静音操作 */
- (void)changeIsSilenceWithFlag:(BOOL)flag;

/** 退出语音账号 **/
- (void)logoutAgoraAccount;

#pragma mark 语音通话
/** 发送DTMF数据 **/
- (void)sendDTMFDataString:(NSString *)dtmfStr;

/** 语音通讯播放路径 YES:扬声器 NO:听筒**/
- (void)changeVoiceWithLoudSpeaker:(BOOL)flag;

#pragma mark 视频通话
/** 切换视频大小屏 **/
- (void)switchVideoShrinkAndLargerView;
@end

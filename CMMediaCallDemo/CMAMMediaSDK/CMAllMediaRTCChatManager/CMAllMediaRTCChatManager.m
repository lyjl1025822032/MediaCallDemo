//
//  CMAllMediaRTCChatManager.m
//  CmosAllMedia
//
//  Created by yao on 2017/12/26.
//  Copyright © 2017年 liangscofield. All rights reserved.
//

#import "CMAllMediaRTCChatManager.h"
#import <AgoraSignal/AGSignalling.h>
#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>
#import "CMAllMediaStatusManager.h"

#define kCmosCallAppID @"7d6341755f2046b8ba49775ddc5b10e0"

@interface CMAllMediaRTCChatManager ()<AGSignallingDelegate, AgoraRtcEngineDelegate> {
    //拨打等待计时
    NSInteger earlyingTime;
    //切换标识
    BOOL switchFlag;
}
@property (nonatomic, weak) UIView *bigPreview;
@property (nonatomic, weak) UIView *smallPreview;

//信令对象
@property (nonatomic, strong) AGSignalling *agoraSignal;
//媒体对象
@property (nonatomic, strong) AgoraRtcEngineKit *agoraKit;

//本地渲染
@property (nonatomic, strong) AgoraRtcVideoCanvas *localVideoCanvas;
//远程渲染
@property (nonatomic, strong) AgoraRtcVideoCanvas *remoteVideoCanvas;
//登录结果回调
@property (nonatomic, copy) void(^loginResultBlock)(BOOL resultFlag,NSInteger errorCode);
//拨打结果回调
@property (nonatomic, copy) void(^callOutBlock)(BOOL resultFlag);
//是否是视频通话
@property (nonatomic, assign) BOOL isVideoCall;
//websocket连接地址
@property (nonatomic, strong) NSString *wsUrl;
//websocket连接标识
@property (nonatomic, assign) BOOL wsIsConnecting;
//通话计时
@property (nonatomic, strong) NSTimer *callingTimer;
@property (nonatomic, strong) CMAllMediaStatusManager *netManager;
@end

@implementation CMAllMediaRTCChatManager
//初始化单例
+ (instancetype)sharedInstance {
    static CMAllMediaRTCChatManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CMAllMediaRTCChatManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isCallingFlag = NO;
        self.netManager = [CMAllMediaStatusManager shareInstance];
    }
    return self;
}

#pragma mark Public
//1.连接WebSocket服务
- (void)connectWebSocketServerWithWebSocketDomain:(NSString *)webSocketDomain AndDomainPort:(NSString *)domainPort AndUsername:(NSString *)username password:(NSString *)password companyID:(NSString *)companyID completion:(void (^)(BOOL, NSInteger))completionBlock {
    if (!webSocketDomain.length || !domainPort.length || !username.length || !password.length) {
        completionBlock(NO,3200);
        return;
    }
    //app从后台唤醒
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActiveReconnect:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [_netManager startObserveNetworkStatus];
    self.wsUrl = [NSString stringWithFormat:@"http://%@:%@", webSocketDomain, domainPort];
    self.agoraSignal = [AGSignalling sharedSignallingController];
    _agoraSignal.delegate = self;
    _agoraSignal.appID = kCmosCallAppID;
    //连接websocket
    [_agoraSignal connectToServerWithUrl:self.wsUrl];
    __weak typeof(self)weakSelf = self;
    weakSelf.netManager.netStatusBlock = ^(CMAllMediaNetworkStatus netStatus) {
        if (netStatus == CMAllMediaNetworkStatusNotReachable) {
            weakSelf.isVoipNormal = NO;
        } else {
            if (!weakSelf.isVoipNormal) {
                [weakSelf reconnectWebSocketServer];
            }
        }
    };
    weakSelf.wsConnectBlock = ^(BOOL resultFlag) {
        if (resultFlag) {
            if (!username.length || !password.length) {
                return;
            }
            weakSelf.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:kCmosCallAppID delegate:weakSelf];
            
            //用户登录
            _agoraSignal = [AGSignalling sharedSignallingController];
            _agoraSignal.delegate = weakSelf;
            _agoraSignal.appID = kCmosCallAppID;
            [_agoraSignal authUserWithName:username password:password companyID:companyID];
            weakSelf.loginResultBlock = ^(BOOL resultFlag, NSInteger errorCode) {
                weakSelf.isVoipNormal = resultFlag?YES:NO;
                resultFlag?completionBlock(resultFlag,0):completionBlock(resultFlag,errorCode);
            };
        } else {
            weakSelf.isVoipNormal = NO;
            completionBlock(NO,3200);
        }
    };
}

//发起通话请求
- (void)callUserWithUserNumber:(NSString *)remoteNumber isVideoCall:(BOOL)isVideoCall repairOrderNumber:(NSString *)repairOrderNumber andSetupLargerPreview:(UIView *)largerPreview andShrinkView:(UIView *)shrinkView {
    switchFlag = YES;
    self.isVideoCall = isVideoCall;
    [_agoraSignal callOut:remoteNumber video:isVideoCall repairOrderNumber:repairOrderNumber];
    //app被杀死挂断语音
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:@"UIApplicationWillTerminateNotification" object:nil];
    
    if (isVideoCall) {
        [self configureVideoParm];
        self.bigPreview = largerPreview;
        self.smallPreview = shrinkView;
        
        self.localVideoCanvas.view = self.bigPreview;
        [self.agoraKit setupLocalVideo:NULL];
        [self.agoraKit setupLocalVideo:self.localVideoCanvas];
        [self.agoraKit setDefaultAudioRouteToSpeakerphone:YES];
        
        //开启预览
        [self.agoraKit startPreview];
    } else {
        [self changeProximityMonitorEnableState:YES];
    }
    
    __weak typeof(self)weakSelf = self;
    weakSelf.callOutBlock = ^(BOOL resultFlag) {
        if (resultFlag) {
            weakSelf.isCallingFlag = YES;
            [_agoraSignal ring];
            earlyingTime = 0;
            //30s等待响应计时
            weakSelf.callingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(callingTimerAction) userInfo:nil repeats:YES];
        }
    };
}

//30s等待接听
- (void)callingTimerAction {
    earlyingTime++;
    if (earlyingTime >= 30) {
        if (_isVideoCall) {
            if (self.videoCallBlock) {
                self.videoCallBlock(CMAMRTCStateNoResponse);
            }
        } else {
            if (self.voipBlock) {
                self.voipBlock(CMAMRTCStateNoResponse);
            }
        }
        [self hangupAgoraCallConnect];
    }
}

//收到通话来电
- (void)receiveAgoraCallIsVideoCall:(BOOL)isVideoCall andSetupLargerPreview:(UIView *)largerPreview andShrinkView:(UIView *)shrinkView {
    switchFlag = YES;
    self.isCallingFlag = YES;
    //app被杀死挂断语音
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:@"UIApplicationWillTerminateNotification" object:nil];
    
    if (isVideoCall) {
        [self configureVideoParm];
        self.bigPreview = largerPreview;
        self.smallPreview = shrinkView;
        
        self.localVideoCanvas.view = self.bigPreview;
        [self.agoraKit setupLocalVideo:NULL];
        [self.agoraKit setupLocalVideo:self.localVideoCanvas];
        [self.agoraKit setDefaultAudioRouteToSpeakerphone:YES];
        
        //开启预览
        [self.agoraKit startPreview];
    }
}

//接受通话来电
- (void)acceptIncomingAgoraCall {
    [_agoraSignal answer];
}

//重新连接WebSocket服务 注:websocket必须连接
- (void)reconnectWebSocketServer {
    //连接websocket
    [self.agoraSignal connectToServerWithUrl:self.wsUrl];
}

//切换摄像头
- (void)switchLocalCamera {
    [self.agoraKit switchCamera];
}

//语音静音操作
- (void)changeIsSilenceWithFlag:(BOOL)flag {
    [self.agoraKit muteLocalAudioStream:flag];
}

//挂断语音
- (void)hangupAgoraCallConnect {
    self.isCallingFlag = NO;
    [self.callingTimer invalidate];
    self.callingTimer = nil;
    [_agoraSignal hungup];
    if (_isVideoCall) {
        [self leaveChannel];
    } else {
        [self changeProximityMonitorEnableState:NO];
    }
}

//app从后台唤醒
- (void)becomeActiveReconnect:(UIApplication *)application {
    if (!self.isVoipNormal) {
        [self reconnectWebSocketServer];
    }
}

//app被杀死挂断
- (void)applicationWillTerminate:(UIApplication *)application {
    if (_isVideoCall) {
        if (self.videoCallBlock) {
            self.videoCallBlock(CMAMRTCStateDisconnect);
        }
    } else {
        if (self.voipBlock) {
            self.voipBlock(CMAMRTCStateDisconnect);
        }
    }
    [self hangupAgoraCallConnect];
}

// 退出语音账号断开websocket
- (void)logoutAgoraAccount {
    [self.agoraSignal cancelConnectToSignalServer];
    [self.agoraKit leaveChannel:nil];
}

#pragma mark 语音通话Private
// 发送DTMF数据
- (void)sendDTMFDataString:(NSString *)dtmfStr {
    [_agoraSignal dtmf:dtmfStr];
}

/** 语音通讯播放路径 YES:扬声器 NO:听筒**/
- (void)changeVoiceWithLoudSpeaker:(BOOL)flag {
    [self changeProximityMonitorEnableState:!flag]; dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_agoraKit setEnableSpeakerphone:flag];
    });
}

#pragma mark 视频通话Private
//1.配置视频参数
- (void)configureVideoParm {
    [self.agoraKit setChannelProfile:AgoraRtc_ChannelProfile_LiveBroadcasting];
    [self.agoraKit enableDualStreamMode:true];
    [self.agoraKit enableVideo];
    [self.agoraKit setVideoProfile:AgoraRtc_VideoProfile_360P swapWidthAndHeight:YES];
    [self.agoraKit setClientRole:AgoraRtc_ClientRole_Broadcaster withKey:nil];
}

//2.断开视频通话
- (void)leaveChannel {
    [self.agoraKit leaveChannel:nil];
    [self.agoraKit stopPreview];
    [self.agoraKit setupLocalVideo:NULL];
    [self configureIdleTimerActive:YES];
    [self.agoraKit setDefaultAudioRouteToSpeakerphone:NO];
}

//3.切换视频大小屏
- (void)switchVideoShrinkAndLargerView {
    if (switchFlag) {
        switchFlag = NO;
        self.remoteVideoCanvas.view = self.bigPreview;
        [self.agoraKit setupRemoteVideo:self.remoteVideoCanvas];
        
        self.localVideoCanvas.view = self.smallPreview;
        [self.agoraKit setupLocalVideo:self.localVideoCanvas];
    } else {
        switchFlag = YES;
        self.remoteVideoCanvas.view = self.smallPreview;
        [self.agoraKit setupRemoteVideo:self.remoteVideoCanvas];

        self.localVideoCanvas.view = self.bigPreview;
        [self.agoraKit setupLocalVideo:self.localVideoCanvas];
    }
}

#pragma mark AgoraSignalDelegate
// WebSocket连接成功
- (void)agsignalConnectSuccess:(AGSignalling *)agSignal {
    self.wsIsConnecting = YES;
    self.wsConnectBlock(YES);
}

// WebSocket连接失败
- (void)agsignal:(AGSignalling *)agSignal connectError:(NSError *)error {
    self.wsIsConnecting = NO;
    self.wsConnectBlock(NO);
    if (_isVideoCall) {
        if (self.videoCallBlock) {
            self.videoCallBlock(CMAMRTCStateDisconnect);
        }
    } else {
        if (self.voipBlock) {
            self.voipBlock(CMAMRTCStateDisconnect);
        }
    }
    [self hangupAgoraCallConnect];
}

//用户登录成功回调
- (void)agsignal:(AGSignalling *)agSignal loginSuccess:(nonnull NSDictionary *)result {
    self.loginResultBlock(YES, 0);
}

//用户登录失败回调
- (void)agsignal:(AGSignalling *)agSignal signalErrorCode:(AGSignalErrorCode)errorCode responseError:(NSDictionary *)error {
    if (errorCode==AGSignalErrorCode_AUTH_FAILED) {
        self.loginResultBlock(NO, errorCode);
        if (_isVideoCall) {
            if (self.videoCallBlock) {
                self.videoCallBlock(CMAMRTCStateDisconnect);
            }
        } else {
            if (self.voipBlock) {
                self.voipBlock(CMAMRTCStateDisconnect);
            }
        }
    }
}

//拨打成功回调
- (void)agsignal:(AGSignalling *)agSignal callOutSuccess:(nonnull NSDictionary *)result {
    if (_isVideoCall) {
        if (self.videoCallBlock) {
            self.videoCallBlock(CMAMRTCStateVideoCalling);
        }
    } else {
        if (self.voipBlock) {
            self.voipBlock(CMAMRTCStateAudioCalling);
        }
    }
    self.callOutBlock(YES);
}

//挂断回调
- (void)agsignal:(AGSignalling *)agSignal hungupSuccess:(nonnull NSDictionary *)result  {
    if (_isVideoCall) {
        if (self.videoCallBlock && earlyingTime != 30) {
            self.videoCallBlock(CMAMRTCStateDisconnect);
        }
    } else {
        if (self.voipBlock && earlyingTime != 30) {
            self.voipBlock(CMAMRTCStateDisconnect);
        }
    }
    [_agoraKit leaveChannel:nil];
}

//接听成功回调
- (void)agsignal:(AGSignalling *)agSignal answerSuccess:(nullable NSString *)channelName result:(nonnull NSDictionary *)result {
    [self.callingTimer invalidate];
    self.callingTimer = nil;
    //join AgoraKit channel
    [_agoraKit joinChannelByKey:nil channelName:channelName info:nil uid:0 joinSuccess:nil];
    if (_isVideoCall) {
        [self configureIdleTimerActive:NO];
    }
}

//WebSocket 关闭
- (void)agsignal:(AGSignalling *)agSignal connectClose:(NSInteger)code reason:(NSString *)reason {
    self.loginResultBlock(NO, code);
}

//响铃事件
- (void)agsignal:(AGSignalling *)agSignal eventRing:(NSDictionary *)infoDic {
    if (_isVideoCall) {
        if (self.videoCallBlock) {
            self.videoCallBlock(CMAMRTCStateEarly);
        }
    } else {
        if (self.voipBlock) {
            self.voipBlock(CMAMRTCStateEarly);
        }
    }
}

//挂断事件
- (void)agsignal:(AGSignalling *)agSignal eventHangup:(NSDictionary *)infoDic {
    [self.callingTimer invalidate];
    self.isCallingFlag = NO;
    self.callingTimer = nil;
    if (_isVideoCall) {
        if (self.videoCallBlock) {
            self.videoCallBlock(CMAMRTCStateDisconnect);
        }
        [self leaveChannel];
    } else {
        if (self.voipBlock) {
            self.voipBlock(CMAMRTCStateDisconnect);
        }
        [self.agoraKit leaveChannel:nil];
    }
}

//对方拨打事件
- (void)agsignal:(AGSignalling *)agSignal eventCall:(nonnull NSDictionary *)infoDic phoneNumber:(nonnull NSString *)phoneNumber isVideo:(BOOL)isVideo {
    self.isVideoCall = isVideo;
    //发送响铃
    [self.agoraSignal ring];
    if (_isVideoCall) {
        if (self.videoCallBlock) {
            self.videoCallBlock(CMAMRTCStateVideoIncoming);
        }
    } else {
        if (self.voipBlock) {
            self.voipBlock(CMAMRTCStateAudioIncoming);
        }
    }
}

//对方接听回调
- (void)agsignal:(AGSignalling *)agSignal eventAnswer:(NSString *)channelName info:(nonnull NSDictionary *)infoDic {
    [self.callingTimer invalidate];
    self.callingTimer = nil;
    //join Agora channel
    [_agoraKit joinChannelByKey:nil channelName:channelName info:nil uid:0 joinSuccess:nil];
    if (_isVideoCall) {
        [self configureIdleTimerActive:NO];
    }
}

#pragma mark AgoraRtcDelegate
//本地第一帧画面
- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstLocalVideoFrameWithSize:(CGSize)size elapsed:(NSInteger)elapsed {
}

//远程画面
- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstRemoteVideoDecodedOfUid:(NSUInteger)uid size:(CGSize)size elapsed:(NSInteger)elapsed {
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        if (self.videoCallBlock) {
            self.videoCallBlock(CMAMRTCStateNoRemoteConfirm);
        }
    } else {
        if (self.videoCallBlock) {
            switchFlag = NO;
            self.remoteVideoCanvas.view = self.bigPreview;
            self.remoteVideoCanvas.uid = uid;
            [self.agoraKit setupRemoteVideo:self.remoteVideoCanvas];
            
            self.localVideoCanvas.view = self.smallPreview;
            [self.agoraKit setupLocalVideo:self.localVideoCanvas];
            self.videoCallBlock(CMAMRTCStateNormalConfirm);
        }
    }
}

//通话成功 ((%lu)用户成功加入 (%@)频道)
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinChannel:(NSString *)channel withUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    if (!_isVideoCall) {
        if (self.voipBlock) {
            self.voipBlock(CMAMRTCStateNormalConfirm);
        }
    }
}

/**
 *  AgoraRtcQuality
 *
 *  AgoraRtc_Quality_Unknown        未知
 *  AgoraRtc_Quality_Excellent      优质
 *  AgoraRtc_Quality_Good           良好
 *  AgoraRtc_Quality_Poor           一般
 *  AgoraRtc_Quality_Bad            差
 *  AgoraRtc_Quality_VBad           很差
 *  AgoraRtc_Quality_Down           宕机?
 */
- (void)rtcEngine:(AgoraRtcEngineKit *)engine audioQualityOfUid:(NSUInteger)uid quality:(AgoraRtcQuality)quality delay:(NSUInteger)delay lost:(NSUInteger)lost {
//    CMLog(@"当前 (%lu)用户的 通话质量延迟(%lu毫秒) 丢包率(%lu%%)", uid, delay, lost);
}

//连接关闭
- (void)rtcEngineConnectionDidInterrupted:(AgoraRtcEngineKit *)engine {
    if (_isVideoCall) {
        if (self.videoCallBlock) {
            self.videoCallBlock(CMAMRTCStateDisconnect);
        }
    } else {
        if (self.voipBlock) {
            self.voipBlock(CMAMRTCStateDisconnect);
        }
    }
    [self hangupAgoraCallConnect];
    [self.agoraKit leaveChannel:nil];
}

//连接丢失
- (void)rtcEngineConnectionDidLost:(AgoraRtcEngineKit *)engine {
    if (_isVideoCall) {
        if (self.videoCallBlock) {
            self.videoCallBlock(CMAMRTCStateDisconnect);
        }
    } else {
        if (self.voipBlock) {
            self.voipBlock(CMAMRTCStateDisconnect);
        }
    }
    [self hangupAgoraCallConnect];
    [self.agoraKit leaveChannel:nil];
}

//因为未知原因要退出重进(网络或媒体相关错误)
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraRtcErrorCode)errorCode {
}

#pragma mark - 近距离传感器
- (void)changeProximityMonitorEnableState:(BOOL)enable {
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    if ([UIDevice currentDevice].proximityMonitoringEnabled == YES) {
        [[UIDevice currentDevice] setProximityMonitoringEnabled:enable];
    }
}

#pragma mark - 自动锁屏
- (void)configureIdleTimerActive:(BOOL)idleTimerDisabled {
    [UIApplication sharedApplication].idleTimerDisabled = !idleTimerDisabled;
}

#pragma mark 本地画面
- (AgoraRtcVideoCanvas *)localVideoCanvas {
    if (!_localVideoCanvas) {
        _localVideoCanvas = [[AgoraRtcVideoCanvas alloc] init];
        _localVideoCanvas.uid = 0;
        _localVideoCanvas.renderMode = AgoraRtc_Render_Hidden;
    }
    return _localVideoCanvas;
}

#pragma mark 远程画面
- (AgoraRtcVideoCanvas *)remoteVideoCanvas {
    if (!_remoteVideoCanvas) {
        _remoteVideoCanvas = [[AgoraRtcVideoCanvas alloc] init];
        _remoteVideoCanvas.renderMode = AgoraRtc_Render_Hidden;
    }
    return _remoteVideoCanvas;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (!self.isVideoCall) {
        [self changeProximityMonitorEnableState:NO];
    }
    self.remoteVideoCanvas = nil;
    self.localVideoCanvas = nil;
    self.isCallingFlag = nil;
    self.agoraSignal = nil;
    self.agoraKit = nil;
    self.wsUrl = nil;
}
@end

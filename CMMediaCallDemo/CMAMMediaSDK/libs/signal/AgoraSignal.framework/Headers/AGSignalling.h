//
//  AGSignalling.h
//  OpenVoiceCall-OC
//
//  Created by willie zhang on 13/10/2017.
//  Copyright © 2017 CavanSu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger,AGSignalErrorCode) {
    AGSignalErrorCode_AUTH_REQUIRED = -32000,//未登录
    AGSignalErrorCode_AUTH_FAILED = -32001,//鉴权失败
    AGSignalErrorCode_SESSION_ERROR = -32002,//SessionId 不匹配
    AGSignalErrorCode_INVALID = -32600,//信令错误
    AGSignalErrorCode_DTMF_FAILED = -99994, //发送DTMF失败
    AGSignalErrorCode_HUNGUP_FAILED = -99995, //挂断失败
    AGSignalErrorCode_RING_FAILED = -99996, //响铃失败
    AGSignalErrorCode_ANSWER_FAILED = -99997, //应答失败
    AGSignalErrorCode_CALLOUT_FAILED = -99998,//拨打失败
    AGSignalErrorCode_Other = -99999 // 其他错误 预留
};

typedef NS_ENUM(NSInteger,AGSignalNetState) {
    AGSignalNetStateUnknow = 0, //webSocket 未知
    AGSignalNetStateConnect, //webSocket连接成功
    AGSignalNetStateLost, //webSocket丢失
};

typedef NS_ENUM(NSInteger,AGSignalState) {
    AGSignalStateNormal = 0,//空闲状态
    AGSignalStateCallOuting,//呼出中
    AGSignalStateCallIning,//呼入中
    AGSignalStateInCall,//通话中
    AGSignalStateHangUping//挂断中
};


@class AGSignalling;

@protocol AGSignallingDelegate <NSObject>

@optional

#pragma mark webSocket
/**
 WebSocket 连接成功回调

 @param agSignal agSignal
 */
- (void)agsignalConnectSuccess:(AGSignalling *)agSignal;
/**
 WebSocket连接失败回调

 @param agSignal agSignal
 @param error 失败信息
 */
- (void)agsignal:(AGSignalling *)agSignal connectError:(NSError *)error;
/**
 WebSocket连接关闭回调

 @param agSignal agSignal
 @param code 状态码
 @param reason 原因
 */
- (void)agsignal:(AGSignalling *)agSignal connectClose:(NSInteger)code reason:(NSString *)reason;

#pragma mark signal
/**
 用户鉴权成功回调
 
 @param agSignal agSignal
 @param result 成功信息
 */
- (void)agsignal:(AGSignalling *)agSignal loginSuccess:(NSDictionary *)result;

/**
 用户订阅成功回调

 @param agSignal agSignal
 @param result 成功信息
 */
- (void)agsignal:(AGSignalling *)agSignal subscribeSuccess:(NSDictionary *)result;

/**
 拨打成功回调
 
 @param agSignal agSignal
 @param result 成功信息
 */
- (void)agsignal:(AGSignalling *)agSignal callOutSuccess:(NSDictionary *)result;

/**
 挂断成功回调
 
 @param agSignal agSignal
 @param result 成功信息
 */
- (void)agsignal:(AGSignalling *)agSignal hungupSuccess:(NSDictionary *)result;

/**
 发送DTMF成功回调
 
 @param agSignal agSignal
 @param result 成功信息
 */
- (void)agsignal:(AGSignalling *)agSignal dtmfSuccess:(NSDictionary *)result;

/**
 接听成功回调
 
 @param agSignal agSignal
 @param channelName 房间名
 @param result 成功信息
 */
- (void)agsignal:(AGSignalling *)agSignal answerSuccess:(nullable NSString *)channelName result:(NSDictionary *)result;

/**
 取消订阅成功回调
 
 @param agSignal agSignal
 @param result 成功信息
 */
- (void)agsignal:(AGSignalling *)agSignal unsubscribeDidSuccess:(NSDictionary *)result;

/**
 信令处理错误回调

 @param agSignal agSignal
 @param error 错误信息
 */
- (void)agsignal:(AGSignalling *)agSignal signalErrorCode:(AGSignalErrorCode)errorCode responseError:(NSDictionary *)error;


#pragma mark -event

/**
 收到响铃事件

 @param agSignal agSignal
 @param infoDic 事件信息
 */
- (void)agsignal:(AGSignalling *)agSignal eventRing:(NSDictionary *)infoDic;

/**
 对方挂断事件

 @param agSignal agSignal
 @param infoDic 事件信息
 */
- (void)agsignal:(AGSignalling *)agSignal eventHangup:(NSDictionary *)infoDic;

/**
 对方接听事件

 @param agSignal agSignal
 @param channelName 房间channel
 @param infoDic 事件信息
 */
- (void)agsignal:(AGSignalling *)agSignal eventAnswer:(NSString *)channelName info:(NSDictionary *)infoDic;

/**
 对方拨打事件

 @param agSignal agSignal
 @param infoDic 事件信息
 @param phoneNumber 呼入电话号码
 @param isVideo 是否是视频
 */
- (void)agsignal:(AGSignalling *)agSignal eventCall:(NSDictionary *)infoDic  phoneNumber:(NSString*)phoneNumber isVideo:(BOOL) isVideo;

/**
 对方DTMF事件

 @param agSignal agSignal
 @param number dtmf
 @param infoDic 事件信息
 */
- (void)agsignal:(AGSignalling *)agSignal eventDtmf:(NSString *)number infoDic:(NSDictionary *)infoDic;

@end



@interface AGSignalling : NSObject

@property (nonatomic, weak) id <AGSignallingDelegate> delegate;
//Agora APPID  不能为空
@property (nonatomic, copy) NSString *appID;
//webSocket连接状态
@property (nonatomic, assign, readonly) AGSignalNetState netState;
//状态
@property (nonatomic, assign, readonly) AGSignalState callState;

/**
 创建单例
 @return 实例对象
 */
+ (instancetype)sharedSignallingController;

/**
 连接到WebSocket
 @param url ws URL
 */
- (void)connectToServerWithUrl:(NSString *)url;
/**
 用户认证

 @param userName 用户名
 @param password 密码
 @param companyID companyID
 */
- (void)authUserWithName:(NSString *)userName password:(NSString *)password companyID:(NSString *)companyID;

/**
 拨打
 @param destNumber 对方用户名
 @param video 是否是视频
 @param repairOrderNumber 工单号 可不传
 */
- (void)callOut:(NSString *)destNumber video:(BOOL)video repairOrderNumber:(NSString *)repairOrderNumber;

/**
 挂断
 */
- (void)hungup;
/**
 发送DTMF
 
 @param number DTMF
 */
- (void)dtmf:(NSString *)number;

/**
 接听
 */
- (void)answer;

/**
 客户端响铃
 */
- (void)ring;

/**
 取消ws连接
 */
- (void)cancelConnectToSignalServer;


/**
 销毁信令
 */
- (void)destory;



/**
 获取当前版本

 @return 版本号
 */
+ (NSString *)getversion;


@end

NS_ASSUME_NONNULL_END


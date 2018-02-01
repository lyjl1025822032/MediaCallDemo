//
//  ViewController.m
//  CMMediaCallDemo
//
//  Created by yao on 2018/1/31.
//  Copyright © 2018年 王智垚. All rights reserved.
//

#import "ViewController.h"
#import "CMAMNetworkManager.h"
#import "CMAMUserInfo.h"
#import "CMAllMediaRTCChatManager.h"
#import "CMAllMediaVoipView.h"
#import "CMAllMediaVideoCallView.h"

@interface ViewController () <CMAllMediaVideoCallViewDelegate>
@property (nonatomic, strong) NSString *wsUrlString;
@property (nonatomic, strong) CMAMUserInfo *userInfo;
@property (nonatomic, strong) CMAllMediaVideoCallView *videoCallView;
@property (strong, nonatomic) IBOutlet UIButton *voipBtn;
@property (strong, nonatomic) IBOutlet UIButton *videoCallBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //视频通话
    self.videoCallView = [[CMAllMediaVideoCallView alloc] initWithFrame:CGRectMake(0, 0, kCMScreenWidth, kCMScreenHeight)];
    _videoCallView.delegate = self;
    
    NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    __weak typeof(self) weakSelf = self;
    NSDictionary *pDic = @{@"companyId":@"cmostest",@"deviceNo":idfv};
    //1.租户数据请求
    [CMAMNetworkManager postWithUrlString:@"http://120.194.44.248:31010/navigation/companyInfo" parameters:pDic success:^(NSDictionary *bean, NSHTTPURLResponse *httpResponse) {
        [weakSelf requestUserInfoWithProvisionUrl:bean[@"provisionUrl"]];
    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
        NSLog(@"error = %@", error);
    }];
}

//2.用户数据请求
- (void)requestUserInfoWithProvisionUrl:(NSString *)provisionUrl {
    __weak typeof(self) weakSelf = self;
    NSDictionary *pDic = @{@"appKey":@"0#0",@"provCode":@"371",@"companyId":@"cmostest",@"userName":@"djkalsd"};
    [CMAMNetworkManager postWithUrlString:provisionUrl parameters:pDic success:^(NSDictionary *bean, NSHTTPURLResponse *httpResponse) {
        weakSelf.userInfo.agentNo = bean[@"agentNo"];
        weakSelf.userInfo.agentPassword = bean[@"agentPassword"];
        weakSelf.userInfo.enablevideo = bean[@"enableVideo"];
        weakSelf.userInfo.sipport = bean[@"sipPort"];
        weakSelf.userInfo.sipurl = bean[@"sipUrl"];
        weakSelf.userInfo.voipCallNo = [bean[@"voipCallNo"] componentsSeparatedByString:@","].firstObject;;
        weakSelf.userInfo.videoCallNo = [bean[@"voipCallNo"] componentsSeparatedByString:@","].lastObject;
        
        [weakSelf loginSipConfig];
    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
        NSLog(@"error = %@", error);
    }];
}

//登录音视频服务
- (void)loginSipConfig {
    [[CMAllMediaRTCChatManager sharedInstance] connectWebSocketServerWithWebSocketDomain:self.userInfo.sipurl AndDomainPort:self.userInfo.sipport AndUsername:self.userInfo.agentNo password:self.userInfo.agentPassword companyID:@"cmostest" completion:^(BOOL result, NSInteger errorCode) {
        self.voipBtn.hidden = !result;
        self.videoCallBtn.hidden = !result;
    }];
}

//拨打音频
- (IBAction)handleVoipButton:(UIButton *)sender {
    CMAllMediaVoipView *voipView = [[CMAllMediaVoipView alloc] initWithFrame:CGRectMake(0, 0, kCMScreenWidth, kCMScreenHeight)];
    voipView.wsLoseBlock = ^{
        NSLog(@"未连接到语音服务");
    };
    voipView.enlargeBlock = ^{
        [self.view endEditing:YES];
    };
    voipView.agoraVoipBlock = ^(CMAMRTCState state, NSString *timeStr) {
        switch (state) {
            case CMAMRTCStateDisconnect:
            {
                NSLog(@"%@", timeStr.length?[NSString stringWithFormat:@"%@ 已结束通话", timeStr]:[NSString stringWithFormat:@"已取消通话"]);
            }
                break;
            case CMAMRTCStateNoResponse:
            {
                //发送消息
                NSLog(@"对方无应答，请重新拨打");
            }
            default:
                break;
        }
    };
    
    [voipView callVoipPhoneWithWithNumber:self.userInfo.voipCallNo];
}

//拨打视频
- (IBAction)handleVideoCallButton:(UIButton *)sender {
    [self.videoCallView callVideoPhoneWithNumber:self.userInfo.videoCallNo];
}

#pragma mark 视频通话Delegate
- (void)webSocketLosingConnect {
    NSLog(@"未连接到视频服务");
}

- (void)videoCallFinishWithTimeLength:(NSString *)timeLength andState:(CMAMRTCState)state {
    switch (state) {
        case CMAMRTCStateDisconnect:
        {
            NSLog(@"%@", timeLength.length?[NSString stringWithFormat:@"%@ 已结束视频通话", timeLength]:[NSString stringWithFormat:@"已取消视频通话"]);
        }
            break;
        case CMAMRTCStateNoResponse:
        {
            NSLog(@"当前客服忙，请稍后再发起请求");
        }
        default:
            break;
    }
}

- (void)handleEnlarge {
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CMAMUserInfo *)userInfo {
    if (!_userInfo) {
        _userInfo = [[CMAMUserInfo alloc] init];
    }
    return _userInfo;
}

@end

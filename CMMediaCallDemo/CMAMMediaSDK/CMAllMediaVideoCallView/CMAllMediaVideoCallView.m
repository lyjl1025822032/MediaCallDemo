//
//  CMAllMediaVideoCallView.m
//  CmosAllMedia
//
//  Created by yao on 2017/12/26.
//  Copyright © 2017年 liangscofield. All rights reserved.
//

#import "CMAllMediaVideoCallView.h"
#import "CMAllMediaVerticalButton.h"

//三个按钮间隔
#define btnMargin ((kCMScreenWidth - 72*kCMScaleWidth*3) / 4)
//两个按钮间隔
#define btnTwoMargin ((kCMScreenWidth - 72*kCMScaleWidth*2) / 3)
//中间三个按钮Y
#define btnY kCMScreenHeight - 222 * kCMScaleHeight
//悬浮球宽度的一半
#define kBallW (34*kCMScaleWidth)
//小屏宽度的一半
#define kSmallViewW (55*kCMScaleWidth)
//小屏高度的一半
#define kSmallViewH (75*kCMScaleHeight)

//悬浮球距离边缘的距离
static CGFloat edgeDistance = 8;
//悬浮球宽高
static CGFloat smallBallWH = 68;
//缩小时接通界面宽
static CGFloat smallWidth = 110;
//缩小时接通界面高
static CGFloat smallHeight = 150;
//挂断按钮Y(距底部)
static CGFloat hangupY = 176;
//底部三个按钮宽
static CGFloat buttonWidth = 72;
//底部三个按钮高
static CGFloat buttonHeight = 95;

//左上角缩放x
static CGFloat shrinkX = 22;
//左上角缩放Y
static CGFloat shrinkY = 32;
//左上角缩放按钮宽
static CGFloat shrinkWidth = 30;
//左上角缩放按钮高
static CGFloat shrinkHeight = 24;

@interface CMAllMediaVideoCallView ()<UIGestureRecognizerDelegate> {
    //等待接通
    NSTimer *waitTimer;
    //记录通信时间
    NSTimer *contenctTimer;
    //通讯时长
    NSInteger contenctT;
    //记录当前小屏
    BOOL isLocalSmall;
    //记录放大前Rect
    CGRect smallRect;
    //是否缩小
    BOOL isSmall;
    //是否静音
    BOOL isSilence;
    //记录客服工号
    NSString *serverNum;
    //是否用户发起
    BOOL isUserCall;
    //是否正在小屏
    BOOL isPiping;
}
// 触摸位置与悬浮球中心的偏差
@property (nonatomic, assign) CGFloat offSetX;
@property (nonatomic, assign) CGFloat offSetY;
//切换本地和远程视图
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
//悬浮界面放大手势
@property (nonatomic, strong) UITapGestureRecognizer *largerGesture;
//悬浮界面拖拽手势
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
//画中画拖拽手势
@property (nonatomic, strong) UIPanGestureRecognizer *pipPanRecognizer;

@property (nonatomic, strong) CMAllMediaRTCChatManager *manager;
//背景视图
@property (nonatomic, strong) UIImageView *backgroundView;
//全屏画面
@property (nonatomic, strong) UIView *largerPreview;
//小屏画面
@property (nonatomic, strong) UIImageView *shrinkView;

//连接标语/时间
@property (nonatomic, strong) NSString *connectString;
@property (nonatomic, strong) UILabel *connectLabel;

//左上缩小按钮
@property (nonatomic, strong) UIButton *shrinkBtn;
//挂断按钮
@property (nonatomic, strong) CMAllMediaVerticalButton *hangupBtn;
//静音按钮
@property (nonatomic, strong) CMAllMediaVerticalButton *silenceBtn;
//切换摄像头按钮
@property (nonatomic, strong) CMAllMediaVerticalButton *cameraSwitchBtn;
//拒接按钮
@property (nonatomic, strong) CMAllMediaVerticalButton *refuseBtn;
//接通按钮
@property (nonatomic, strong) CMAllMediaVerticalButton *answerBtn;

@end

@implementation CMAllMediaVideoCallView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        __weak typeof(self)weakSelf = self;
        weakSelf.manager = [CMAllMediaRTCChatManager sharedInstance];
        weakSelf.manager.videoCallBlock = ^(CMAMRTCState state) {
            [self handleAgoraStateWithRTCState:state];
        };
    }
    return self;
}

//主动发起视频通话
- (void)callVideoPhoneWithNumber:(NSString *)phoneNumber {
    if ([CMAllMediaRTCChatManager sharedInstance].isVoipNormal && ![CMAllMediaRTCChatManager sharedInstance].isCallingFlag) {
        isSmall = NO;
        isPiping = NO;
        isSilence = NO;
        isUserCall = YES;
        isLocalSmall = NO;
        serverNum = phoneNumber;
        [self.manager callUserWithUserNumber:phoneNumber isVideoCall:YES repairOrderNumber:@"" andSetupLargerPreview:self.largerPreview andShrinkView:self.shrinkView];
        self.refuseBtn.hidden = YES;
        self.answerBtn.hidden = YES;
        self.silenceBtn.hidden = YES;
        self.cameraSwitchBtn.hidden = YES;
        [self showVideoCallView];
    } else if (![CMAllMediaRTCChatManager sharedInstance].isVoipNormal && ![CMAllMediaRTCChatManager sharedInstance].isCallingFlag) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(webSocketLosingConnect)]) {
            [self.delegate webSocketLosingConnect];
        }
    }
}

//接收到视频来电
- (void)acceptVideoPhoneCall {
    if ([CMAllMediaRTCChatManager sharedInstance].isVoipNormal && ![CMAllMediaRTCChatManager sharedInstance].isCallingFlag) {
        isSmall = NO;
        isPiping = NO;
        isSilence = NO;
        isUserCall = NO;
        isLocalSmall = NO;
        [self configureBtnHiddenCallOrReveive:NO];
        [self showVideoCallView];
        [self.manager receiveAgoraCallIsVideoCall:YES andSetupLargerPreview:self.largerPreview andShrinkView:self.shrinkView];
    } else if (![CMAllMediaRTCChatManager sharedInstance].isVoipNormal && ![CMAllMediaRTCChatManager sharedInstance].isCallingFlag) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(webSocketLosingConnect)]) {
            [self.delegate webSocketLosingConnect];
        }
    }
}

//接受视频来电
- (void)connectVideoPhoneCall {
    __weak typeof(self)weakSelf = self;
    isLocalSmall = NO;
    [weakSelf.manager acceptIncomingAgoraCall];
    [weakSelf configureBtnHiddenCallOrReveive:YES];
}

- (void)configureBtnHiddenCallOrReveive:(BOOL)flag {
    self.refuseBtn.hidden = flag;
    self.answerBtn.hidden = flag;
    self.silenceBtn.hidden = !flag;
    self.hangupBtn.hidden = !flag;
    self.cameraSwitchBtn.hidden = !flag;
}

//展示视频界面
- (void)showVideoCallView {
    contenctT = 0;
    
    [self addSubview:self.backgroundView];
    [self addGestureRecognizer:self.panRecognizer];
    
    [self.backgroundView addSubview:self.largerPreview];
    [self.backgroundView addGestureRecognizer:self.largerGesture];
    
    [self.backgroundView addSubview:self.shrinkBtn];
    [self.backgroundView addSubview:self.refuseBtn];
    [self.backgroundView addSubview:self.answerBtn];
    [self.backgroundView addSubview:self.silenceBtn];
    [self.backgroundView addSubview:self.hangupBtn];
    [self.backgroundView addSubview:self.cameraSwitchBtn];
    [self.backgroundView addSubview:self.connectLabel];
    
    [self.backgroundView addSubview:self.shrinkView];
    
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [UIView animateWithDuration:0.5 animations:^{
        _backgroundView.frame = CGRectMake(0, 0, kCMScreenWidth, kCMScreenHeight);
    }];
}

#pragma mark 根据Agora状态的处理
- (void)handleAgoraStateWithRTCState:(NSInteger)voipState {
    switch (voipState) {
        case CMAMRTCStateVideoCalling:
            //邀请人工客服
            [self updateStateLabelWithStr:[NSString stringWithFormat:@"正在连接%@工号为您服务...", serverNum]];
            waitTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(waitTimerState) userInfo:nil repeats:YES];
            break;
        case CMAMRTCStateVideoIncoming:
            [self acceptVideoPhoneCall];
            //人工客服邀请
            [self updateStateLabelWithStr:@"人工客服邀请视频通话..."];
            waitTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(waitTimerState) userInfo:nil repeats:YES];
            break;
        case CMAMRTCStateEarly:
            if (!self.backgroundView) {
                [self showVideoCallView];
            }
            break;
        case CMAMRTCStateConnecting:
            self.connectLabel.text = @"接通中...";
            break;
        case CMAMRTCStateNormalConfirm://接通
        {
            [self destoryWaitTimer];
            self.largerGesture.enabled = NO;
            self.shrinkView.hidden = NO;
            [self updateStateLabelWithStr:@"00:00"];
            self.shrinkView.frame = CGRectMake(kCMScreenWidth-120*kCMScaleWidth, shrinkY*kCMScaleHeight, smallWidth*kCMScaleWidth, smallHeight*kCMScaleHeight);
            contenctTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(contenctTimeLength) userInfo:nil repeats:YES];
            [self changeButtonHiddenWithFullOrHalfState:NO];
        }
            break;
        case CMAMRTCStateNoRemoteConfirm://接通无远程
        {
            self.largerGesture.enabled = NO;
            [self destoryWaitTimer];
            [self.shrinkView setImage:kCM_loadBundleImage(@"normalhead")];
            [self.shrinkView removeGestureRecognizer:self.tapGesture];
            self.shrinkView.layer.borderWidth = 0;
            self.shrinkView.hidden = NO;
            [self updateStateLabelWithStr:@"00:00"];
            contenctTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(contenctTimeLength) userInfo:nil repeats:YES];
            [self changeButtonHiddenWithFullOrHalfState:NO];
        }
            break;
        case CMAMRTCStateDisconnect:
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoCallFinishWithTimeLength:andState:)]) {
                [self.delegate videoCallFinishWithTimeLength:contenctT?_connectLabel.text:nil andState:CMAMRTCStateDisconnect];
            }
            [self updateStateLabelWithStr:@"已挂断"];
            [self destoryWaitTimer];
            [self destoryContentTimer];
            [self dismissVideoCallView];
        }
            break;
        case CMAMRTCStateNoResponse:
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoCallFinishWithTimeLength:andState:)]) {
                [self.delegate videoCallFinishWithTimeLength:nil andState:CMAMRTCStateNoResponse];
            }
            [self updateStateLabelWithStr:@"对方忙"];
            [self destoryWaitTimer];
            [self destoryContentTimer];
            [self dismissVideoCallView];
        }
            break;
        default:
            break;
    }
}

#pragma mark Gesture Action
//大小屏切换
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (!contenctT) {
        return;
    }
    [self exchangeView];
}

//大小屏切换
- (void)exchangeView {
    if (isPiping || self.layer.cornerRadius == kBallW) {
        return;
    }
    [self.manager switchVideoShrinkAndLargerView];
}

//放大界面
- (void)handleLargerTapGesture:(UITapGestureRecognizer *)sender {
    if(!isSmall || isPiping)return;
    if (self.delegate && [self.delegate respondsToSelector:@selector(handleEnlarge)]) {
        [self.delegate handleEnlarge];
    }
    isSmall = NO;
    self.largerPreview.hidden = NO;
    self.connectLabel.font = [UIFont systemFontOfSize:17];
    [UIView animateWithDuration:0.5 animations:^{
        self.frame = CGRectMake(0, 0, kCMScreenWidth, kCMScreenHeight);
        self.layer.cornerRadius = 0;
        
        _backgroundView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        [_backgroundView setImage:[UIImage new]];
        
        self.largerPreview.frame = self.frame;
        
        self.shrinkBtn.frame = CGRectMake(shrinkX*kCMScaleWidth, shrinkY*kCMScaleHeight, shrinkWidth*kCMScaleWidth, shrinkHeight*kCMScaleHeight);
        [self updateStateLabelWithStr:self.connectString];
    } completion:^(BOOL finished) {
        _connectLabel.hidden = NO;
        _panRecognizer.enabled = NO;
        self.layer.masksToBounds = NO;
        
        self.shrinkBtn.hidden = NO;
        self.silenceBtn.hidden = contenctT?NO:YES;
        self.shrinkView.hidden = contenctT?NO:YES;
        self.cameraSwitchBtn.hidden = contenctT?NO:YES;
        self.hangupBtn.hidden = isUserCall?NO:(contenctT?NO:YES);
        self.refuseBtn.hidden = isUserCall?YES:(contenctT?YES:NO);
        self.answerBtn.hidden = isUserCall?YES:(contenctT?YES:NO);
    }];
}

//缩小界面
- (void)handleShrinkButton:(UIButton *)sender {
    if(isSmall)return;
    isSmall = YES;
    isPiping = YES;
    [self changeButtonHiddenWithFullOrHalfState:YES];
    if (contenctT) {
        self.connectLabel.hidden = YES;
    } else {
        self.connectString = self.connectLabel.text;
        self.connectLabel.font = [UIFont systemFontOfSize:12];
    }
    smallRect = CGRectMake(smallRect.size.width?smallRect.origin.x:kCMScreenWidth-120*kCMScaleWidth, smallRect.size.width?smallRect.origin.y:84, (contenctT?smallWidth:smallBallWH)*kCMScaleWidth, (contenctT?smallHeight:smallBallWH)*kCMScaleWidth);
    [UIView animateWithDuration:0.5 animations:^{
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = (contenctT?5:34)*kCMScaleWidth;
        self.frame = smallRect;
        
        _backgroundView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        self.shrinkView.hidden = YES;
        self.largerPreview.frame = CGRectMake(0, 0, smallRect.size.width, smallRect.size.height);
        _connectLabel.text = contenctT?_connectLabel.text:@"等待中";
    } completion:^(BOOL finished) {
        if (!contenctT) {
            self.shrinkView.hidden = YES;
            self.largerPreview.hidden = YES;
            [_backgroundView setImage:kCM_loadBundleImage(@"videobacksmall")];
        }
        [self updateStateLabelWithStr:_connectLabel.text];
        _panRecognizer.enabled = YES;
        isPiping = NO;
    }];
}

//拖拽界面
- (void)handlePanVideoView:(UIPanGestureRecognizer *)sender {
    CGPoint location = [sender locationInView:sender.view];
    CGPoint panPoint = [sender locationInView:sender.view.superview];
    BOOL flag = (self.layer.cornerRadius == kBallW)?YES:NO;
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.offSetX = flag?kBallW/2:kSmallViewW - location.x;
        self.offSetY = flag?kBallW/2:kSmallViewH - location.y;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        sender.view.center = CGPointMake(panPoint.x + _offSetX, panPoint.y + _offSetY);
    } else if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        CGFloat superWidth = sender.view.superview.bounds.size.width;
        CGFloat superHeight = sender.view.superview.bounds.size.height;
        
        CGFloat endX = sender.view.center.x;
        CGFloat endY = sender.view.center.y - 2;//矫正Y减2 成为视觉中心, center 需要相应加2以作矫正
        
        CGFloat top = fabs(endY);//上距离
        CGFloat bottom = fabs(superHeight - endY);//下距离
        CGFloat left = fabs(endX);//左距离
        CGFloat right = fabs(superWidth - endX);//右距离
        
        CGFloat minSpace = MIN(MIN(MIN(top, left), bottom), right);
        
        //判断最小距离属于上下左右哪个方向 并设置该方向边缘的point属性
        CGPoint newCenter;
        
        if (minSpace == top) {//上
            endX = endX - (flag?kBallW:kSmallViewW) < edgeDistance * 2 ? (flag?kBallW:kSmallViewW) + edgeDistance : endX;
            endX = endX + (flag?kBallW:kSmallViewW) > superWidth - edgeDistance * 2 ? superWidth - (flag?kBallW:kSmallViewW) - edgeDistance : endX;
            newCenter = CGPointMake(endX , edgeDistance*(kCMISiPhoneX?4:2) + (flag?kBallW:kSmallViewH) + 2);
        } else if(minSpace == bottom) {//下
            endX = endX - (flag?kBallW:kSmallViewW) < edgeDistance * 2 ? (flag?kBallW:kSmallViewW) + edgeDistance : endX;
            endX = endX + (flag?kBallW:kSmallViewW) > superWidth - edgeDistance * 2 ? superWidth - (flag?kBallW:kSmallViewW) - edgeDistance : endX;
            newCenter = CGPointMake(endX , superHeight - (flag?kBallW:kSmallViewH) - edgeDistance*(kCMISiPhoneX?3:1) + 2);
        } else if(minSpace == left) {//左
            endY = endY - (flag?kBallW:kSmallViewH) < edgeDistance * 2 ? (flag?kBallW:kSmallViewH) + edgeDistance : endY;
            endY = endY + (flag?kBallW:kSmallViewH) > superHeight - edgeDistance * 2 ? superHeight - (flag?kBallW:kSmallViewH) - edgeDistance : endY;
            newCenter = CGPointMake(edgeDistance + (flag?kBallW:kSmallViewW) , endY + 2);
        } else {//右
            endY = endY - (flag?kBallW:kSmallViewH) < edgeDistance * 2 ? (flag?kBallW:kSmallViewH) + edgeDistance : endY;
            endY = endY + (flag?kBallW:kSmallViewH) > superHeight - edgeDistance * 2 ? superHeight - (flag?kBallW:kSmallViewH) - edgeDistance : endY;
            newCenter = CGPointMake(superWidth - (flag?kBallW:kSmallViewW) - edgeDistance , endY + 2);
        }
        
        [UIView animateWithDuration:0.3 animations:^{
            sender.view.center = newCenter;
            smallRect = sender.view.frame;
        }];
    }
}

//拖拽画中画手势
- (void)handlePanPIPView:(UIPanGestureRecognizer *)sender {
    CGPoint location = [sender locationInView:sender.view];
    CGPoint panPoint = [sender locationInView:sender.view.superview];
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.offSetX = kSmallViewW - location.x;
        self.offSetY = kSmallViewH - location.y;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        sender.view.center = CGPointMake(panPoint.x + _offSetX, panPoint.y + _offSetY);
    } else if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        CGFloat superWidth = sender.view.superview.bounds.size.width;
        CGFloat superHeight = sender.view.superview.bounds.size.height;
        
        CGFloat endX = sender.view.center.x;
        CGFloat endY = sender.view.center.y - 2;//矫正Y减2 成为视觉中心, center 需要相应加2以作矫正
        
        CGFloat top = fabs(endY);//上距离
        CGFloat bottom = fabs(superHeight - endY);//下距离
        CGFloat left = fabs(endX);//左距离
        CGFloat right = fabs(superWidth - endX);//右距离
        
        CGFloat minSpace = MIN(MIN(MIN(top, left), bottom), right);
        
        //判断最小距离属于上下左右哪个方向 并设置该方向边缘的point属性
        CGPoint newCenter;
        
        if (minSpace == top) {//上
            endX = endX - kSmallViewW < edgeDistance * 2 ? kSmallViewW + edgeDistance : endX;
            endX = endX + kSmallViewW > superWidth - edgeDistance * 2 ? superWidth - kSmallViewW - edgeDistance : endX;
            newCenter = CGPointMake(endX , edgeDistance*(kCMISiPhoneX?4:2) + kSmallViewH + 2);
        } else if(minSpace == bottom) {//下
            endX = endX - kSmallViewW < edgeDistance * 2 ? kSmallViewW + edgeDistance : endX;
            endX = endX + kSmallViewW > superWidth - edgeDistance * 2 ? superWidth - kSmallViewW - edgeDistance : endX;
            newCenter = CGPointMake(endX , superHeight - kSmallViewH - edgeDistance*(kCMISiPhoneX?3:1) + 2);
        } else if(minSpace == left) {//左
            endY = endY - kSmallViewH < edgeDistance * 2 ? kSmallViewH + edgeDistance : endY;
            endY = endY + kSmallViewH > superHeight - edgeDistance * 2 ? superHeight - kSmallViewH - edgeDistance : endY;
            newCenter = CGPointMake(edgeDistance + kSmallViewW , endY + 2);
        } else {//右
            endY = endY - kSmallViewH < edgeDistance * 2 ? kSmallViewH + edgeDistance : endY;
            endY = endY + kSmallViewH > superHeight - edgeDistance * 2 ? superHeight - kSmallViewH - edgeDistance : endY;
            newCenter = CGPointMake(superWidth - kSmallViewW - edgeDistance , endY + 2);
        }
        
        [UIView animateWithDuration:0.3 animations:^{
            sender.view.center = newCenter;
        }];
    }
}

#pragma mark Private Action
//记录通话时间
- (void)contenctTimeLength {
    contenctT++;
    NSString *str = [self convertTime:contenctT];
    self.connectString = str;
    self.connectLabel.text = str;
    self.largerGesture.enabled = YES;
    [self updateStateLabelWithStr:str];
    
    if (self.layer.cornerRadius == kBallW) {
        _panRecognizer.enabled = YES;
        self.connectLabel.hidden = YES;
        [_backgroundView setImage:[UIImage new]];
        [self changeButtonHiddenWithFullOrHalfState:YES];
        smallRect = CGRectMake(kCMScreenWidth-120*kCMScaleWidth, 84, smallWidth*kCMScaleWidth, smallHeight*kCMScaleWidth);
        
        self.frame = smallRect;
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 5*kCMScaleWidth;
        
        _backgroundView.frame = CGRectMake(0, 0, smallRect.size.width, smallRect.size.height);
        
        self.largerPreview.hidden = NO;
        self.largerPreview.layer.borderWidth = 0;
        self.largerPreview.frame = CGRectMake(0, 0, kCMScreenWidth, kCMScreenHeight);
    }
}

//时间换算
- (NSString *)convertTime:(long long)timeSecond {
    NSString *theLastTime = nil;
    if (timeSecond < 60) {
        theLastTime = [NSString stringWithFormat:@"00:%.2lld", timeSecond];
    } else if (timeSecond >= 60 && timeSecond < 3600){
        theLastTime = [NSString stringWithFormat:@"%.2lld:%.2lld", timeSecond/60, timeSecond%60];
    } else if (timeSecond >= 3600){
        theLastTime = [NSString stringWithFormat:@"%.2lld:%.2lld:%.2lld", timeSecond/3600, timeSecond%3600/60, timeSecond%60];
    }
    return theLastTime;
}

//更新状态Label
- (void)updateStateLabelWithStr:(NSString *)str {
    CGSize chatSize;
    _connectLabel.text = str;
    
    if (isSmall) {
        chatSize = [self getWidthWithString:contenctT?_connectLabel.text:@"等待中" height:20*kCMScaleHeight font:12];
        _connectLabel.frame = CGRectMake((smallRect.size.width-chatSize.width)/2, smallRect.size.height-35*kCMScaleHeight, chatSize.width, 20*kCMScaleHeight);
    } else {
        NSString *string = [str containsString:@"服"]?[str stringByAppendingString:@"..."]:str;
        chatSize = [self getWidthWithString:string height:15*kCMScaleHeight font:17];
        _connectLabel.frame = CGRectMake((kCMScreenWidth-chatSize.width)/2, kCMScreenHeight-(hangupY + 32 + 15)*kCMScaleHeight, chatSize.width, 15*kCMScaleHeight);
    }
}

//状态等待文字
- (void)waitTimerState {
    [self stateLabelOccurenceOfString:_connectLabel.text];
}

//状态标语等待文字
- (void)stateLabelOccurenceOfString:(NSString *)string {
    if ([string isEqualToString:@"等待中"])return;
    NSInteger count = 0, length = [string length];
    NSRange range = NSMakeRange(0, length);
    while(range.location != NSNotFound) {
        range = [string rangeOfString:@"." options:0 range:range];
        if(range.location != NSNotFound) {
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            count++;
        }
    }
    NSString *titleStr = [string containsString:@"正在连接"]?[NSString stringWithFormat:@"正在连接%@工号为您服务", serverNum]:@"人工客服邀请视频通话";
    switch (count) {
        case 0:
            _connectLabel.text = [titleStr stringByAppendingString:@"."];
            break;
        case 1:
            _connectLabel.text = [titleStr stringByAppendingString:@".."];
            break;
        case 2:
            _connectLabel.text = [titleStr stringByAppendingString:@"..."];
            break;
        case 3:
            _connectLabel.text = titleStr;
            break;
        default:
            break;
    }
}

//根据文字获取宽度(高度一定)
- (CGSize)getWidthWithString:(NSString *)string height:(CGFloat)height font:(CGFloat)font {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    attrs[NSFontAttributeName] = [UIFont systemFontOfSize:font];
    
    CGSize size =  [string boundingRectWithSize:CGSizeMake(MAXFLOAT,height) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
    return size;
}

//销毁等待时间计时器
- (void)destoryWaitTimer {
    [waitTimer invalidate];
    waitTimer = nil;
}

//销毁通话时间计时器
- (void)destoryContentTimer {
    [contenctTimer invalidate];
    contenctTimer = nil;
}

//拒接
- (void)handleRefuseVideoCall:(UIButton *)sender {
    [self hangupVoipCallPhone];
}

//接通视频
- (void)handleAnswerVideoCall:(UIButton *)sender {
    [self connectVideoPhoneCall];
}

//静音
- (void)handleSilenceVolume:(UIButton *)sender {
    isSilence = isSilence?NO:YES;
    isSilence?[sender setImage:kCM_loadBundleImage(@"silence_pressed") forState:UIControlStateNormal]:[sender setImage:kCM_loadBundleImage(@"silence_mormal") forState:UIControlStateNormal];
    [_manager changeIsSilenceWithFlag:isSilence];
}

//挂断通话
- (void)hangupVoipCallPhone {
    [_manager hangupAgoraCallConnect];
}

//摄像头切换
- (void)switchLocalCamera:(UIButton *)sender {
    [_manager switchLocalCamera];
}

//界面按钮显示状态
- (void)changeButtonHiddenWithFullOrHalfState:(BOOL)flag {
    if (!isUserCall && !contenctT && self.shrinkView.hidden) {
        self.refuseBtn.hidden = flag;
        self.answerBtn.hidden = flag;
        self.shrinkBtn.hidden = flag;
        return;
    }
    self.shrinkBtn.hidden = isSmall?YES:flag;
    self.silenceBtn.hidden = flag;
    self.hangupBtn.hidden = isSmall?flag:NO;
    self.cameraSwitchBtn.hidden = flag;
    self.refuseBtn.hidden = isSmall?YES:!flag;
    self.answerBtn.hidden = isSmall?YES:!flag;
}

//隐藏视图
- (void)dismissVideoCallView {
    [UIView animateWithDuration:0.5 animations:^{
        if (isSmall) {
            self.alpha = 0.f;
            self.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
            [self.backgroundView setImage:[UIImage new]];
        } else {
            self.backgroundView.frame = CGRectMake(0, -kCMScreenHeight, kCMScreenWidth, kCMScreenHeight);
        }
    } completion:^(BOOL finished) {
        self.alpha = 1.f;
        self.layer.cornerRadius = 0;
        self.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
        self.frame = CGRectMake(0, 0, kCMScreenWidth, kCMScreenHeight);
        self.panRecognizer.enabled = NO;
        self.largerPreview = nil;
        self.shrinkView = nil;
        self.backgroundView = nil;
        self.cameraSwitchBtn = nil;
        self.connectString = nil;
        self.connectLabel = nil;
        self.silenceBtn = nil;
        self.shrinkBtn = nil;
        self.hangupBtn = nil;
        self.refuseBtn = nil;
        self.answerBtn = nil;
        [self removeAllSubviewsFromSuperView:self.backgroundView];
        [self removeFromSuperview];
    }];
}

- (void)removeAllSubviewsFromSuperView:(UIView *)superView {
    while (superView.subviews.count) {
        [superView.subviews.lastObject removeFromSuperview];
    }
}

#pragma mark 懒加载
//大小屏切换
- (UITapGestureRecognizer *)tapGesture {
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    }
    return _tapGesture;
}

//悬浮拖拽手势
- (UIPanGestureRecognizer *)panRecognizer {
    if (!_panRecognizer) {
        _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanVideoView:)];
        _panRecognizer.delegate = self;
        _panRecognizer.maximumNumberOfTouches = 1;
        _panRecognizer.minimumNumberOfTouches = 1;
        _panRecognizer.enabled = NO;
    }
    return _panRecognizer;
}

//画中画拖拽手势
- (UIPanGestureRecognizer *)pipPanRecognizer {
    if (!_pipPanRecognizer) {
        _pipPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanPIPView:)];
        _pipPanRecognizer.delegate = self;
        _pipPanRecognizer.maximumNumberOfTouches = 1;
        _pipPanRecognizer.minimumNumberOfTouches = 1;
    }
    return _pipPanRecognizer;
}

//放大界面手势
- (UITapGestureRecognizer *)largerGesture {
    if (!_largerGesture) {
        _largerGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleLargerTapGesture:)];
    }
    return _largerGesture;
}

//背景父视图
- (UIImageView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, -kCMScreenHeight, kCMScreenWidth, kCMScreenHeight)];
        _backgroundView.userInteractionEnabled = YES;
    }
    return _backgroundView;
}

//本地画面
- (UIView *)largerPreview {
    if (!_largerPreview) {
        _largerPreview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kCMScreenWidth, kCMScreenHeight)];
        _largerPreview.backgroundColor = [UIColor whiteColor];
    }
    return _largerPreview;
}

//远程画面
- (UIImageView *)shrinkView {
    if (!_shrinkView) {
        _shrinkView = [[UIImageView alloc] initWithFrame:CGRectMake(kCMScreenWidth-100, shrinkY, 70, 70)];
        _shrinkView.hidden = YES;
        _shrinkView.userInteractionEnabled = YES;
        _shrinkView.layer.borderWidth = 0.5;
        _shrinkView.layer.borderColor = [UIColor whiteColor].CGColor;
        [_shrinkView setImage:kCM_loadBundleImage(@"normalhead")];
        [_shrinkView addGestureRecognizer:self.tapGesture];
        [_shrinkView addGestureRecognizer:self.pipPanRecognizer];
    }
    return _shrinkView;
}

//连接状态标语
- (UILabel *)connectLabel {
    if (!_connectLabel) {
        _connectLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _connectLabel.textColor = [UIColor whiteColor];
    }
    return _connectLabel;
}

//左上缩小按钮
- (UIButton *)shrinkBtn {
    if (!_shrinkBtn) {
        _shrinkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _shrinkBtn.frame = CGRectMake(shrinkX*kCMScaleWidth, shrinkY*kCMScaleHeight, shrinkWidth*kCMScaleWidth, shrinkHeight*kCMScaleHeight);
        [_shrinkBtn setImage:kCM_loadBundleImage(@"shrink_normal") forState:UIControlStateNormal];
        [_shrinkBtn setImage:kCM_loadBundleImage(@"shrink_pressed") forState:UIControlStateHighlighted];
        [_shrinkBtn addTarget:self action:@selector(handleShrinkButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _shrinkBtn;
}

//静音按钮
- (CMAllMediaVerticalButton *)silenceBtn {
    if (!_silenceBtn) {
        _silenceBtn = [CMAllMediaVerticalButton buttonWithType:UIButtonTypeCustom];
        _silenceBtn.frame = CGRectMake(btnMargin, kCMScreenHeight-hangupY*kCMScaleWidth, buttonWidth*kCMScaleWidth, buttonHeight*kCMScaleWidth);
        [_silenceBtn.titleLabel setFont:[UIFont systemFontOfSize:12]];
        [_silenceBtn setTitle:@"静音" forState:UIControlStateNormal];
        [_silenceBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        [_silenceBtn setImage:kCM_loadBundleImage(@"silence_mormal") forState:UIControlStateNormal];
        [_silenceBtn addTarget:self action:@selector(handleSilenceVolume:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _silenceBtn;
}

//挂断按钮
- (CMAllMediaVerticalButton *)hangupBtn {
    if (!_hangupBtn) {
        _hangupBtn = [CMAllMediaVerticalButton buttonWithType:UIButtonTypeCustom];
        _hangupBtn.frame = CGRectMake((kCMScreenWidth-buttonWidth*kCMScaleWidth)/2, kCMScreenHeight-hangupY*kCMScaleWidth, buttonWidth*kCMScaleWidth, buttonHeight*kCMScaleWidth);
        [_hangupBtn.titleLabel setFont:[UIFont systemFontOfSize:12]];
        [_hangupBtn setTitle:@"取消" forState:UIControlStateNormal];
        [_hangupBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        [_hangupBtn setImage:kCM_loadBundleImage(@"voiphangup_normal") forState:UIControlStateNormal];
        [_hangupBtn addTarget:self action:@selector(hangupVoipCallPhone) forControlEvents:UIControlEventTouchUpInside];
    }
    return _hangupBtn;
}

//切换摄像头按钮
- (CMAllMediaVerticalButton *)cameraSwitchBtn {
    if (!_cameraSwitchBtn) {
        _cameraSwitchBtn = [CMAllMediaVerticalButton buttonWithType:UIButtonTypeCustom];
        _cameraSwitchBtn.frame = CGRectMake(kCMScreenWidth-btnMargin-buttonWidth*kCMScaleWidth, kCMScreenHeight-hangupY*kCMScaleWidth, buttonWidth*kCMScaleWidth, buttonHeight*kCMScaleHeight);
        [_cameraSwitchBtn.titleLabel setFont:[UIFont systemFontOfSize:12]];
        [_cameraSwitchBtn setTitle:@"转换摄像头" forState:UIControlStateNormal];
        [_cameraSwitchBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        [_cameraSwitchBtn setImage:kCM_loadBundleImage(@"switchcamera") forState:UIControlStateNormal];
        [_cameraSwitchBtn addTarget:self action:@selector(switchLocalCamera:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraSwitchBtn;
}

//拒接按钮
- (CMAllMediaVerticalButton *)refuseBtn {
    if (!_refuseBtn) {
        _refuseBtn = [CMAllMediaVerticalButton buttonWithType:UIButtonTypeCustom];
        _refuseBtn.frame = CGRectMake(btnTwoMargin, kCMScreenHeight-hangupY*kCMScaleWidth, buttonWidth*kCMScaleWidth, buttonHeight*kCMScaleHeight);
        [_refuseBtn.titleLabel setFont:[UIFont systemFontOfSize:12]];
        [_refuseBtn setTitle:@"拒绝" forState:UIControlStateNormal];
        [_refuseBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        [_refuseBtn setImage:kCM_loadBundleImage(@"voiphangup_normal") forState:UIControlStateNormal];
        [_refuseBtn addTarget:self action:@selector(handleRefuseVideoCall:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _refuseBtn;
}

//接通按钮
- (CMAllMediaVerticalButton *)answerBtn {
    if (!_answerBtn) {
        _answerBtn = [CMAllMediaVerticalButton buttonWithType:UIButtonTypeCustom];
        _answerBtn.frame = CGRectMake(kCMScreenWidth-btnTwoMargin-buttonWidth*kCMScaleWidth, kCMScreenHeight-hangupY*kCMScaleWidth, buttonWidth*kCMScaleWidth, buttonHeight*kCMScaleHeight);
        [_answerBtn.titleLabel setFont:[UIFont systemFontOfSize:12]];
        [_answerBtn setTitle:@"接受" forState:UIControlStateNormal];
        [_answerBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        [_answerBtn setImage:kCM_loadBundleImage(@"voipreceive_normal") forState:UIControlStateNormal];
        [_answerBtn addTarget:self action:@selector(handleAnswerVideoCall:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _answerBtn;
}

- (void)dealloc
{
    self.delegate = nil;
}
@end

//
//  Header.h
//  CMMediaCallDemo
//
//  Created by yao on 2018/1/31.
//  Copyright © 2018年 王智垚. All rights reserved.
//

#ifndef Header_h
#define Header_h

#define kCMScreenWidth [UIScreen mainScreen].bounds.size.width
#define kCMScreenHeight [UIScreen mainScreen].bounds.size.height
#define kCMScaleWidth (kCMScreenWidth > 320 ? 1.0 : (kCMScreenWidth / 360.0))
#define kCMScaleHeight (kCMScreenHeight > 568.0 ? 1.0 : (kCMScreenHeight / 640.0))
#define kCMISiPhoneX ((kCMScreenWidth < kCMScreenHeight ? kCMScreenHeight : kCMScreenWidth) == 812 ? YES : NO)
#define kCM_loadBundleImage(imageName) [UIImage imageNamed:imageName]

//中间三个按钮Y
#define btnY kCMScreenHeight - 222 * kCMScaleHeight
//三个按钮间隔
#define btnMargin ((kCMScreenWidth - 72*kCMScaleWidth*3) / 4)
//两个按钮间隔
#define btnTwoMargin ((kCMScreenWidth - 72*kCMScaleWidth*2) / 3)
//小屏宽度的一半
#define kSmallViewW (55*kCMScaleWidth)
//小屏高度的一半
#define kSmallViewH (75*kCMScaleHeight)

//悬浮球宽度的一半
#define kBallW (34*kCMScaleWidth)
//悬浮屏宽度的一半
#define kSmallW (35*kCMScaleWidth)
//悬浮屏高度的一半
#define kSmallH (40*kCMScaleHeight)

#endif /* Header_h */

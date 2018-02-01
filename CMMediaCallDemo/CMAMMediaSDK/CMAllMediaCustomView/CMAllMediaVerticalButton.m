//
//  CMAllMediaVerticalButton.m
//  TestDemo
//
//  Created by yao on 2017/12/26.
//  Copyright © 2017年 王智垚. All rights reserved.
//

#import "CMAllMediaVerticalButton.h"

@implementation CMAllMediaVerticalButton

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    CGRect tempImageviewRect = self.imageView.frame;
    tempImageviewRect.origin.y = 0;
    tempImageviewRect.origin.x = (self.bounds.size.width - tempImageviewRect.size.width) / 2;
    self.imageView.frame = tempImageviewRect;

    self.titleLabel.frame = CGRectMake(0, self.imageView.frame.size.height +1, self.bounds.size.width, self.bounds.size.height - self.imageView.frame.size.height);
}
@end

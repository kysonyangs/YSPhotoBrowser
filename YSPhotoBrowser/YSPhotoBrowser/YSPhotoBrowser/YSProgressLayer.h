//
//  YSProgressLayer.h
//  YSPhotoBrowser
//
//  Created by Kyson on 2018/9/18.
//  Copyright © 2018年 YangShen. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YSProgressLayer : CAShapeLayer

+ (instancetype)progressLayer;
- (void)startSpin;
- (void)stopSpin;

@end

NS_ASSUME_NONNULL_END

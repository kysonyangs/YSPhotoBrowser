//
//  YSPhotoView.h
//  YSPhotoBrowser
//
//  Created by Kyson on 2018/9/18.
//  Copyright © 2018年 YangShen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YSProgressLayer.h"

NS_ASSUME_NONNULL_BEGIN

extern const CGFloat kYSPhotoViewPadding;

@protocol YSImageManagerProtocol;
@class YSPhotoItem;

@interface YSPhotoView : UIScrollView

@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) YSProgressLayer *progressLayer;
@property (nonatomic, strong, readonly) YSPhotoItem *item;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setItem:(YSPhotoItem *)item determinate:(BOOL)determinate;
- (void)resizeImageView;
- (void)cancelCurrentImageLoad;

@end

NS_ASSUME_NONNULL_END

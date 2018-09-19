//
//  YSPhotoBrowser.h
//  YSPhotoBrowser
//
//  Created by Kyson on 2018/9/18.
//  Copyright © 2018年 YangShen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YSPhotoItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, YSPhotoBrowserPageIndicatorStyle) {
    YSPhotoBrowserPageIndicatorStyleDot,
    YSPhotoBrowserPageIndicatorStyleText,
};

typedef NS_ENUM(NSUInteger, YSPhotoBrowserImageLoadingStyle) {
    YSPhotoBrowserImageLoadingStyleIndeterminate,
    YSPhotoBrowserImageLoadingStyleDeterminate,
};

@class YSPhotoBrowser;
@protocol YSImageManagerProtocol;

@protocol YSPhotoBrowserDelegate <NSObject>

@optional
- (void)ys_photoBrowser:(YSPhotoBrowser *)browser didSelectItem:(YSPhotoItem *)item atIndex:(NSUInteger)index;

// If you do not implement this method, there will be a default implementation which will call the system share sheet `UIActivityViewController`
- (void)ys_photoBrowser:(YSPhotoBrowser *)browser didLongPressItem:(YSPhotoItem *)item atIndex:(NSUInteger)index;

@end

@interface YSPhotoBrowser : UIViewController

@property (class, nonatomic, strong) Class imageManagerClass;
@property (class, nonatomic, strong) Class imageViewClass;

@property (nonatomic, assign) YSPhotoBrowserPageIndicatorStyle pageindicatorStyle;
@property (nonatomic, assign) YSPhotoBrowserImageLoadingStyle loadingStyle;
@property (nonatomic, weak) id<YSPhotoBrowserDelegate> delegate;

+ (instancetype)browserWithPhotoItems:(NSArray<YSPhotoItem *> *)items selectedIndex:(NSUInteger)selectedIndex;
- (instancetype)initWithPhotoItems:(NSArray<YSPhotoItem *> *)items selectedIndex:(NSUInteger)selectedIndex;
- (void)showFromViewController:(UIViewController *)vc;
- (UIImage *)imageForItem:(YSPhotoItem *)item;
- (UIImage *)imageAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END

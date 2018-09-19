//
//  YSImageManagerProtocol.h
//  YSPhotoBrowser
//
//  Created by Kyson on 2018/9/18.
//  Copyright © 2018年 YangShen. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^YSImageManagerProgressBlock)(NSInteger receivedSize, NSInteger expectedSize);

typedef void (^YSImageManagerCompletionBlock)(UIImage * _Nullable image, NSURL * _Nullable url, BOOL success, NSError * _Nullable error);

@protocol YSImageManagerProtocol <NSObject>

+ (void)setImageForImageView:(nullable UIImageView *)imageView
                     withURL:(nullable NSURL *)imageURL
                 placeholder:(nullable UIImage *)placeholder
                    progress:(nullable YSImageManagerProgressBlock)progress
                  completion:(nullable YSImageManagerCompletionBlock)completion;

+ (void)cancelImageRequestForImageView:(nullable UIImageView *)imageView;

+ (UIImage *_Nullable)imageFromMemoryForURL:(nullable NSURL *)url;

+ (UIImage *_Nullable)imageForURL:(nullable NSURL *)url;

@end

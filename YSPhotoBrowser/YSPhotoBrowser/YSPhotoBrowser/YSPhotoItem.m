//
//  YSPhotoItem.m
//  YSPhotoBrowser
//
//  Created by Kyson on 2018/9/18.
//  Copyright © 2018年 YangShen. All rights reserved.
//

#import "YSPhotoItem.h"
#import "YSPhotoBrowser.h"
#import "YSImageManagerProtocol.h"

@interface YSPhotoItem ()

@property (nonatomic, strong, readwrite) UIImage *thumbImage;
@property (nonatomic, strong, readwrite) UIImage *image;
@property (nonatomic, strong, readwrite) NSURL *imageUrl;

@end

@implementation YSPhotoItem

- (instancetype)initWithSourceView:(UIView *)view
                        thumbImage:(UIImage *)image
                          imageUrl:(NSURL *)url {
    if (self = [super init]) {
        _sourceView = view;
        _thumbImage = image;
        _imageUrl = url;
        _image = [YSPhotoBrowser.imageManagerClass imageForURL:_imageUrl];
        _finished = _image != nil;
    }
    return self;
}

- (instancetype)initWithSourceView:(UIImageView *)view
                          imageUrl:(NSURL *)url {
    return [self initWithSourceView:view
                         thumbImage:view.image
                           imageUrl:url];
}

- (instancetype)initWithSourceView:(UIImageView *)view
                             image:(UIImage *)image {
    if (self = [super init]) {
        _sourceView = view;
        _thumbImage = image;
        _imageUrl = nil;
        _image = image;
    }
    return self;
}

+ (instancetype)itemWithSourceView:(UIView *)view
                        thumbImage:(UIImage *)image
                          imageUrl:(NSURL *)url {
    return [[YSPhotoItem alloc] initWithSourceView:view
                                        thumbImage:image
                                          imageUrl:url];
}

+ (instancetype)itemWithSourceView:(UIImageView *)view
                          imageUrl:(NSURL *)url {
    return [[YSPhotoItem alloc] initWithSourceView:view
                                          imageUrl:url];
}

+ (instancetype)itemWithSourceView:(UIImageView *)view
                             image:(UIImage *)image {
    return [[YSPhotoItem alloc] initWithSourceView:view
                                             image:image];
}

@end

//
//  YSPhotoView.m
//  YSPhotoBrowser
//
//  Created by Kyson on 2018/9/18.
//  Copyright © 2018年 YangShen. All rights reserved.
//

#import "YSPhotoView.h"
#import "YSPhotoItem.h"
#import "YSImageManagerProtocol.h"
#import "YSPhotoBrowser.h"

const CGFloat kYSPhotoViewPadding = 10;
const CGFloat kYSPhotoViewMaxScale = 3;

@interface YSPhotoView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) UIImageView *imageView;
@property (nonatomic, strong, readwrite) YSProgressLayer *progressLayer;
@property (nonatomic, strong, readwrite) YSPhotoItem *item;

@end

@implementation YSPhotoView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.bouncesZoom = YES;
        self.maximumZoomScale = kYSPhotoViewMaxScale;
        self.multipleTouchEnabled = YES;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.delegate = self;
        if (@available(iOS 11.0, *)) { // 忽略内边距
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        _imageView = [[YSPhotoBrowser.imageViewClass alloc] init];
        _imageView.backgroundColor = [UIColor darkGrayColor];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [self addSubview:_imageView];
        [self resizeImageView];
        
        _progressLayer = [YSProgressLayer progressLayer];
        _progressLayer.hidden = YES;
        [self.layer addSublayer:_progressLayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _progressLayer.position = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
}

- (void)setItem:(YSPhotoItem *)item determinate:(BOOL)determinate {
    _item = item;
    [YSPhotoBrowser.imageManagerClass cancelImageRequestForImageView:_imageView];
    
    if (item) {
        if (item.image) {
            _imageView.image = item.image;
            _item.finished = YES;
            [_progressLayer stopSpin];
            _progressLayer.hidden = YES;
            [self resizeImageView];
            return;
        }
        
        __weak typeof(self) wself = self;
        YSImageManagerProgressBlock progressBlock = nil;
        if (determinate) {
            progressBlock = ^(NSInteger receivedSize, NSInteger expectedSize) {
                __strong typeof(wself) sself = wself;
                CGFloat progress = (CGFloat)receivedSize / expectedSize;
                sself.progressLayer.hidden = NO;
                sself.progressLayer.strokeEnd = MAX(progress, 0.01);
            };
        } else {
            [_progressLayer startSpin];
        }
        _progressLayer.hidden = NO;
        
        _imageView.image = item.thumbImage;
        [YSPhotoBrowser.imageManagerClass setImageForImageView:_imageView withURL:item.imageUrl placeholder:item.thumbImage progress:progressBlock completion:^(UIImage *image, NSURL *url, BOOL finished, NSError *error) {
            __strong typeof(wself) sself = wself;
            if (finished) {
                [sself resizeImageView];
            }
            [sself.progressLayer stopSpin];
            sself.progressLayer.hidden = YES;
            sself.item.finished = YES;
        }];
        
    } else {
        [_progressLayer stopSpin];
        _progressLayer.hidden = YES;
        _imageView.image = nil;
    }
    
    [self resizeImageView];
}

- (void)resizeImageView {
    if (_imageView.image) {
        CGSize imageSize = _imageView.image.size;
        CGFloat width = self.frame.size.width - 2 * kYSPhotoViewPadding;
        CGFloat height = width * (imageSize.height / imageSize.width);
        CGRect rect = CGRectMake(0, 0, width, height);
        
        _imageView.frame = rect;
        
        // If image is very high, show top content.
        if (height <= self.bounds.size.height) {
            _imageView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
        } else {
            _imageView.center = CGPointMake(self.bounds.size.width / 2, height / 2);
        }
        
        // If image is very wide, make sure user can zoom to fullscreen.
        if (width / height > 2) {
            self.maximumZoomScale = self.bounds.size.height / height;
        }
        
    } else {
        CGFloat width = self.frame.size.width - 2 * kYSPhotoViewPadding;
        _imageView.frame = CGRectMake(0, 0, width, width * 2.0 / 3);
        _imageView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    }
    
    self.contentSize = _imageView.frame.size;
}

- (void)cancelCurrentImageLoad {
    [YSPhotoBrowser.imageManagerClass cancelImageRequestForImageView:_imageView];
    [_progressLayer stopSpin];
    _progressLayer.hidden = YES;
}

- (BOOL)isScrollViewOnTopOrBottom {
    CGPoint translation = [self.panGestureRecognizer translationInView:self];
    if (translation.y > 0 && self.contentOffset.y <= 0) {
        return YES;
    }
    CGFloat maxOffsetY = floor(self.contentSize.height - self.bounds.size.height);
    if (translation.y < 0 && self.contentOffset.y >= maxOffsetY) {
        return YES;
    }
    return NO;
}

#pragma mark - <UIScrollViewDelegate>
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    _imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                    scrollView.contentSize.height * 0.5 + offsetY);
}

#pragma mark - <UIGestureRecognizerDelegate>
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerStatePossible) {
            if ([self isScrollViewOnTopOrBottom]) {
                return NO;
            }
        }
    }
    return YES;
}

@end

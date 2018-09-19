//
//  YSPhotoBrowser.m
//  YSPhotoBrowser
//
//  Created by Kyson on 2018/9/18.
//  Copyright © 2018年 YangShen. All rights reserved.
//

#import "YSPhotoBrowser.h"
#import "YSPhotoView.h"
#import "YSSDImageManager.h"
#import <FLAnimatedImage/FLAnimatedImage.h>

static const NSTimeInterval kAnimationDuration = 0.33;
static const CGFloat kPageControlHeight = 20;
static const CGFloat kPageControlBottomSpacing = 40;
static Class ImageManagerClass = nil;
static Class ImageViewClass = nil;

@interface YSPhotoBrowser () <UIScrollViewDelegate, UIViewControllerTransitioningDelegate, CAAnimationDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *photoItems;
@property (nonatomic, strong) NSMutableSet *reusableItemViews;
@property (nonatomic, strong) NSMutableArray *visibleItemViews;
@property (nonatomic, assign) NSUInteger currentPage;
@property (nonatomic, strong) UIImageView *backgroundView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) UILabel *pageLabel;
@property (nonatomic, assign) BOOL presented;
@property (nonatomic, assign) CGPoint startLocation;
@property (nonatomic, assign) CGRect startFrame;

@end

@implementation YSPhotoBrowser

#pragma mark - Initializer

+ (instancetype)browserWithPhotoItems:(NSArray<YSPhotoItem *> *)items selectedIndex:(NSUInteger)selectedIndex {
    return [[self alloc] initWithPhotoItems:items selectedIndex:selectedIndex];
}

- (instancetype)init {
    NSAssert(NO, @"Use initWithPhotoItems:selectedIndex: instead.");
    return nil;
}

- (instancetype)initWithPhotoItems:(NSArray<YSPhotoItem *> *)items selectedIndex:(NSUInteger)selectedIndex {
    if (self = [super init]) {
        // 自定义转场动画
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        _photoItems = [NSMutableArray arrayWithArray:items];
        _currentPage = selectedIndex;
        
        _pageindicatorStyle = YSPhotoBrowserPageIndicatorStyleDot;
        _loadingStyle = YSPhotoBrowserImageLoadingStyleDeterminate;
        
        _reusableItemViews = [NSMutableSet set];
        _visibleItemViews = [NSMutableArray array];
        
        if (ImageManagerClass == nil) {
            ImageManagerClass = YSSDImageManager.class;
        }
        
        if (ImageViewClass == nil) {
            ImageViewClass = FLAnimatedImageView.class;
        }
    }
    return self;
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    _backgroundView = [[UIImageView alloc] init];
    _backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    _backgroundView.alpha = 0;
    [self.view addSubview:_backgroundView];
    
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.pagingEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.delegate = self;
    [self.view addSubview:_scrollView];
    
    if (_pageindicatorStyle == YSPhotoBrowserPageIndicatorStyleDot && _photoItems.count < 10) {
        if (_photoItems.count > 1) {
            _pageControl = [[UIPageControl alloc] init];
            _pageControl.numberOfPages = _photoItems.count;
            _pageControl.currentPage = _currentPage;
            [self.view addSubview:_pageControl];
        }
    } else {
        _pageLabel = [[UILabel alloc] init];
        _pageLabel.textColor = [UIColor whiteColor];
        _pageLabel.font = [UIFont systemFontOfSize:16];
        _pageLabel.textAlignment = NSTextAlignmentCenter;
        [self configPageLabelWithPage:_currentPage];
        [self.view addSubview:_pageLabel];
    }
    
    [self setupFrames];
    
    [self addGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    YSPhotoItem *item = [_photoItems objectAtIndex:_currentPage];
    if (_delegate && [_delegate respondsToSelector:@selector(ys_photoBrowser:didSelectItem:atIndex:)]) {
        [_delegate ys_photoBrowser:self didSelectItem:item atIndex:_currentPage];
    }
    
    YSPhotoView *photoView = [self photoViewForPage:_currentPage];
    photoView.imageView.image = item.thumbImage;
    [photoView resizeImageView];
    
    if (item.sourceView == nil) {
        photoView.alpha = 0;
        [UIView animateWithDuration:kAnimationDuration animations:^{
            self.view.backgroundColor = [UIColor blackColor];
            self.backgroundView.alpha = 1;
            photoView.alpha = 1;
        } completion:^(BOOL finished) {
            [self configPhotoView:photoView withItem:item];
            self.presented = YES;
            [self setStatusBarHidden:YES];
        }];
        return;
    }
    
    CGRect endRect = photoView.imageView.frame;
    CGRect sourceRect;
    CGFloat systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersion >= 8.0 && systemVersion < 9.0) {
        sourceRect = [item.sourceView.superview convertRect:item.sourceView.frame toCoordinateSpace:photoView];
    } else {
        sourceRect = [item.sourceView.superview convertRect:item.sourceView.frame toView:photoView];
    }
    photoView.imageView.frame = sourceRect;
    
    // 开始动画
    CGRect startBounds = CGRectMake(0, 0, sourceRect.size.width, sourceRect.size.height);
    CGRect endBounds = CGRectMake(0, 0, endRect.size.width, endRect.size.height);
    UIBezierPath *startPath = [UIBezierPath bezierPathWithRoundedRect:startBounds cornerRadius:MAX(item.sourceView.layer.cornerRadius, 0.1)];
    UIBezierPath *endPath = [UIBezierPath bezierPathWithRoundedRect:endBounds cornerRadius:0.1];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = endBounds;
    photoView.imageView.layer.mask = maskLayer;
    
    CABasicAnimation *maskAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    maskAnimation.duration = kAnimationDuration;
    maskAnimation.fromValue = (__bridge id _Nullable)startPath.CGPath;
    maskAnimation.toValue = (__bridge id _Nullable)endPath.CGPath;
    maskAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [maskLayer addAnimation:maskAnimation forKey:nil];
    maskLayer.path = endPath.CGPath;
    
    [UIView animateWithDuration:kAnimationDuration animations:^{
        photoView.imageView.frame = endRect;
        self.view.backgroundColor = [UIColor blackColor];
        self.backgroundView.alpha = 1;
    } completion:^(BOOL finished) {
        [self configPhotoView:photoView withItem:item];
        self.presented = YES;
        [self setStatusBarHidden:YES];
        photoView.imageView.layer.mask = nil;
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self setupFrames];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

#pragma mark - Public

- (void)showFromViewController:(UIViewController *)vc {
    [vc presentViewController:self animated:NO completion:nil];
}

- (UIImage *)imageForItem:(YSPhotoItem *)item {
    return [ImageManagerClass imageForURL:item.imageUrl];
}

- (UIImage *)imageAtIndex:(NSUInteger)index {
    YSPhotoItem *item = [_photoItems objectAtIndex:index];
    return [ImageManagerClass imageForURL:item.imageUrl];
}

#pragma mark - Private

- (void)configPageLabelWithPage:(NSUInteger)page {
    _pageLabel.text = [NSString stringWithFormat:@"%lu / %lu", _currentPage+1, _photoItems.count];
}

- (void)setupFrames {
    CGRect rect = self.view.bounds;
    _backgroundView.frame = rect;
    
    CGFloat scrollX = rect.origin.x - kYSPhotoViewPadding;
    CGFloat scrollW = rect.size.width + kYSPhotoViewPadding;
    _scrollView.frame = CGRectMake(scrollX, rect.origin.y, scrollW, rect.size.height);
    
    CGRect pageRect = CGRectMake(0, rect.size.height - kPageControlBottomSpacing, rect.size.width, kPageControlHeight);
    _pageControl.frame = pageRect;
    _pageLabel.frame = pageRect;
    
    for (YSPhotoView *photoView in _visibleItemViews) {
        CGRect rect = _scrollView.bounds;
        rect.origin.x = photoView.tag * _scrollView.bounds.size.width;
        photoView.frame = rect;
        [photoView resizeImageView];
    }
    
    CGPoint contentOffset = CGPointMake(_scrollView.bounds.size.width * _currentPage, 0);
    [_scrollView setContentOffset:contentOffset];
    if (contentOffset.x == 0) {
        [self scrollViewDidScroll:_scrollView];
    }
    
    CGSize contentSize = CGSizeMake(scrollW * _photoItems.count, rect.size.height);
    _scrollView.contentSize = contentSize;
}

- (YSPhotoView *)photoViewForPage:(NSUInteger)page {
    for (YSPhotoView *photoView in _visibleItemViews) {
        if (photoView.tag == page) {
            return photoView;
        }
    }
    return nil;
}

- (void)configPhotoView:(YSPhotoView *)photoView withItem:(YSPhotoItem *)item {
    [photoView setItem:item determinate:(_loadingStyle == YSPhotoBrowserImageLoadingStyleDeterminate)];
}

- (void)setStatusBarHidden:(BOOL)hidden {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (hidden) {
        window.windowLevel = UIWindowLevelStatusBar + 1;
    } else {
        window.windowLevel = UIWindowLevelNormal;
    }
}

- (void)updateReusableItemViews {
    NSMutableArray *itemsForRemove = @[].mutableCopy;
    for (YSPhotoView *photoView in _visibleItemViews) {
        if (photoView.frame.origin.x + photoView.frame.size.width < _scrollView.contentOffset.x - _scrollView.frame.size.width ||
            photoView.frame.origin.x > _scrollView.contentOffset.x + 2 * _scrollView.frame.size.width) {
            [photoView removeFromSuperview];
            [self configPhotoView:photoView withItem:nil];
            [itemsForRemove addObject:photoView];
            [_reusableItemViews addObject:photoView];
        }
    }
    [_visibleItemViews removeObjectsInArray:itemsForRemove];
}

- (void)configItemViews {
    NSInteger page = _scrollView.contentOffset.x / _scrollView.frame.size.width + 0.5;
    for (NSInteger i = page - 1; i <= page + 1; i++) {
        if (i < 0 || i >= _photoItems.count) {
            continue;
        }
        YSPhotoView *photoView = [self photoViewForPage:i];
        if (photoView == nil) {
            photoView = [self dequeueReusableItemView];
            CGRect rect = _scrollView.bounds;
            rect.origin.x = i * _scrollView.bounds.size.width;
            photoView.frame = rect;
            photoView.tag = i;
            [_scrollView addSubview:photoView];
            [_visibleItemViews addObject:photoView];
        }
        if (photoView.item == nil && self.presented) {
            YSPhotoItem *item = [_photoItems objectAtIndex:i];
            [self configPhotoView:photoView withItem:item];
        }
    }
    
    if (page != _currentPage && self.presented && (page >= 0 && page < _photoItems.count)) {
        YSPhotoItem *item = [_photoItems objectAtIndex:page];
        _currentPage = page;
        if (_pageindicatorStyle == YSPhotoBrowserPageIndicatorStyleDot && _photoItems.count < 10) {
            _pageControl.currentPage = page;
        } else {
            [self configPageLabelWithPage:_currentPage];
        }
        if (_delegate && [_delegate respondsToSelector:@selector(ys_photoBrowser:didSelectItem:atIndex:)]) {
            [_delegate ys_photoBrowser:self didSelectItem:item atIndex:page];
        }
    }
}

- (YSPhotoView *)dequeueReusableItemView {
    YSPhotoView *photoView = [_reusableItemViews anyObject];
    if (photoView == nil) {
        photoView = [[YSPhotoView alloc] initWithFrame:_scrollView.bounds];
    } else {
        [_reusableItemViews removeObject:photoView];
    }
    photoView.tag = -1;
    return photoView;
}

- (void)dismissAnimated:(BOOL)animated {
    for (YSPhotoView *photoView in _visibleItemViews) {
        [photoView cancelCurrentImageLoad];
    }
    
    YSPhotoItem *item = [_photoItems objectAtIndex:_currentPage];
    if (animated) {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            item.sourceView.alpha = 1;
        }];
    } else {
        item.sourceView.alpha = 1;
    }
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - Gesture Recognizer

- (void)addGestureRecognizer {
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSingleTap:)];
    singleTap.numberOfTapsRequired = 1;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.view addGestureRecognizer:singleTap];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPress:)];
    [self.view addGestureRecognizer:longPress];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [self.view addGestureRecognizer:pan];
}

- (void)didSingleTap:(UITapGestureRecognizer *)tap {
    [self showDismissalAnimation];
}

- (void)didDoubleTap:(UITapGestureRecognizer *)tap {
    YSPhotoView *photoView = [self photoViewForPage:_currentPage];
    YSPhotoItem *item = [_photoItems objectAtIndex:_currentPage];
    if (!item.finished) {
        return;
    }
    if (photoView.zoomScale > 1) {
        [photoView setZoomScale:1 animated:YES];
    } else {
        CGPoint location = [tap locationInView:self.view];
        CGFloat maxZoomScale = photoView.maximumZoomScale;
        CGFloat width = self.view.bounds.size.width / maxZoomScale;
        CGFloat height = self.view.bounds.size.height / maxZoomScale;
        [photoView zoomToRect:CGRectMake(location.x - width/2, location.y - height/2, width, height) animated:YES];
    }
}

- (void)didLongPress:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state != UIGestureRecognizerStateBegan) {
        return;
    }
    YSPhotoView *photoView = [self photoViewForPage:_currentPage];
    UIImage *image = photoView.imageView.image;
    if (!image) {
        return;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(ys_photoBrowser:didLongPressItem:atIndex:)]) {
        [_delegate ys_photoBrowser:self didLongPressItem:_photoItems[_currentPage] atIndex:_currentPage];
        return;
    }
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        activityViewController.popoverPresentationController.sourceView = longPress.view;
        CGPoint point = [longPress locationInView:longPress.view];
        activityViewController.popoverPresentationController.sourceRect = CGRectMake(point.x, point.y, 1, 1);
    }
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)didPan:(UIPanGestureRecognizer *)pan {
    YSPhotoView *photoView = [self photoViewForPage:_currentPage];
    if (photoView.zoomScale > 1.1) {
        return;
    }
    
    [self performScaleWithPan:pan];
}

- (void)performScaleWithPan:(UIPanGestureRecognizer *)pan {
    YSPhotoView *photoView = [self photoViewForPage:_currentPage];
    CGPoint point = [pan translationInView:self.view];
    CGPoint location = [pan locationInView:photoView];
    CGPoint velocity = [pan velocityInView:self.view];
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            _startLocation = location;
            self.startFrame = photoView.imageView.frame;
            [self handlePanBegin];
            break;
        case UIGestureRecognizerStateChanged: {
            double percent = 1 - fabs(point.y) / self.view.frame.size.height;
            double s = MAX(percent, 0.3);
            
            CGFloat width = self.startFrame.size.width * s;
            CGFloat height = self.startFrame.size.height * s;
            
            CGFloat rateX = (_startLocation.x - self.startFrame.origin.x) / self.startFrame.size.width;
            CGFloat x = location.x - width * rateX;
            
            CGFloat rateY = (_startLocation.y - self.startFrame.origin.y) / self.startFrame.size.height;
            CGFloat y = location.y - height * rateY;
            
//            NSLog(@"%f", rateY);
            
            photoView.imageView.frame = CGRectMake(x, y, width, height);
            
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:percent];
            self.backgroundView.alpha = percent;
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (fabs(point.y) > 100 || fabs(velocity.y) > 500) {
                [self showDismissalAnimation];
            } else {
                [self showCancellationAnimation];
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)handlePanBegin {
    YSPhotoView *photoView = [self photoViewForPage:_currentPage];
    [photoView cancelCurrentImageLoad];
    YSPhotoItem *item = [_photoItems objectAtIndex:_currentPage];
    [self setStatusBarHidden:NO];
    photoView.progressLayer.hidden = YES;
    item.sourceView.alpha = 0;
}

#pragma mark - Animation
- (void)showDismissalAnimation {
    YSPhotoItem *item = [_photoItems objectAtIndex:_currentPage];
    YSPhotoView *photoView = [self photoViewForPage:_currentPage];
    [photoView cancelCurrentImageLoad];
    [self setStatusBarHidden:NO];
    
    if (item.sourceView == nil) {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            self.view.alpha = 0;
        } completion:^(BOOL finished) {
            [self dismissAnimated:NO];
        }];
        return;
    }
    
    photoView.progressLayer.hidden = YES;
    item.sourceView.alpha = 0;
    CGRect sourceRect;
    CGFloat systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersion >= 8.0 && systemVersion < 9.0) {
        sourceRect = [item.sourceView.superview convertRect:item.sourceView.frame toCoordinateSpace:photoView];
    } else {
        sourceRect = [item.sourceView.superview convertRect:item.sourceView.frame toView:photoView];
    }
    
    if (sourceRect.origin.y >= self.view.bounds.size.height - 10) {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            self.view.alpha = 0;
        } completion:^(BOOL finished) {
            [self dismissAnimated:NO];
        }];
        return;
    }
    
    CGRect startRect = photoView.imageView.frame;
    CGRect endBounds = CGRectMake(0, 0, sourceRect.size.width, sourceRect.size.height);
    CGRect startBounds = CGRectMake(0, 0, startRect.size.width, startRect.size.height);
    UIBezierPath *startPath = [UIBezierPath bezierPathWithRoundedRect:startBounds cornerRadius:0.1];
    UIBezierPath *endPath = [UIBezierPath bezierPathWithRoundedRect:endBounds cornerRadius:MAX(item.sourceView.layer.cornerRadius, 0.1)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = endBounds;
    photoView.imageView.layer.mask = maskLayer;
    
    CABasicAnimation *maskAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    maskAnimation.duration = kAnimationDuration;
    maskAnimation.fromValue = (__bridge id _Nullable)startPath.CGPath;
    maskAnimation.toValue = (__bridge id _Nullable)endPath.CGPath;
    maskAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [maskLayer addAnimation:maskAnimation forKey:nil];
    maskLayer.path = endPath.CGPath;
    
    [UIView animateWithDuration:kAnimationDuration animations:^{
        photoView.imageView.frame = sourceRect;
        self.view.backgroundColor = [UIColor clearColor];
        self.backgroundView.alpha = 0;
    } completion:^(BOOL finished) {
        [self dismissAnimated:NO];
    }];
}

- (void)showCancellationAnimation {
    YSPhotoView *photoView = [self photoViewForPage:_currentPage];
    YSPhotoItem *item = [_photoItems objectAtIndex:_currentPage];
    item.sourceView.alpha = 1;
    if (!item.finished) {
        photoView.progressLayer.hidden = NO;
    }
    
    [UIView animateWithDuration:kAnimationDuration animations:^{
        photoView.imageView.frame = self.startFrame;
        
        self.view.backgroundColor = [UIColor blackColor];
        self.backgroundView.alpha = 1;
    } completion:^(BOOL finished) {
        [self setStatusBarHidden:YES];
        [self configPhotoView:photoView withItem:item];
    }];
}

#pragma mark - <CAAnimationDelegate>

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if ([[anim valueForKey:@"id"] isEqualToString:@"throwAnimation"]) {
        [self dismissAnimated:YES];
    }
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateReusableItemViews];
    [self configItemViews];
}

#pragma mark - Setter

+ (void)setImageViewClass:(Class)imageViewClass {
    ImageViewClass = imageViewClass;
}

+ (void)setImageManagerClass:(Class)imageManagerClass {
    ImageManagerClass = imageManagerClass;
}

#pragma mark - Getter

+ (Class)imageViewClass {
    return ImageViewClass;
}

+ (Class)imageManagerClass {
    return ImageManagerClass;
}

@end

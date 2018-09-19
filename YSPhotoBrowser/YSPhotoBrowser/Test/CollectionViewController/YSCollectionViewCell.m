//
//  YSCollectionViewCell.m
//  YSPhotoBrowser
//
//  Created by Kyson on 2018/9/19.
//  Copyright © 2018年 YangShen. All rights reserved.
//

#import "YSCollectionViewCell.h"

@implementation YSCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _imageView = [[UIImageView alloc] init];
        [self addSubview:_imageView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _imageView.frame = self.bounds;
}

@end

//
//  YSCollectionTestViewController.m
//  YSPhotoBrowser
//
//  Created by Kyson on 2018/9/19.
//  Copyright © 2018年 YangShen. All rights reserved.
//

#import "YSCollectionTestViewController.h"
#import "YSPhotoBrowser.h"
#import "YSCollectionViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface YSCollectionTestViewController () <YSPhotoBrowserDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) NSMutableArray *urls;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *items;

@end

@implementation YSCollectionTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"CollectionView Test";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(100, 100);
    flowLayout.minimumLineSpacing = 20;
    flowLayout.minimumInteritemSpacing = 5;
    flowLayout.sectionInset = UIEdgeInsetsMake(20, 20, 20, 20);
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.backgroundColor = [UIColor whiteColor];
    [_collectionView registerClass:[YSCollectionViewCell class] forCellWithReuseIdentifier:@"cellid"];
    [self.view addSubview:_collectionView];
    
    NSArray *urls =  @[
                       @"http://ww2.sinaimg.cn/thumbnail/642beb18gw1ep3629gfm0g206o050b2a.gif",
                       @"http://ww4.sinaimg.cn/thumbnail/9e9cb0c9jw1ep7nlyu8waj20c80kptae.jpg",
                       @"http://ww3.sinaimg.cn/thumbnail/8e88b0c1gw1e9lpr1xydcj20gy0o9q6s.jpg",
                       @"http://ww2.sinaimg.cn/thumbnail/8e88b0c1gw1e9lpr2n1jjj20gy0o9tcc.jpg",
                       @"http://ww4.sinaimg.cn/thumbnail/8e88b0c1gw1e9lpr4nndfj20gy0o9q6i.jpg",
                       @"http://ww3.sinaimg.cn/thumbnail/8e88b0c1gw1e9lpr57tn9j20gy0obn0f.jpg",
                       @"http://ww2.sinaimg.cn/thumbnail/677febf5gw1erma104rhyj20k03dz16y.jpg",
                       @"http://ww4.sinaimg.cn/thumbnail/677febf5gw1erma1g5xd0j20k0esa7wj.jpg",
                       @"http://ww4.sinaimg.cn/thumbnail/a15bd3a5jw1f12r9ku6wjj20u00mhn22.jpg",
                       @"http://ww2.sinaimg.cn/thumbnail/a15bd3a5jw1f01hkxyjhej20u00jzacj.jpg",
                       @"http://ww4.sinaimg.cn/thumbnail/a15bd3a5jw1f01hhs2omoj20u00jzwh9.jpg",
                       @"http://ww2.sinaimg.cn/thumbnail/a15bd3a5jw1ey1oyiyut7j20u00mi0vb.jpg",
                       @"http://ww2.sinaimg.cn/thumbnail/a15bd3a5jw1exkkw984e3j20u00miacm.jpg",
                       @"http://ww4.sinaimg.cn/thumbnail/a15bd3a5jw1ezvdc5dt1pj20ku0kujt7.jpg",
                       @"http://ww3.sinaimg.cn/thumbnail/a15bd3a5jw1ew68tajal7j20u011iacr.jpg",
                       @"http://ww2.sinaimg.cn/thumbnail/a15bd3a5jw1eupveeuzajj20hs0hs75d.jpg",
                       @"http://ww2.sinaimg.cn/thumbnail/d8937438gw1fb69b0hf5fj20hu13fjxj.jpg",
                       ];
    _urls = @[].mutableCopy;
    for (int i = 0; i < 10; i++) {
        [_urls addObjectsFromArray:urls];
    }
}

// MARK: - KSPhotoBrowserDelegate

- (void)ys_photoBrowser:(YSPhotoBrowser *)browser didSelectItem:(YSPhotoItem *)item atIndex:(NSUInteger)index {
    NSLog(@"selected index: %ld", index);
}

- (void)ys_photoBrowser:(YSPhotoBrowser *)browser didLongPressItem:(YSPhotoItem *)item atIndex:(NSUInteger)index {
    UIImage *image = [browser imageForItem:item];
    NSLog(@"long pressed image:%@", image);
}

// MARK: - CollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _urls.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YSCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellid" forIndexPath:indexPath];
    
    NSString *url = _urls[indexPath.row];

    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:url]];
    return cell;
}

// MARK: - CollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *items = @[].mutableCopy;
    for (int i = 0; i < _urls.count; i++) {
        YSCollectionViewCell *cell = (YSCollectionViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        NSString *url = [_urls[i] stringByReplacingOccurrencesOfString:@"thumbnail" withString:@"bmiddle"];
        YSPhotoItem *item = [YSPhotoItem itemWithSourceView:cell.imageView imageUrl:[NSURL URLWithString:url]];
        NSLog(@"%@", item.sourceView);
        [items addObject:item];
    }
    [self showBrowserWithPhotoItems:items selectedIndex:indexPath.item];
}

- (void)showBrowserWithPhotoItems:(NSArray *)items selectedIndex:(NSUInteger)selectedIndex {
    self.items = items;
    YSPhotoBrowser *browser = [YSPhotoBrowser browserWithPhotoItems:items selectedIndex:selectedIndex];
    browser.delegate = self;
    [browser showFromViewController:self];
}


@end

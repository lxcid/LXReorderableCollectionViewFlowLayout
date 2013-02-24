//
//  LXReorderableCollectionViewFlowLayout.h
//
//  Created by Stan Chang Khin Boon on 1/10/12.
//  Copyright (c) 2012 d--buzz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LXReorderableCollectionViewFlowLayout : UICollectionViewFlowLayout <UIGestureRecognizerDelegate>

- (void)setUpGestureRecognizersOnCollectionView __attribute__((deprecated));

@property (assign, nonatomic) CGFloat scrollingSpeed;
@property (assign, nonatomic) UIEdgeInsets scrollingTriggerEdgeInsets;
@property (readonly, nonatomic) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (readonly, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;

@end

@protocol LXReorderableCollectionViewDelegateFlowLayout <UICollectionViewDelegateFlowLayout>

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath;

@optional

- (BOOL)collectionView:(UICollectionView *)theCollectionView layout:(UICollectionViewLayout *)layout itemAtIndexPath:(NSIndexPath *)theFromIndexPath shouldMoveToIndexPath:(NSIndexPath *)theToIndexPath;
- (BOOL)collectionView:(UICollectionView *)theCollectionView layout:(UICollectionViewLayout *)layout shouldBeginReorderingAtIndexPath:(NSIndexPath *)theIndexPath;
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout willBeginReorderingAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout didBeginReorderingAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout willEndReorderingAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout didEndReorderingAtIndexPath:(NSIndexPath *)indexPath;

@end
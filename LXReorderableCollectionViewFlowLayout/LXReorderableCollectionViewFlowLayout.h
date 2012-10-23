//
//  LXReorderableCollectionViewFlowLayout.h
//
//  Created by Stan Chang Khin Boon on 1/10/12.
//  Copyright (c) 2012 d--buzz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LXReorderableCollectionViewFlowLayout : UICollectionViewFlowLayout <UIGestureRecognizerDelegate>

@property (assign, nonatomic) UIEdgeInsets triggerScrollingEdgeInsets;
@property (assign, nonatomic) CGFloat scrollingSpeed;
@property (strong, nonatomic) NSTimer *scrollingTimer;

@property (weak, nonatomic) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (weak, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;

@property (strong, nonatomic) NSIndexPath *selectedItemIndexPath;
@property (weak, nonatomic) UIView *currentView;
@property (assign, nonatomic) CGPoint currentViewCenter;
@property (assign, nonatomic) CGPoint panTranslationInCollectionView;

@property (assign, nonatomic) BOOL alwaysScroll;

@property (strong, nonatomic) NSTimer *invalidateLayoutTimer;
@property (strong, nonatomic) NSIndexPath *catchItemIndexPath;

- (void)setUpGestureRecognizersOnCollectionView;

@end

@protocol LXReorderableCollectionViewDelegateFlowLayout <UICollectionViewDelegateFlowLayout>

- (void)collectionView:(UICollectionView *)theCollectionView layout:(UICollectionViewLayout *)theLayout itemAtIndexPath:(NSIndexPath *)theFromIndexPath willMoveToIndexPath:(NSIndexPath *)theToIndexPath;

@optional

- (void)collectionView:(UICollectionView *)theCollectionView layout:(UICollectionViewLayout *)theLayout willBeginReorderingAtIndexPath:(NSIndexPath *)theIndexPath;
- (void)collectionView:(UICollectionView *)theCollectionView layout:(UICollectionViewLayout *)theLayout didBeginReorderingAtIndexPath:(NSIndexPath *)theIndexPath;
- (void)collectionView:(UICollectionView *)theCollectionView layout:(UICollectionViewLayout *)theLayout willEndReorderingAtIndexPath:(NSIndexPath *)theIndexPath;
- (void)collectionView:(UICollectionView *)theCollectionView layout:(UICollectionViewLayout *)theLayout didEndReorderingAtIndexPath:(NSIndexPath *)theIndexPath;
- (BOOL)collectionView:(UICollectionView *)theCollectionView layout:(UICollectionViewLayout *)theLayout shouldDropIndexPath:(NSIndexPath *)theDropIndexPath onIndexPath:(NSIndexPath *)theCatchIndexPath;
- (void)collectionView:(UICollectionView *)theCollectionView layout:(UICollectionViewLayout *)theLayout willDropIndexPath:(NSIndexPath *)theDropIndexPath onIndexPath:(NSIndexPath *)theCatchIndexPath;

@end
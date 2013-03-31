//
//  LXReorderableCollectionViewFlowLayout.m
//
//  Created by Stan Chang Khin Boon on 1/10/12.
//  Copyright (c) 2012 d--buzz. All rights reserved.
//

#import "LXReorderableCollectionViewFlowLayout.h"
#import <QuartzCore/QuartzCore.h>

#define LX_FRAMES_PER_SECOND 60.0

#ifndef CGGEOMETRY_LXSUPPORT_H_
CG_INLINE CGPoint
LXS_CGPointAdd(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}
#endif

typedef NS_ENUM(NSInteger, LXScrollingDirection) {
    LXScrollingDirectionUnknown = 0,
    LXScrollingDirectionUp,
    LXScrollingDirectionDown,
    LXScrollingDirectionLeft,
    LXScrollingDirectionRight
};

static NSString * const kLXScrollingDirectionKey = @"LXScrollingDirection";
static NSString * const kLXCollectionViewKeyPath = @"collectionView";

@interface UICollectionViewCell (LXReorderableCollectionViewFlowLayout)

- (UIImage *)LX_rasterizedImage;

@end

@implementation UICollectionViewCell (LXReorderableCollectionViewFlowLayout)

- (UIImage *)LX_rasterizedImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

@interface LXReorderableCollectionViewFlowLayout ()

@property (strong, nonatomic) NSIndexPath *selectedItemIndexPath;
@property (strong, nonatomic) UIView *currentView;
@property (assign, nonatomic) CGPoint currentViewCenter;
@property (assign, nonatomic) CGPoint panTranslationInCollectionView;
@property (strong, nonatomic) NSTimer *scrollingTimer;

@property (assign, nonatomic, readonly) id<LXReorderableCollectionViewDatasource> dataSource;
@property (assign, nonatomic, readonly) id<LXReorderableCollectionViewDelegate> delegate;

@end

@implementation LXReorderableCollectionViewFlowLayout

- (void)setDefaults {
    _scrollingSpeed = 300.0f;
    _scrollingTriggerEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
}

- (void)setupCollectionView {
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                             action:@selector(handleLongPressGesture:)];
    longPressGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:longPressGestureRecognizer];
    
    // Links the default long press gesture recognizer to the custom long press gesture recognizer we are creating now
    // by enforcing failure dependency so that they doesn't clash.
    for (UIGestureRecognizer *gestureRecognizer in self.collectionView.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gestureRecognizer requireGestureRecognizerToFail:longPressGestureRecognizer];
        }
    }
    _longPressGestureRecognizer = longPressGestureRecognizer;
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(handlePanGesture:)];
    panGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:panGestureRecognizer];
    _panGestureRecognizer = panGestureRecognizer;
}

- (id)init {
    self = [super init];
    if (self) {
        [self setDefaults];
        [self addObserver:self forKeyPath:kLXCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setDefaults];
        [self addObserver:self forKeyPath:kLXCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    [self invalidatesScrollTimer];
    [self removeObserver:self forKeyPath:kLXCollectionViewKeyPath];
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    if ([layoutAttributes.indexPath isEqual:self.selectedItemIndexPath]) {
        layoutAttributes.hidden = YES;
    }
}

- (id<LXReorderableCollectionViewDatasource>)dataSource {
    return (id<LXReorderableCollectionViewDatasource>)self.collectionView.dataSource;
}

- (id<LXReorderableCollectionViewDelegate>)delegate {
    return (id<LXReorderableCollectionViewDelegate>)self.collectionView.delegate;
}

- (void)invalidateLayoutIfNecessary {
    NSIndexPath *newIndexPath = [self.collectionView indexPathForItemAtPoint:self.currentView.center];
    NSIndexPath *previousIndexPath = self.selectedItemIndexPath;
    
    if ((newIndexPath == nil) || [newIndexPath isEqual:previousIndexPath]) {
        return;
    }
    
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:canMoveToIndexPath:)] &&
        ![self.dataSource collectionView:self.collectionView itemAtIndexPath:previousIndexPath canMoveToIndexPath:newIndexPath]) {
        return;
    }
    
    self.selectedItemIndexPath = newIndexPath;
    
    [self.dataSource collectionView:self.collectionView itemAtIndexPath:previousIndexPath willMoveToIndexPath:newIndexPath];
    
    __weak typeof(self) weakSelf = self;
    [self.collectionView performBatchUpdates:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf.collectionView deleteItemsAtIndexPaths:@[ previousIndexPath ]];
            [strongSelf.collectionView insertItemsAtIndexPaths:@[ newIndexPath ]];
        }
    } completion:nil];
}

- (void)invalidatesScrollTimer {
    if (self.scrollingTimer.isValid) {
        [self.scrollingTimer invalidate];
    }
    self.scrollingTimer = nil;
}

- (void)setupScrollTimerInDirection:(LXScrollingDirection)direction {
    if (self.scrollingTimer.isValid) {
        LXScrollingDirection oldDirection = [self.scrollingTimer.userInfo[kLXScrollingDirectionKey] integerValue];
        
        if (direction == oldDirection) {
            return;
        }
    }
    
    [self invalidatesScrollTimer];
    
    self.scrollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / LX_FRAMES_PER_SECOND
                                                           target:self
                                                         selector:@selector(handleScroll:)
                                                         userInfo:@{ kLXScrollingDirectionKey : @(direction) }
                                                          repeats:YES];
}

#pragma mark - Target/Action methods

// Tight loop, allocate memory sparely, even if they are stack allocation.
- (void)handleScroll:(NSTimer *)timer {
    LXScrollingDirection direction = (LXScrollingDirection)[timer.userInfo[kLXScrollingDirectionKey] integerValue];
    if (direction == LXScrollingDirectionUnknown) {
        return;
    }
    
    CGSize frameSize = self.collectionView.bounds.size;
    CGSize contentSize = self.collectionView.contentSize;
    CGPoint contentOffset = self.collectionView.contentOffset;
    CGFloat distance = self.scrollingSpeed / LX_FRAMES_PER_SECOND;
    CGPoint translation = CGPointZero;
    
    switch(direction) {
        case LXScrollingDirectionUp: {
            distance = -distance;
            CGFloat minY = 0.0f;
            
            if ((contentOffset.y + distance) <= minY) {
                distance = -contentOffset.y;
            }
            
            translation = CGPointMake(0.0f, distance);
        } break;
        case LXScrollingDirectionDown: {
            CGFloat maxY = MAX(contentSize.height, frameSize.height) - frameSize.height;
            
            if ((contentOffset.y + distance) >= maxY) {
                distance = maxY - contentOffset.y;
            }
            
            translation = CGPointMake(0.0f, distance);
        } break;
        case LXScrollingDirectionLeft: {
            distance = -distance;
            CGFloat minX = 0.0f;
            
            if ((contentOffset.x + distance) <= minX) {
                distance = -contentOffset.x;
            }
            
            translation = CGPointMake(distance, 0.0f);
        } break;
        case LXScrollingDirectionRight: {
            CGFloat maxX = MAX(contentSize.width, frameSize.width) - frameSize.width;
            
            if ((contentOffset.x + distance) >= maxX) {
                distance = maxX - contentOffset.x;
            }
            
            translation = CGPointMake(distance, 0.0f);
        } break;
        default: {
            // Do nothing...
        } break;
    }
    
    self.currentViewCenter = LXS_CGPointAdd(self.currentViewCenter, translation);
    self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
    self.collectionView.contentOffset = LXS_CGPointAdd(contentOffset, translation);
}


- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer {
    switch(gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
            
            if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)] &&
               ![self.dataSource collectionView:self.collectionView canMoveItemAtIndexPath:currentIndexPath]) {
                return;
            }
            
            self.selectedItemIndexPath = currentIndexPath;
            
            if ([self.delegate respondsToSelector:@selector(collectionView:willBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView willBeginDraggingItemAtIndexPath:self.selectedItemIndexPath];
            }
            
            UICollectionViewCell *collectionViewCell = [self.collectionView cellForItemAtIndexPath:self.selectedItemIndexPath];
            
            self.currentView = [[UIView alloc] initWithFrame:collectionViewCell.frame];
            
            collectionViewCell.highlighted = YES;
            UIImageView *highlightedImageView = [[UIImageView alloc] initWithImage:[collectionViewCell LX_rasterizedImage]];
            highlightedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            highlightedImageView.alpha = 1.0f;
            
            collectionViewCell.highlighted = NO;
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[collectionViewCell LX_rasterizedImage]];
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            imageView.alpha = 0.0f;
            
            [self.currentView addSubview:imageView];
            [self.currentView addSubview:highlightedImageView];
            [self.collectionView addSubview:self.currentView];
            
            self.currentViewCenter = self.currentView.center;
            
            __weak typeof(self) weakSelf = self;
            [UIView
             animateWithDuration:0.3
             delay:0.0
             options:UIViewAnimationOptionBeginFromCurrentState
             animations:^{
                 __strong typeof(self) strongSelf = weakSelf;
                 if (strongSelf) {
                     strongSelf.currentView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                     highlightedImageView.alpha = 0.0f;
                     imageView.alpha = 1.0f;
                 }
             }
             completion:^(BOOL finished) {
                 __strong typeof(self) strongSelf = weakSelf;
                 if (strongSelf) {
                     [highlightedImageView removeFromSuperview];
                     
                     if ([strongSelf.delegate respondsToSelector:@selector(collectionView:didBeginDraggingItemAtIndexPath:)]) {
                         [strongSelf.delegate collectionView:strongSelf.collectionView didBeginDraggingItemAtIndexPath:strongSelf.selectedItemIndexPath];
                     }
                 }
             }];
            
            [self invalidateLayout];
        } break;
        case UIGestureRecognizerStateEnded: {
            NSIndexPath *currentIndexPath = self.selectedItemIndexPath;
            
            if (currentIndexPath) {
                if ([self.delegate respondsToSelector:@selector(collectionView:willEndDraggingItemAtIndexPath:)]) {
                    [self.delegate collectionView:self.collectionView willEndDraggingItemAtIndexPath:currentIndexPath];
                }
                
                self.selectedItemIndexPath = nil;
                self.currentViewCenter = CGPointZero;
                
                UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:currentIndexPath];
                
                __weak typeof(self) weakSelf = self;
                [UIView
                 animateWithDuration:0.3
                 delay:0.0
                 options:UIViewAnimationOptionBeginFromCurrentState
                 animations:^{
                     __strong typeof(self) strongSelf = weakSelf;
                     if (strongSelf) {
                         strongSelf.currentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                         strongSelf.currentView.center = layoutAttributes.center;
                     }
                 }
                 completion:^(BOOL finished) {
                     __strong typeof(self) strongSelf = weakSelf;
                     if (strongSelf) {
                         [strongSelf.currentView removeFromSuperview];
                         strongSelf.currentView = nil;
                         [strongSelf invalidateLayout];
                         
                         if ([strongSelf.delegate respondsToSelector:@selector(collectionView:didEndDraggingItemAtIndexPath:)]) {
                             [strongSelf.delegate collectionView:strongSelf.collectionView didEndDraggingItemAtIndexPath:currentIndexPath];
                         }
                     }
                 }];
            }
        } break;
            
        default: break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged: {
            self.panTranslationInCollectionView = [gestureRecognizer translationInView:self.collectionView];
            CGPoint viewCenter = self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
            
            [self invalidateLayoutIfNecessary];
            
            switch (self.scrollDirection) {
                case UICollectionViewScrollDirectionVertical: {
                    if (viewCenter.y < (CGRectGetMinY(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.top)) {
                        [self setupScrollTimerInDirection:LXScrollingDirectionUp];
                    } else {
                        if (viewCenter.y > (CGRectGetMaxY(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.bottom)) {
                            [self setupScrollTimerInDirection:LXScrollingDirectionDown];
                        } else {
                            [self invalidatesScrollTimer];
                        }
                    }
                } break;
                case UICollectionViewScrollDirectionHorizontal: {
                    if (viewCenter.x < (CGRectGetMinX(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.left)) {
                        [self setupScrollTimerInDirection:LXScrollingDirectionLeft];
                    } else {
                        if (viewCenter.x > (CGRectGetMaxX(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.right)) {
                            [self setupScrollTimerInDirection:LXScrollingDirectionRight];
                        } else {
                            [self invalidatesScrollTimer];
                        }
                    }
                } break;
            }
        } break;
        case UIGestureRecognizerStateEnded: {
            [self invalidatesScrollTimer];
        } break;
        default: {
            // Do nothing...
        } break;
    }
}

#pragma mark - UICollectionViewFlowLayoutDelegate methods

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *layoutAttributesForElementsInRect = [super layoutAttributesForElementsInRect:rect];
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in layoutAttributesForElementsInRect) {
        switch (layoutAttributes.representedElementCategory) {
            case UICollectionElementCategoryCell: {
                [self applyLayoutAttributes:layoutAttributes];
            } break;
            default: {
                // Do nothing...
            } break;
        }
    }
    
    return layoutAttributesForElementsInRect;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *layoutAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    switch (layoutAttributes.representedElementCategory) {
        case UICollectionElementCategoryCell: {
            [self applyLayoutAttributes:layoutAttributes];
        } break;
        default: {
            // Do nothing...
        } break;
    }
    
    return layoutAttributes;
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return (self.selectedItemIndexPath != nil);
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([self.longPressGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.panGestureRecognizer isEqual:otherGestureRecognizer];
    }
    
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.longPressGestureRecognizer isEqual:otherGestureRecognizer];
    }
    
    return NO;
}

#pragma mark - Key-Value Observing methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:kLXCollectionViewKeyPath]) {
        if (self.collectionView != nil) {
            [self setupCollectionView];
        } else {
            [self invalidatesScrollTimer];
        }
    }
}

#pragma mark - Depreciated methods

#pragma mark Starting from 0.1.0
- (void)setUpGestureRecognizersOnCollectionView {
    // Do nothing...
}

@end

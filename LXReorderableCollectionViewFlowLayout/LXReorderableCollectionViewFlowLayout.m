//
//  LXReorderableCollectionViewFlowLayout.m
//
//  Created by Stan Chang Khin Boon on 1/10/12.
//  Copyright (c) 2012 d--buzz. All rights reserved.
//

#import "LXReorderableCollectionViewFlowLayout.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

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

@interface CADisplayLink (LX_userInfo)
@property (nonatomic, copy) NSDictionary *LX_userInfo;
@end

@implementation CADisplayLink (LX_userInfo)
- (void) setLX_userInfo:(NSDictionary *) LX_userInfo {
    objc_setAssociatedObject(self, "LX_userInfo", LX_userInfo, OBJC_ASSOCIATION_COPY);
}

- (NSDictionary *) LX_userInfo {
    return objc_getAssociatedObject(self, "LX_userInfo");
}
@end

@interface UICollectionViewCell (LXReorderableCollectionViewFlowLayout)

- (UIImage *)LX_rasterizedImage;

@end

@implementation UICollectionViewCell (LXReorderableCollectionViewFlowLayout)

- (UIImage *)LX_rasterizedImage {
    self.layer.masksToBounds = NO;
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, /*self.isOpaque*/ NO, 0.0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.layer.masksToBounds = YES;
    return image;
}

@end

@interface LXReorderableCollectionViewFlowLayout ()

@property (strong, nonatomic) NSIndexPath *selectedItemIndexPath;
@property (strong, nonatomic) NSIndexPath *catchItemIndexPath;
@property (strong, nonatomic) UIImageView *currentView;
@property (assign, nonatomic) CGPoint currentViewCenter;
@property (assign, nonatomic) CGPoint panTranslationInCollectionView;
@property (strong, nonatomic) CADisplayLink *displayLink;

@property (assign, nonatomic, readonly) id<LXReorderableCollectionViewDataSource> dataSource;
@property (assign, nonatomic, readonly) id<LXReorderableCollectionViewDelegateFlowLayout> delegate;

@end

@implementation LXReorderableCollectionViewFlowLayout

- (void)setDefaults {
    _scrollingSpeed = 300.0f;
    _scrollingTriggerEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
}

- (void)setupCollectionView {
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(handleLongPressGesture:)];
    _longPressGestureRecognizer.delegate = self;
    
    // Links the default long press gesture recognizer to the custom long press gesture recognizer we are creating now
    // by enforcing failure dependency so that they doesn't clash.
    for (UIGestureRecognizer *gestureRecognizer in self.collectionView.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gestureRecognizer requireGestureRecognizerToFail:_longPressGestureRecognizer];
        }
    }
    
    [self.collectionView addGestureRecognizer:_longPressGestureRecognizer];
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(handlePanGesture:)];
    _panGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:_panGestureRecognizer];

    // Useful in multiple scenarios: one common scenario being when the Notification Center drawer is pulled down
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillResignActive:) name: UIApplicationWillResignActiveNotification object:nil];
}

- (id)init {
    self = [super init];
    if (self){
        [self setDefaults];
        [self addObserver:self forKeyPath:kLXCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self){
        [self setDefaults];
        [self addObserver:self forKeyPath:kLXCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    [self invalidatesScrollTimer];
    [self removeObserver:self forKeyPath:kLXCollectionViewKeyPath];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    if ([layoutAttributes.indexPath isEqual:self.selectedItemIndexPath]) {
        layoutAttributes.hidden = YES;
    }
}

- (id<LXReorderableCollectionViewDataSource>)dataSource {
    return (id<LXReorderableCollectionViewDataSource>)self.collectionView.dataSource;
}

- (id<LXReorderableCollectionViewDelegateFlowLayout>)delegate {
    return (id<LXReorderableCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
}

- (void)resetCatchItemIfNeeded {
    if (self.catchItemIndexPath) {
        [self.collectionView deselectItemAtIndexPath:self.catchItemIndexPath animated:YES];
        self.catchItemIndexPath = nil;
    }
}

- (void)moveCurrentItemToIndexPath:(NSIndexPath *)newIndexPath {
    [self resetCatchItemIfNeeded];
    
    NSIndexPath *previousIndexPath = self.selectedItemIndexPath;
    
    if ((newIndexPath == nil) || [newIndexPath isEqual:previousIndexPath]) {
        return;
    }
    
    if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:toIndexPath:)] &&
        ![self.dataSource collectionView:self.collectionView canMoveItemAtIndexPath:previousIndexPath toIndexPath:newIndexPath]) {
        return;
    }
    
    self.selectedItemIndexPath = newIndexPath;
    
    if ([self.dataSource respondsToSelector:@selector(collectionView:willMoveItemAtIndexPath:toIndexPath:)]) {
        [self.dataSource collectionView:self.collectionView willMoveItemAtIndexPath:previousIndexPath toIndexPath:newIndexPath];
    }
    
    __weak typeof(self)weakSelf = self;
    [self.collectionView performBatchUpdates:^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        if ([strongSelf.dataSource respondsToSelector:@selector(collectionView:moveItemAtIndexPath:toIndexPath:)]) {
            [strongSelf.dataSource collectionView:strongSelf.collectionView moveItemAtIndexPath:previousIndexPath toIndexPath:newIndexPath];
        }
        
        [strongSelf.collectionView deleteItemsAtIndexPaths:@[ previousIndexPath ]];
        [strongSelf.collectionView insertItemsAtIndexPaths:@[ newIndexPath ]];
    } completion:^(BOOL finished) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        if ([strongSelf.dataSource respondsToSelector:@selector(collectionView:didMoveItemAtIndexPath:toIndexPath:)]) {
            [strongSelf.dataSource collectionView:strongSelf.collectionView didMoveItemAtIndexPath:previousIndexPath toIndexPath:newIndexPath];
        }
    }];
}

- (void)dropCurrentItemOnIndexPath:(NSIndexPath *)newIndexPath {
    if ((newIndexPath == nil) || [newIndexPath isEqual:self.selectedItemIndexPath]) {
        [self resetCatchItemIfNeeded];
        return;
    }
    
    if ([newIndexPath isEqual:self.catchItemIndexPath]) {
        return;
    }
    
    if (![self.dataSource respondsToSelector:@selector(collectionView:canDropItemAtIndexPath:toIndexPath:)]) {
        [self moveCurrentItemToIndexPath:newIndexPath];
        return;
    }

    if ([self.dataSource collectionView:self.collectionView canDropItemAtIndexPath:self.selectedItemIndexPath toIndexPath:newIndexPath]) {
        self.catchItemIndexPath = newIndexPath;
        [self.collectionView selectItemAtIndexPath:newIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    } else {
        [self moveCurrentItemToIndexPath:newIndexPath];
    }
}

- (void)invalidateLayoutIfNecessary {
    CGPoint theCurrentViewCenter = self.currentView.center;
    NSIndexPath *newIndePath = [self.collectionView indexPathForItemAtPoint:theCurrentViewCenter];
    
    UICollectionViewLayoutAttributes *theLayoutAttributesOfSelectedItem = [self layoutAttributesForItemAtIndexPath:newIndePath];
    CGRect theFrame = theLayoutAttributesOfSelectedItem.frame;
    CGRect theLeftFrame, theRightFrame;
    //    CGRectDivide(theFrame, &theLeftFrame, &theRightFrame, CGRectGetWidth(theFrame) / 2.0f, CGRectMinXEdge);
    CGRectDivide(theFrame, &theLeftFrame, &theRightFrame, CGRectGetHeight(theFrame) / 2.0f, CGRectMinYEdge);
    
    if (CGRectContainsPoint(theLeftFrame, theCurrentViewCenter)) {
        if (self.selectedItemIndexPath.item > newIndePath.item) {
            [self moveCurrentItemToIndexPath:newIndePath];
        } else {
            [self dropCurrentItemOnIndexPath:newIndePath];
        }
    } else if (CGRectContainsPoint(theRightFrame, theCurrentViewCenter)) {
        if (self.selectedItemIndexPath.item < newIndePath.item) {
            [self moveCurrentItemToIndexPath:newIndePath];
        } else {
            [self dropCurrentItemOnIndexPath:newIndePath];
        }
    }
}

- (void)invalidatesScrollTimer {
    if (!self.displayLink.paused) {
        [self.displayLink invalidate];
    }
    self.displayLink = nil;
}

- (void)setupScrollTimerInDirection:(LXScrollingDirection)direction {
    if (!self.displayLink.paused) {
        LXScrollingDirection oldDirection = [self.displayLink.LX_userInfo[kLXScrollingDirectionKey] integerValue];

        if (direction == oldDirection) {
            return;
        }
    }
    
    [self invalidatesScrollTimer];

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleScroll:)];
    self.displayLink.LX_userInfo = @{ kLXScrollingDirectionKey : @(direction) };

    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - Target/Action methods

// Tight loop, allocate memory sparely, even if they are stack allocation.
- (void)handleScroll:(CADisplayLink *)displayLink {
    LXScrollingDirection direction = (LXScrollingDirection)[displayLink.LX_userInfo[kLXScrollingDirectionKey] integerValue];
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
            
            if (!currentIndexPath) {
                return ;
            }
            
            if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)] &&
               ![self.dataSource collectionView:self.collectionView canMoveItemAtIndexPath:currentIndexPath]) {
                return;
            }
            
            self.selectedItemIndexPath = currentIndexPath;
            
            if ([self.delegate respondsToSelector:@selector(collectionView:layout:willBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView layout:self willBeginDraggingItemAtIndexPath:self.selectedItemIndexPath];
            }
            
            UICollectionViewCell *collectionViewCell = [self.collectionView cellForItemAtIndexPath:self.selectedItemIndexPath];
            
            self.currentView = [[UIImageView alloc] initWithFrame:collectionViewCell.frame];
            
            collectionViewCell.highlighted = YES;
            self.currentView.highlightedImage = [collectionViewCell LX_rasterizedImage];
            
            collectionViewCell.highlighted = NO;
            self.currentView.image = [collectionViewCell LX_rasterizedImage];
            
            self.currentView.highlighted = YES;
            [self.collectionView addSubview:self.currentView];
            
            self.currentViewCenter = self.currentView.center;
            
            __weak typeof(self)weakSelf = self;
            [UIView animateWithDuration:0.3
                                  delay:0.0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 __strong typeof(weakSelf)strongSelf = weakSelf;
                                 if (!strongSelf) {
                                     return;
                                 }
                                 
                                 strongSelf.currentView.transform = CGAffineTransformMakeScale(1.05f, 1.05f);
                                 strongSelf.currentView.highlighted = NO;
                             }
                             completion:^(BOOL finished) {
                                 __strong typeof(weakSelf)strongSelf = weakSelf;
                                 if (!strongSelf) {
                                     return;
                                 }
                                 
                                 if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didBeginDraggingItemAtIndexPath:)]) {
                                     [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didBeginDraggingItemAtIndexPath:strongSelf.selectedItemIndexPath];
                                 }
                             }];
            
            [self invalidateLayout];
        } break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            NSIndexPath *previousIndexPath = self.selectedItemIndexPath;
            NSIndexPath *newIndexPath = self.catchItemIndexPath;
            
            if (!previousIndexPath) {
                [self resetCatchItemIfNeeded];
                return ;
            }
            
            if ([self.delegate respondsToSelector:@selector(collectionView:layout:willEndDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView layout:self willEndDraggingItemAtIndexPath:previousIndexPath];
            }
            
            self.selectedItemIndexPath = nil;
            self.currentViewCenter = CGPointZero;
            
            if (newIndexPath) {
                if ([self.dataSource respondsToSelector:@selector(collectionView:willDropItemAtIndexPath:toIndexPath:)]) {
                    [self.dataSource collectionView:self.collectionView willDropItemAtIndexPath:previousIndexPath toIndexPath:newIndexPath];
                }
                
                __weak typeof(self)weakSelf = self;
                [self.collectionView deselectItemAtIndexPath:newIndexPath animated:YES];
                [self.collectionView performBatchUpdates:^{
                    __strong typeof(weakSelf)strongSelf = weakSelf;
                    if (!strongSelf) {
                        return;
                    }
                    
                    if ([strongSelf.dataSource respondsToSelector:@selector(collectionView:dropItemAtIndexPath:toIndexPath:)]) {
                        [strongSelf.dataSource collectionView:strongSelf.collectionView dropItemAtIndexPath:previousIndexPath toIndexPath:newIndexPath];
                    }
                    
                    [strongSelf.collectionView deleteItemsAtIndexPaths:@[ previousIndexPath ]];
                    [strongSelf.collectionView insertItemsAtIndexPaths:@[ newIndexPath ]];
                } completion:^(BOOL finished) {
                    __strong typeof(weakSelf)strongSelf = weakSelf;
                    if (!strongSelf) {
                        return;
                    }

                    if ([strongSelf.dataSource respondsToSelector:@selector(collectionView:didDropItemAtIndexPath:toIndexPath:)]) {
                        [strongSelf.dataSource collectionView:strongSelf.collectionView didDropItemAtIndexPath:previousIndexPath toIndexPath:newIndexPath];
                    }
                }];
            }
            
            UICollectionViewLayoutAttributes *theLayoutAttributes;
            if (newIndexPath) {
                theLayoutAttributes = [self layoutAttributesForItemAtIndexPath:newIndexPath];
            } else {
                theLayoutAttributes = [self layoutAttributesForItemAtIndexPath:previousIndexPath];
            }
            
            __weak typeof(self)weakSelf = self;
            [UIView animateWithDuration:0.3
                                  delay:0.0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 __strong typeof(weakSelf)strongSelf = weakSelf;
                                 if (!strongSelf) {
                                     return;
                                 }
                                 
                                 if (newIndexPath) {
                                     strongSelf.currentView.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
                                     strongSelf.currentView.center = theLayoutAttributes.center;
                                 } else {
                                     strongSelf.currentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                                     strongSelf.currentView.center = theLayoutAttributes.center;
                                 }
                             }
                             completion:^(BOOL finished) {
                                 __strong typeof(weakSelf)strongSelf = weakSelf;
                                 if (!strongSelf) {
                                     return;
                                 }
                                 
                                 [strongSelf.currentView removeFromSuperview];
                                 strongSelf.currentView = nil;
                                 [strongSelf invalidateLayout];
                                 
                                 if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]) {
                                     [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didEndDraggingItemAtIndexPath:previousIndexPath];
                                 }
                             }];

            [self resetCatchItemIfNeeded];
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
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            [self invalidatesScrollTimer];
        } break;
        default: {
            // Do nothing...
        } break;
    }
}

#pragma mark - UICollectionViewLayout overridden methods

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

#pragma mark - Notifications

- (void)handleApplicationWillResignActive:(NSNotification *)notification {
    self.panGestureRecognizer.enabled = NO;
    self.panGestureRecognizer.enabled = YES;
}

#pragma mark - Depreciated methods

#pragma mark Starting from 0.1.0
- (void)setUpGestureRecognizersOnCollectionView {
    // Do nothing...
}

@end

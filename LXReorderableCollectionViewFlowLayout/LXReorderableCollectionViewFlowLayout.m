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
LXS_CGPointAdd(CGPoint thePoint1, CGPoint thePoint2) {
    return CGPointMake(thePoint1.x + thePoint2.x, thePoint1.y + thePoint2.y);
}
#endif

typedef NS_ENUM(NSInteger, LXReorderableCollectionViewFlowLayoutScrollingDirection) {
    LXReorderableCollectionViewFlowLayoutScrollingDirectionUp = 1,
    LXReorderableCollectionViewFlowLayoutScrollingDirectionDown,
    LXReorderableCollectionViewFlowLayoutScrollingDirectionLeft,
    LXReorderableCollectionViewFlowLayoutScrollingDirectionRight
};

static NSString * const kLXReorderableCollectionViewFlowLayoutScrollingDirectionKey = @"LXScrollingDirection";

@implementation LXReorderableCollectionViewFlowLayout

- (void)setUpGestureRecognizersOnCollectionView {
    UILongPressGestureRecognizer *theLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    // Links the default long press gesture recognizer to the custom long press gesture recognizer we are creating now
    // by enforcing failure dependency so that they doesn't clash.
    for (UIGestureRecognizer *theGestureRecognizer in self.collectionView.gestureRecognizers) {
        if ([theGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [theGestureRecognizer requireGestureRecognizerToFail:theLongPressGestureRecognizer];
        }
    }
    theLongPressGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:theLongPressGestureRecognizer];
    self.longPressGestureRecognizer = theLongPressGestureRecognizer;
    
    UIPanGestureRecognizer *thePanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    thePanGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:thePanGestureRecognizer];
    self.panGestureRecognizer = thePanGestureRecognizer;
    
    self.triggerScrollingEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
    self.scrollingSpeed = 300.0f;
    [self.scrollingTimer invalidate];
    self.scrollingTimer = nil;
    self.alwaysScroll = YES;
}

- (void)awakeFromNib {
    [self setUpGestureRecognizersOnCollectionView];
}

#pragma mark - Custom methods

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)theLayoutAttributes {
    if ([theLayoutAttributes.indexPath isEqual:self.selectedItemIndexPath]) {
        theLayoutAttributes.hidden = YES;
    }
}

- (void)resetCatchItemIfNeeded {
    if (self.catchItemIndexPath) {
        [self.collectionView deselectItemAtIndexPath:self.catchItemIndexPath animated:YES];
        self.catchItemIndexPath = nil;
    }
}

- (void)moveCurrentItemToIndexPath:(NSIndexPath *)theIndexPathOfSelectedItem {
    [self resetCatchItemIfNeeded];
    
    if (!theIndexPathOfSelectedItem) {
        return;
    }
    
    if (![theIndexPathOfSelectedItem isEqual:self.selectedItemIndexPath]) {
        NSIndexPath *thePreviousSelectedIndexPath = self.selectedItemIndexPath;
        self.selectedItemIndexPath = theIndexPathOfSelectedItem;
        if ([self.collectionView.delegate conformsToProtocol:@protocol(LXReorderableCollectionViewDelegateFlowLayout)]) {
            id<LXReorderableCollectionViewDelegateFlowLayout> theDelegate = (id<LXReorderableCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
            [theDelegate collectionView:self.collectionView layout:self itemAtIndexPath:thePreviousSelectedIndexPath willMoveToIndexPath:theIndexPathOfSelectedItem];
            
            [self.collectionView performBatchUpdates:^{
                //[self.collectionView moveItemAtIndexPath:thePreviousSelectedIndexPath toIndexPath:theIndexPathOfSelectedItem];
                [self.collectionView deleteItemsAtIndexPaths:@[ thePreviousSelectedIndexPath ]];
                [self.collectionView insertItemsAtIndexPaths:@[ theIndexPathOfSelectedItem ]];
            } completion:^(BOOL finished) {
            }];
        }
    }
}

- (void)dropCurrentItemOnIndexPath:(NSIndexPath *)theIndexPathOfSelectedItem {
    if (!theIndexPathOfSelectedItem) {
        [self resetCatchItemIfNeeded];
        return;
    }
    
    if (![theIndexPathOfSelectedItem isEqual:self.selectedItemIndexPath]) {
        if (![theIndexPathOfSelectedItem isEqual:self.catchItemIndexPath]) {
            if ([self.collectionView.delegate conformsToProtocol:@protocol(LXReorderableCollectionViewDelegateFlowLayout)]) {
                id<LXReorderableCollectionViewDelegateFlowLayout> theDelegate = (id<LXReorderableCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
                // TOOD: (stan@buuuk.com) Method should be optional.
                if ([theDelegate collectionView:self.collectionView layout:self shouldDropIndexPath:self.selectedItemIndexPath onIndexPath:theIndexPathOfSelectedItem]) {
                    self.catchItemIndexPath = theIndexPathOfSelectedItem;
                    [self.collectionView selectItemAtIndexPath:theIndexPathOfSelectedItem animated:YES scrollPosition:UICollectionViewScrollPositionNone];
                } else {
                    [self moveCurrentItemToIndexPath:theIndexPathOfSelectedItem];
                }
            }
        }
    } else {
        [self resetCatchItemIfNeeded];
    }
}

- (void)invalidateLayoutIfNecessary {
    CGPoint theCurrentViewCenter = self.currentView.center;
    NSIndexPath *theIndexPathOfSelectedItem = [self.collectionView indexPathForItemAtPoint:theCurrentViewCenter];
    
    UICollectionViewLayoutAttributes *theLayoutAttributesOfSelectedItem = [self layoutAttributesForItemAtIndexPath:theIndexPathOfSelectedItem];
    CGRect theFrame = theLayoutAttributesOfSelectedItem.frame;
    CGRect theLeftFrame;
    CGRect theRightFrame;
    CGRectDivide(theFrame, &theLeftFrame, &theRightFrame, CGRectGetWidth(theFrame) / 3.0f, CGRectMinXEdge);
    
    if (CGRectContainsPoint(theLeftFrame, theCurrentViewCenter)) {
        if (self.selectedItemIndexPath.item > theIndexPathOfSelectedItem.item) {
            [self moveCurrentItemToIndexPath:theIndexPathOfSelectedItem];
        } else {
            [self dropCurrentItemOnIndexPath:theIndexPathOfSelectedItem];
        }
    } else if (CGRectContainsPoint(theRightFrame, theCurrentViewCenter)) {
        if (self.selectedItemIndexPath.item < theIndexPathOfSelectedItem.item) {
            [self moveCurrentItemToIndexPath:theIndexPathOfSelectedItem];
        } else {
            [self dropCurrentItemOnIndexPath:theIndexPathOfSelectedItem];
        }
    }
}

#pragma mark - Target/Action methods

- (void)handleScroll:(NSTimer *)theTimer {
    LXReorderableCollectionViewFlowLayoutScrollingDirection theScrollingDirection = (LXReorderableCollectionViewFlowLayoutScrollingDirection)[theTimer.userInfo[kLXReorderableCollectionViewFlowLayoutScrollingDirectionKey] integerValue];
    switch (theScrollingDirection) {
        case LXReorderableCollectionViewFlowLayoutScrollingDirectionUp: {
            CGFloat theDistance = -(self.scrollingSpeed / LX_FRAMES_PER_SECOND);
            CGPoint theContentOffset = self.collectionView.contentOffset;
            CGFloat theMinY = 0.0f;
            if ((theContentOffset.y + theDistance) <= theMinY) {
                theDistance = -theContentOffset.y;
            }
            self.collectionView.contentOffset = LXS_CGPointAdd(theContentOffset, CGPointMake(0.0f, theDistance));
            self.currentViewCenter = LXS_CGPointAdd(self.currentViewCenter, CGPointMake(0.0f, theDistance));
            self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
        } break;
        case LXReorderableCollectionViewFlowLayoutScrollingDirectionDown: {
            CGFloat theDistance = (self.scrollingSpeed / LX_FRAMES_PER_SECOND);
            CGPoint theContentOffset = self.collectionView.contentOffset;
            CGFloat theMaxY = MAX(self.collectionView.contentSize.height, CGRectGetHeight(self.collectionView.bounds)) - CGRectGetHeight(self.collectionView.bounds);
            if ((theContentOffset.y + theDistance) >= theMaxY) {
                theDistance = theMaxY - theContentOffset.y;
            }
            self.collectionView.contentOffset = LXS_CGPointAdd(theContentOffset, CGPointMake(0.0f, theDistance));
            self.currentViewCenter = LXS_CGPointAdd(self.currentViewCenter, CGPointMake(0.0f, theDistance));
            self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
        } break;
            
        case LXReorderableCollectionViewFlowLayoutScrollingDirectionLeft: {
            CGFloat theDistance = -(self.scrollingSpeed / LX_FRAMES_PER_SECOND);
            CGPoint theContentOffset = self.collectionView.contentOffset;
            CGFloat theMinX = 0.0f;
            if ((theContentOffset.x + theDistance) <= theMinX) {
                theDistance = -theContentOffset.x;
            }
            self.collectionView.contentOffset = LXS_CGPointAdd(theContentOffset, CGPointMake(theDistance, 0.0f));
            self.currentViewCenter = LXS_CGPointAdd(self.currentViewCenter, CGPointMake(theDistance, 0.0f));
            self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
        } break;
        case LXReorderableCollectionViewFlowLayoutScrollingDirectionRight: {
            CGFloat theDistance = (self.scrollingSpeed / LX_FRAMES_PER_SECOND);
            CGPoint theContentOffset = self.collectionView.contentOffset;
            CGFloat theMaxX = MAX(self.collectionView.contentSize.width, CGRectGetWidth(self.collectionView.bounds)) - CGRectGetWidth(self.collectionView.bounds);
            if ((theContentOffset.x + theDistance) >= theMaxX) {
                theDistance = theMaxX - theContentOffset.x;
            }
            self.collectionView.contentOffset = LXS_CGPointAdd(theContentOffset, CGPointMake(theDistance, 0.0f));
            self.currentViewCenter = LXS_CGPointAdd(self.currentViewCenter, CGPointMake(theDistance, 0.0f));
            self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
        } break;
            
        default: {
        } break;
    }
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)theLongPressGestureRecognizer {
    switch (theLongPressGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            CGPoint theLocationInCollectionView = [theLongPressGestureRecognizer locationInView:self.collectionView];
            NSIndexPath *theIndexPathOfSelectedItem = [self.collectionView indexPathForItemAtPoint:theLocationInCollectionView];
            
            if ([self.collectionView.delegate conformsToProtocol:@protocol(LXReorderableCollectionViewDelegateFlowLayout)]) {
                id<LXReorderableCollectionViewDelegateFlowLayout> theDelegate = (id<LXReorderableCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
                if ([theDelegate respondsToSelector:@selector(collectionView:layout:willBeginReorderingAtIndexPath:)]) {
                    [theDelegate collectionView:self.collectionView layout:self willBeginReorderingAtIndexPath:theIndexPathOfSelectedItem];
                }
            }
            
            UICollectionViewCell *theCollectionViewCell = [self.collectionView cellForItemAtIndexPath:theIndexPathOfSelectedItem];
            
            theCollectionViewCell.highlighted = YES;
            UIGraphicsBeginImageContextWithOptions(theCollectionViewCell.bounds.size, theCollectionViewCell.opaque, 0.0f);
            [theCollectionViewCell.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *theHighlightedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            theCollectionViewCell.highlighted = NO;
            UIGraphicsBeginImageContextWithOptions(theCollectionViewCell.bounds.size, theCollectionViewCell.opaque, 0.0f);
            [theCollectionViewCell.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            UIImageView *theImageView = [[UIImageView alloc] initWithImage:theImage];
            theImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight; // Not using constraints, lets auto resizing mask be translated automatically...
            
            UIImageView *theHighlightedImageView = [[UIImageView alloc] initWithImage:theHighlightedImage];
            theHighlightedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight; // Not using constraints, lets auto resizing mask be translated automatically...
            
            UIView *theView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(theCollectionViewCell.frame), CGRectGetMinY(theCollectionViewCell.frame), CGRectGetWidth(theImageView.frame), CGRectGetHeight(theImageView.frame))];
            
            [theView addSubview:theImageView];
            [theView addSubview:theHighlightedImageView];
            
            [self.collectionView addSubview:theView];
            
            self.selectedItemIndexPath = theIndexPathOfSelectedItem;
            self.currentView = theView;
            self.currentViewCenter = theView.center;
            
            theImageView.alpha = 0.0f;
            theHighlightedImageView.alpha = 1.0f;
            
            [UIView
             animateWithDuration:0.3
             animations:^{
                 theView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                 theImageView.alpha = 1.0f;
                 theHighlightedImageView.alpha = 0.0f;
             }
             completion:^(BOOL finished) {
                 [theHighlightedImageView removeFromSuperview];
                 
                 if ([self.collectionView.delegate conformsToProtocol:@protocol(LXReorderableCollectionViewDelegateFlowLayout)]) {
                     id<LXReorderableCollectionViewDelegateFlowLayout> theDelegate = (id<LXReorderableCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
                     if ([theDelegate respondsToSelector:@selector(collectionView:layout:didBeginReorderingAtIndexPath:)]) {
                         [theDelegate collectionView:self.collectionView layout:self didBeginReorderingAtIndexPath:theIndexPathOfSelectedItem];
                     }
                 }
             }];
            
            [self invalidateLayout];
        } break;
        case UIGestureRecognizerStateEnded: {
            NSIndexPath *theIndexPathOfSelectedItem = self.selectedItemIndexPath;
            NSIndexPath *theIndexPathOfCatchItem = self.catchItemIndexPath;
            
            if ([self.collectionView.delegate conformsToProtocol:@protocol(LXReorderableCollectionViewDelegateFlowLayout)]) {
                id<LXReorderableCollectionViewDelegateFlowLayout> theDelegate = (id<LXReorderableCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
                if ([theDelegate respondsToSelector:@selector(collectionView:layout:willEndReorderingAtIndexPath:)]) {
                    [theDelegate collectionView:self.collectionView layout:self willEndReorderingAtIndexPath:theIndexPathOfSelectedItem];
                }
            }
            
            self.selectedItemIndexPath = nil;
            self.currentViewCenter = CGPointZero;
            
            if ([self.collectionView.delegate conformsToProtocol:@protocol(LXReorderableCollectionViewDelegateFlowLayout)]) {
                id<LXReorderableCollectionViewDelegateFlowLayout> theDelegate = (id<LXReorderableCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
                if (theIndexPathOfCatchItem) {
                    if ([theDelegate respondsToSelector:@selector(collectionView:layout:willDropIndexPath:onIndexPath:)]) {
                        [theDelegate collectionView:self.collectionView layout:self willDropIndexPath:theIndexPathOfSelectedItem onIndexPath:theIndexPathOfCatchItem];
                    }
                    [self.collectionView deselectItemAtIndexPath:theIndexPathOfCatchItem animated:YES];
                    [self.collectionView
                     performBatchUpdates:^{
                         [self.collectionView deleteItemsAtIndexPaths:@[ theIndexPathOfSelectedItem ]];
                     }
                     completion:^(BOOL theFinished) {
                     }];
                }
            }
            
            UICollectionViewLayoutAttributes *theLayoutAttributes;
            if (theIndexPathOfCatchItem) {
                theLayoutAttributes = [self layoutAttributesForItemAtIndexPath:theIndexPathOfCatchItem];
            } else {
                theLayoutAttributes = [self layoutAttributesForItemAtIndexPath:theIndexPathOfSelectedItem];
            }
            
            __weak LXReorderableCollectionViewFlowLayout *theWeakSelf = self;
            [UIView
             animateWithDuration:0.3f
             animations:^{
                 __strong LXReorderableCollectionViewFlowLayout *theStrongSelf = theWeakSelf;
                 
                 if (theIndexPathOfCatchItem) {
                     theStrongSelf.currentView.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
                     theStrongSelf.currentView.center = theLayoutAttributes.center;
                 } else {
                     theStrongSelf.currentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                     theStrongSelf.currentView.center = theLayoutAttributes.center;
                 }
             }
             completion:^(BOOL finished) {
                 __strong LXReorderableCollectionViewFlowLayout *theStrongSelf = theWeakSelf;
                 
                 [theStrongSelf.currentView removeFromSuperview];
                 [theStrongSelf invalidateLayout];
                 
                 if ([self.collectionView.delegate conformsToProtocol:@protocol(LXReorderableCollectionViewDelegateFlowLayout)]) {
                     id<LXReorderableCollectionViewDelegateFlowLayout> theDelegate = (id<LXReorderableCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
                     if ([theDelegate respondsToSelector:@selector(collectionView:layout:didEndReorderingAtIndexPath:)]) {
                         [theDelegate collectionView:self.collectionView layout:self didEndReorderingAtIndexPath:theIndexPathOfSelectedItem];
                     }
                 }
             }];
            
            [self resetCatchItemIfNeeded];
        } break;
        default: {
        } break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)thePanGestureRecognizer {
    switch (thePanGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged: {
            CGPoint theTranslationInCollectionView = [thePanGestureRecognizer translationInView:self.collectionView];
            self.panTranslationInCollectionView = theTranslationInCollectionView;
            CGPoint theLocationInCollectionView = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
            self.currentView.center = theLocationInCollectionView;
            
            if (self.invalidateLayoutTimer) {
                [self.invalidateLayoutTimer invalidate];
                self.invalidateLayoutTimer = nil;
            }
            self.invalidateLayoutTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(invalidateLayoutIfNecessary) userInfo:nil repeats:NO];
            
            switch (self.scrollDirection) {
                case UICollectionViewScrollDirectionVertical: {
                    if (theLocationInCollectionView.y < (CGRectGetMinY(self.collectionView.bounds) + self.triggerScrollingEdgeInsets.top)) {
                        BOOL isScrollingTimerSetUpNeeded = YES;
                        if (self.scrollingTimer) {
                            if (self.scrollingTimer.isValid) {
                                isScrollingTimerSetUpNeeded = ([self.scrollingTimer.userInfo[kLXReorderableCollectionViewFlowLayoutScrollingDirectionKey] integerValue] != LXReorderableCollectionViewFlowLayoutScrollingDirectionUp);
                            }
                        }
                        if (isScrollingTimerSetUpNeeded) {
                            if (self.scrollingTimer) {
                                [self.scrollingTimer invalidate];
                                self.scrollingTimer = nil;
                            }
                            self.scrollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / LX_FRAMES_PER_SECOND
                                                                                   target:self
                                                                                 selector:@selector(handleScroll:)
                                                                                 userInfo:@{ kLXReorderableCollectionViewFlowLayoutScrollingDirectionKey : @( LXReorderableCollectionViewFlowLayoutScrollingDirectionUp ) }
                                                                                  repeats:YES];
                        }
                    } else if (theLocationInCollectionView.y > (CGRectGetMaxY(self.collectionView.bounds) - self.triggerScrollingEdgeInsets.bottom)) {
                        BOOL isScrollingTimerSetUpNeeded = YES;
                        if (self.scrollingTimer) {
                            if (self.scrollingTimer.isValid) {
                                isScrollingTimerSetUpNeeded = ([self.scrollingTimer.userInfo[kLXReorderableCollectionViewFlowLayoutScrollingDirectionKey] integerValue] != LXReorderableCollectionViewFlowLayoutScrollingDirectionDown);
                            }
                        }
                        if (isScrollingTimerSetUpNeeded) {
                            if (self.scrollingTimer) {
                                [self.scrollingTimer invalidate];
                                self.scrollingTimer = nil;
                            }
                            self.scrollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / LX_FRAMES_PER_SECOND
                                                                                   target:self
                                                                                 selector:@selector(handleScroll:)
                                                                                 userInfo:@{ kLXReorderableCollectionViewFlowLayoutScrollingDirectionKey : @( LXReorderableCollectionViewFlowLayoutScrollingDirectionDown ) }
                                                                                  repeats:YES];
                        }
                    } else {
                        if (self.scrollingTimer) {
                            [self.scrollingTimer invalidate];
                            self.scrollingTimer = nil;
                        }
                    }
                } break;
                case UICollectionViewScrollDirectionHorizontal: {
                    if (theLocationInCollectionView.x < (CGRectGetMinX(self.collectionView.bounds) + self.triggerScrollingEdgeInsets.left)) {
                        BOOL isScrollingTimerSetUpNeeded = YES;
                        if (self.scrollingTimer) {
                            if (self.scrollingTimer.isValid) {
                                isScrollingTimerSetUpNeeded = ([self.scrollingTimer.userInfo[kLXReorderableCollectionViewFlowLayoutScrollingDirectionKey] integerValue] != LXReorderableCollectionViewFlowLayoutScrollingDirectionLeft);
                            }
                        }
                        if (isScrollingTimerSetUpNeeded) {
                            if (self.scrollingTimer) {
                                [self.scrollingTimer invalidate];
                                self.scrollingTimer = nil;
                            }
                            self.scrollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / LX_FRAMES_PER_SECOND
                                                                                   target:self
                                                                                 selector:@selector(handleScroll:)
                                                                                 userInfo:@{ kLXReorderableCollectionViewFlowLayoutScrollingDirectionKey : @( LXReorderableCollectionViewFlowLayoutScrollingDirectionLeft ) }
                                                                                  repeats:YES];
                        }
                    } else if (theLocationInCollectionView.x > (CGRectGetMaxX(self.collectionView.bounds) - self.triggerScrollingEdgeInsets.right)) {
                        BOOL isScrollingTimerSetUpNeeded = YES;
                        if (self.scrollingTimer) {
                            if (self.scrollingTimer.isValid) {
                                isScrollingTimerSetUpNeeded = ([self.scrollingTimer.userInfo[kLXReorderableCollectionViewFlowLayoutScrollingDirectionKey] integerValue] != LXReorderableCollectionViewFlowLayoutScrollingDirectionRight);
                            }
                        }
                        if (isScrollingTimerSetUpNeeded) {
                            if (self.scrollingTimer) {
                                [self.scrollingTimer invalidate];
                                self.scrollingTimer = nil;
                            }
                            self.scrollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / LX_FRAMES_PER_SECOND
                                                                                   target:self
                                                                                 selector:@selector(handleScroll:)
                                                                                 userInfo:@{ kLXReorderableCollectionViewFlowLayoutScrollingDirectionKey : @( LXReorderableCollectionViewFlowLayoutScrollingDirectionRight ) }
                                                                                  repeats:YES];
                        }
                    } else {
                        if (self.scrollingTimer) {
                            [self.scrollingTimer invalidate];
                            self.scrollingTimer = nil;
                        }
                    }
                } break;
            }
        } break;
        case UIGestureRecognizerStateEnded: {
            if (self.invalidateLayoutTimer) {
                [self.invalidateLayoutTimer invalidate];
                self.invalidateLayoutTimer = nil;
            }
            if (self.scrollingTimer) {
                [self.scrollingTimer invalidate];
                self.scrollingTimer = nil;
            }
        } break;
        default: {
        } break;
    }
}

#pragma mark - UICollectionViewFlowLayoutDelegate methods

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)theRect {
    NSArray *theLayoutAttributesForElementsInRect = [super layoutAttributesForElementsInRect:theRect];
    
    for (UICollectionViewLayoutAttributes *theLayoutAttributes in theLayoutAttributesForElementsInRect) {
        switch (theLayoutAttributes.representedElementCategory) {
            case UICollectionElementCategoryCell: {
                [self applyLayoutAttributes:theLayoutAttributes];
            } break;
            default: {
            } break;
        }
    }
    
    return theLayoutAttributesForElementsInRect;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)theIndexPath {
    UICollectionViewLayoutAttributes *theLayoutAttributes = [super layoutAttributesForItemAtIndexPath:theIndexPath];
    
    switch (theLayoutAttributes.representedElementCategory) {
        case UICollectionElementCategoryCell: {
            [self applyLayoutAttributes:theLayoutAttributes];
        } break;
        default: {
        } break;
    }
    
    return theLayoutAttributes;
    
}

- (CGSize)collectionViewContentSize {
    CGSize theCollectionViewContentSize = [super collectionViewContentSize];
    if (self.alwaysScroll) {
        switch (self.scrollDirection) {
            case UICollectionViewScrollDirectionVertical: {
                if (theCollectionViewContentSize.height <= CGRectGetHeight(self.collectionView.bounds)) {
                    theCollectionViewContentSize.height = CGRectGetHeight(self.collectionView.bounds) + 1.0f;
                }
            } break;
            case UICollectionViewScrollDirectionHorizontal: {
                if (theCollectionViewContentSize.width <= CGRectGetWidth(self.collectionView.bounds)) {
                    theCollectionViewContentSize.width = CGRectGetWidth(self.collectionView.bounds) + 1.0f;
                }
            } break;
        }
    }
    return theCollectionViewContentSize;
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)theGestureRecognizer {
    if ([self.panGestureRecognizer isEqual:theGestureRecognizer]) {
        return (self.selectedItemIndexPath != nil);
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)theGestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)theOtherGestureRecognizer {
    if ([self.longPressGestureRecognizer isEqual:theGestureRecognizer]) {
        if ([self.panGestureRecognizer isEqual:theOtherGestureRecognizer]) {
            return YES;
        } else {
            return NO;
        }
    } else if ([self.panGestureRecognizer isEqual:theGestureRecognizer]) {
        if ([self.longPressGestureRecognizer isEqual:theOtherGestureRecognizer]) {
            return YES;
        } else {
            return NO;
        }
    }
    return NO;
}

@end

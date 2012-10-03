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

- (void)invalidateLayoutIfNecessary {
    NSIndexPath *theIndexPathOfSelectedItem = [self.collectionView indexPathForItemAtPoint:self.currentView.center];
    if ((![theIndexPathOfSelectedItem isEqual:self.selectedItemIndexPath]) &&(theIndexPathOfSelectedItem)) {
        NSIndexPath *thePreviousSelectedIndexPath = self.selectedItemIndexPath;
        self.selectedItemIndexPath = theIndexPathOfSelectedItem;
        if ([self.collectionView.delegate conformsToProtocol:@protocol(LXReorderableCollectionViewDelegateFlowLayout)]) {
            id<LXReorderableCollectionViewDelegateFlowLayout> theDelegate = (id<LXReorderableCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
            [theDelegate itemAtIndexPath:thePreviousSelectedIndexPath willMoveToIndexPath:theIndexPathOfSelectedItem];
        }
        [self.collectionView performBatchUpdates:^{
            //[self.collectionView moveItemAtIndexPath:thePreviousSelectedIndexPath toIndexPath:theIndexPathOfSelectedItem];
            [self.collectionView deleteItemsAtIndexPaths:@[ thePreviousSelectedIndexPath ]];
            [self.collectionView insertItemsAtIndexPaths:@[ theIndexPathOfSelectedItem ]];
        } completion:^(BOOL finished) {
        }];
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
            CGFloat theMaxY = self.collectionView.contentSize.height - CGRectGetHeight(self.collectionView.bounds);
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
            CGFloat theMinY = 0.0f;
            if ((theContentOffset.y + theDistance) <= theMinY) {
                theDistance = -theContentOffset.y;
            }
            self.collectionView.contentOffset = LXS_CGPointAdd(theContentOffset, CGPointMake(theDistance, 0.0f));
            self.currentViewCenter = LXS_CGPointAdd(self.currentViewCenter, CGPointMake(theDistance, 0.0f));
            self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
        } break;
        case LXReorderableCollectionViewFlowLayoutScrollingDirectionRight: {
            CGFloat theDistance = (self.scrollingSpeed / LX_FRAMES_PER_SECOND);
            CGPoint theContentOffset = self.collectionView.contentOffset;
            CGFloat theMinY = 0.0f;
            if ((theContentOffset.y + theDistance) <= theMinY) {
                theDistance = -theContentOffset.y;
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
             }];
            
            [self invalidateLayout];
        } break;
        case UIGestureRecognizerStateEnded: {
            NSIndexPath *theIndexPathOfSelectedItem = self.selectedItemIndexPath;
            self.selectedItemIndexPath = nil;
            self.currentViewCenter = CGPointZero;
            
            UICollectionViewLayoutAttributes *theLayoutAttributes = [self layoutAttributesForItemAtIndexPath:theIndexPathOfSelectedItem];
            
            __weak LXReorderableCollectionViewFlowLayout *theWeakSelf = self;
            [UIView
             animateWithDuration:0.3f
             animations:^{
                 __strong LXReorderableCollectionViewFlowLayout *theStrongSelf = theWeakSelf;
                 
                 theStrongSelf.currentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                 theStrongSelf.currentView.center = theLayoutAttributes.center;
             }
             completion:^(BOOL finished) {
                 __strong LXReorderableCollectionViewFlowLayout *theStrongSelf = theWeakSelf;
                 
                 [theStrongSelf.currentView removeFromSuperview];
                 [theStrongSelf invalidateLayout];
             }];
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
            
            [self invalidateLayoutIfNecessary];
            
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
        [self applyLayoutAttributes:theLayoutAttributes];
    }
    
    return theLayoutAttributesForElementsInRect;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)theIndexPath {
    UICollectionViewLayoutAttributes *theLayoutAttributes = [super layoutAttributesForItemAtIndexPath:theIndexPath];
    
    [self applyLayoutAttributes:theLayoutAttributes];
    
    return theLayoutAttributes;
    
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

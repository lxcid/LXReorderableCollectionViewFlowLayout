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


@interface UICollectionViewCell (LXReorderableCollectionViewFlowLayout)

- (UIImage *)lxRasterizedImage;

@end

@implementation UICollectionViewCell (LXReorderableCollectionViewFlowLayout)

- (UIImage *)lxRasterizedImage
{
    UIImage *image;
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, .0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

@interface LXReorderableCollectionViewFlowLayout ()
{
    NSIndexPath *selectedItemIndexPath;
    UIView *currentView;
    CGPoint currentViewCenter;
    CGPoint panTranslationInCollectionView;
    NSTimer *scrollingTimer;
    UICollectionView *collectionView;
}
@end

@implementation LXReorderableCollectionViewFlowLayout
@synthesize longPressGestureRecognizer;
@synthesize panGestureRecognizer;
@synthesize scrollingSpeed;
@synthesize scrollingTriggerEdgeInsets;

- (void)setDefaults
{
    scrollingSpeed = 300.0f;
    scrollingTriggerEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
}

- (void)setupCollectionView
{
    collectionView = self.collectionView;
    longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                               action:@selector(handleLongPressGesture:)];
    
    [longPressGestureRecognizer setDelegate:self];
    [collectionView addGestureRecognizer:longPressGestureRecognizer];
    
    // Links the default long press gesture recognizer to the custom long press gesture recognizer we are creating now
    // by enforcing failure dependency so that they doesn't clash.
    for(UIGestureRecognizer *gestureRecognizer in collectionView.gestureRecognizers) {
        if([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gestureRecognizer requireGestureRecognizerToFail:longPressGestureRecognizer];
        }
    }
    
    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                   action:@selector(handlePanGesture:)];
    [panGestureRecognizer setDelegate:self];
    [collectionView addGestureRecognizer:panGestureRecognizer];
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setDefaults];
        [self addObserver:self forKeyPath:@"collectionView" options:0 context:nil];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setDefaults];
        [self addObserver:self forKeyPath:@"collectionView" options:0 context:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"collectionView"]) {
        if(object != nil) {
            [self setupCollectionView];
        }
        else {
            [self invalidateScrollTimer];
        }
    }
}

- (void)dealloc
{
    [self invalidateScrollTimer];
    [self removeObserver:self forKeyPath:@"collectionView"];
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    if ([layoutAttributes.indexPath isEqual:selectedItemIndexPath]) {
        layoutAttributes.hidden = YES;
    }
}

- (id<LXReorderableCollectionViewDatasource>)dataSource
{
    return (id<LXReorderableCollectionViewDatasource>)collectionView.dataSource;
}

- (id<LXReorderableCollectionViewDelegate>)delegate
{
    return (id<LXReorderableCollectionViewDelegate>)collectionView.delegate;
}

- (void)invalidateLayoutIfNecessary
{
    NSIndexPath *newIndexPath = [collectionView indexPathForItemAtPoint:currentView.center];
    NSIndexPath *previousIndexPath = selectedItemIndexPath;
    
    if(! newIndexPath || [newIndexPath isEqual:previousIndexPath])
        return;
    
    if([[self dataSource] respondsToSelector:@selector(collectionView:itemAtIndexPath:canMoveToIndexPath:)] &&
       ! [[self dataSource] collectionView:collectionView
                    itemAtIndexPath:previousIndexPath
                 canMoveToIndexPath:newIndexPath]) {
           return;
       }
    
    selectedItemIndexPath = newIndexPath;
    
    [[self dataSource] collectionView:collectionView
               itemAtIndexPath:previousIndexPath
           willMoveToIndexPath:newIndexPath];
    
    [collectionView performBatchUpdates:^{
        [collectionView deleteItemsAtIndexPaths:@[previousIndexPath]];
        [collectionView insertItemsAtIndexPaths:@[newIndexPath]];
    } completion:nil];
}

- (void)invalidateScrollTimer
{
    if(scrollingTimer.isValid) {
        [scrollingTimer invalidate];
    }
    scrollingTimer = nil;
}

- (void)setupScrollTimerInDirection:(LXScrollingDirection)direction
{
    LXScrollingDirection oldDirection;
    
    if(scrollingTimer.isValid) {
        oldDirection = [scrollingTimer.userInfo[kLXScrollingDirectionKey] integerValue];
        
        if(direction == oldDirection) {
            return;
        }
    }
    
    [self invalidateScrollTimer];
    
    scrollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / LX_FRAMES_PER_SECOND
                                                      target:self
                                                    selector:@selector(handleScroll:)
                                                    userInfo:@{kLXScrollingDirectionKey:@(direction)}
                                                     repeats:YES];
}

#pragma mark - Target/Action methods

- (void)handleScroll:(NSTimer *)timer
{
    LXScrollingDirection direction = (LXScrollingDirection)[timer.userInfo[kLXScrollingDirectionKey] integerValue];
    CGSize frameSize = collectionView.bounds.size;
    CGSize contentSize = collectionView.contentSize;
    CGPoint contentOffset = collectionView.contentOffset;
    CGFloat distance = scrollingSpeed / LX_FRAMES_PER_SECOND;
    CGFloat minX, minY, maxX, maxY;
    CGPoint translation;
    
    switch(direction) {
        case LXScrollingDirectionUp:
            distance = -distance;
            minY = 0.0f;
            
            if((contentOffset.y + distance) <= minY)
                distance = -contentOffset.y;
            
            translation = CGPointMake(0.0f, distance);
            break;
        case LXScrollingDirectionDown:
            maxY = MAX(contentSize.height, frameSize.height) - frameSize.height;
            
            if((contentOffset.y + distance) >= maxY)
                distance = maxY - contentOffset.y;
            
            translation = CGPointMake(0.0f, distance);
            break;
        case LXScrollingDirectionLeft:
            distance = -distance;
            minX = 0.0f;
            
            if((contentOffset.x + distance) <= minX)
                distance = -contentOffset.x;
            
            translation = CGPointMake(distance, 0.0f);
            break;
        case LXScrollingDirectionRight:
            maxX = MAX(contentSize.width, frameSize.width) - frameSize.width;
            
            if((contentOffset.x + distance) >= maxX)
                distance = maxX - contentOffset.x;
            
            translation = CGPointMake(distance, 0.0f);
            break;
    }
    
    currentViewCenter = LXS_CGPointAdd(currentViewCenter, translation);
    currentView.center = LXS_CGPointAdd(currentViewCenter, panTranslationInCollectionView);
    collectionView.contentOffset = LXS_CGPointAdd(contentOffset, translation);
}


- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer
{
    UICollectionViewCell *collectionViewCell;
    UIImageView *imageView;
    UIImageView *highlightedImageView;
    NSIndexPath *currentIndexPath;
    UICollectionViewLayoutAttributes *layoutAttributes;
    
    switch(gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            currentIndexPath = [collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:collectionView]];
            
            if([[self dataSource] respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)] &&
               ![[self dataSource] collectionView:collectionView canMoveItemAtIndexPath:currentIndexPath]) {
                return;
            }
            
            selectedItemIndexPath = currentIndexPath;
            
            if([[self delegate] respondsToSelector:@selector(collectionView:willBeginDraggingItemAtIndexPath:)]) {
                [[self delegate] collectionView:collectionView willBeginDraggingItemAtIndexPath:selectedItemIndexPath];
            }
            
            collectionViewCell = [collectionView cellForItemAtIndexPath:selectedItemIndexPath];
            
            currentView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(collectionViewCell.frame),
                                                                   CGRectGetMinY(collectionViewCell.frame),
                                                                   CGRectGetWidth(collectionViewCell.frame),
                                                                   CGRectGetHeight(collectionViewCell.frame))];
            
            collectionViewCell.highlighted = YES;
            highlightedImageView = [[UIImageView alloc] initWithImage:[collectionViewCell lxRasterizedImage]];
            highlightedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            highlightedImageView.hidden = NO;
            
            collectionViewCell.highlighted = NO;
            imageView = [[UIImageView alloc] initWithImage:[collectionViewCell lxRasterizedImage]];
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            imageView.hidden = YES;
            
            [currentView addSubview:imageView];
            [currentView addSubview:highlightedImageView];
            [collectionView addSubview:currentView];
            
            currentViewCenter = currentView.center;
            
            [UIView animateWithDuration:0.3
                             animations:^{
                                 currentView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                                 highlightedImageView.hidden = YES;
                                 imageView.hidden = NO;
                             }
                             completion:^(BOOL finished) {
                                 [highlightedImageView removeFromSuperview];
                                 
                                 if ([[self delegate] respondsToSelector:@selector(collectionView:didBeginDraggingItemAtIndexPath:)]) {
                                     [[self delegate] collectionView:collectionView didBeginDraggingItemAtIndexPath:selectedItemIndexPath];
                                 }
                             }];
            
            [self invalidateLayout];
        } break;
            
        case UIGestureRecognizerStateEnded: {
            currentIndexPath = selectedItemIndexPath;
            
            if (currentIndexPath) {
                if ([[self delegate] respondsToSelector:@selector(collectionView:willEndDraggingItemAtIndexPath:)]) {
                    [[self delegate] collectionView:self.collectionView willEndDraggingItemAtIndexPath:currentIndexPath];
                }
                
                selectedItemIndexPath = nil;
                currentViewCenter = CGPointZero;
                
                layoutAttributes = [self layoutAttributesForItemAtIndexPath:currentIndexPath];
                
                [UIView animateWithDuration:0.3
                                 animations:^{
                                     currentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                                     currentView.center = layoutAttributes.center;
                                 }
                                 completion:^(BOOL finished) {
                                     [currentView removeFromSuperview];
                                     currentView = nil;
                                     [self invalidateLayout];
                                     
                                     if ([[self delegate] respondsToSelector:@selector(collectionView:didEndDraggingItemAtIndexPath:)]) {
                                         [[self delegate] collectionView:self.collectionView didEndDraggingItemAtIndexPath:currentIndexPath];
                                     }
                                 }];
            }
        } break;
            
        default: break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint viewCenter;
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
            panTranslationInCollectionView = [gestureRecognizer translationInView:collectionView];
            currentView.center = viewCenter = LXS_CGPointAdd(currentViewCenter, panTranslationInCollectionView);
            
            [self invalidateLayoutIfNecessary];
            
            switch (self.scrollDirection)
            {
                case UICollectionViewScrollDirectionVertical:
                    if (viewCenter.y < (CGRectGetMinY(collectionView.bounds) + scrollingTriggerEdgeInsets.top)) {
                        [self setupScrollTimerInDirection:LXScrollingDirectionUp];
                    }
                    else {
                        if(viewCenter.y > (CGRectGetMaxY(collectionView.bounds) - scrollingTriggerEdgeInsets.bottom)) {
                            [self setupScrollTimerInDirection:LXScrollingDirectionDown];
                        }
                        else {
                            [self invalidateScrollTimer];
                        }
                    }
                    break;
                    
                case UICollectionViewScrollDirectionHorizontal:
                    if(viewCenter.x < (CGRectGetMinX(collectionView.bounds) + scrollingTriggerEdgeInsets.left)) {
                        [self setupScrollTimerInDirection:LXScrollingDirectionLeft];
                    }
                    else {
                        if(viewCenter.x > (CGRectGetMaxX(collectionView.bounds) - scrollingTriggerEdgeInsets.right)) {
                            [self setupScrollTimerInDirection:LXScrollingDirectionRight];
                        }
                        else {
                            [self invalidateScrollTimer];
                        }
                    }
                    break;
            }
            break;
            
        case UIGestureRecognizerStateEnded:
            [self invalidateScrollTimer];
            break;
            
        default: break;
    }
}

#pragma mark - UICollectionViewFlowLayoutDelegate methods

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)theRect
{
    NSArray *theLayoutAttributesForElementsInRect = [super layoutAttributesForElementsInRect:theRect];
    
    for (UICollectionViewLayoutAttributes *theLayoutAttributes in theLayoutAttributesForElementsInRect) {
        switch (theLayoutAttributes.representedElementCategory) {
            case UICollectionElementCategoryCell:
                [self applyLayoutAttributes:theLayoutAttributes];
                break;
                
            default: break;
        }
    }
    
    return theLayoutAttributesForElementsInRect;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)theIndexPath
{
    UICollectionViewLayoutAttributes *theLayoutAttributes = [super layoutAttributesForItemAtIndexPath:theIndexPath];
    
    switch (theLayoutAttributes.representedElementCategory) {
        case UICollectionElementCategoryCell:
            [self applyLayoutAttributes:theLayoutAttributes];
            break;
            
        default: break;
    }
    
    return theLayoutAttributes;
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([panGestureRecognizer isEqual:gestureRecognizer]) {
        return (selectedItemIndexPath != nil);
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([longPressGestureRecognizer isEqual:gestureRecognizer]) {
        return [panGestureRecognizer isEqual:otherGestureRecognizer];
    }
    
    if ([panGestureRecognizer isEqual:gestureRecognizer]) {
        return [longPressGestureRecognizer isEqual:otherGestureRecognizer];
    }
    
    return NO;
}

@end

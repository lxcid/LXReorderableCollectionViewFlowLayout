//
//  LXCollectionViewController.m
//  LXRCVFL Example using Storyboard
//
//  Created by Stan Chang Khin Boon on 3/10/12.
//  Copyright (c) 2012 d--buzz. All rights reserved.
//

#import "LXCollectionViewController.h"
#import "PlayingCard.h"
#import "PlayingCardCell.h"

@implementation LXCollectionViewController
@synthesize deck;

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    deck = [self constructsDeck];
}

- (NSMutableArray *)constructsDeck
{
    NSMutableArray *newDeck = [NSMutableArray arrayWithCapacity:52];
    
    for (NSInteger rank = 1; rank <= 13; rank++) {
        // Spade
        {
            PlayingCard *playingCard = [[PlayingCard alloc] init];
            playingCard.suit = PlayingCardSuitSpade;
            playingCard.rank = rank;
            [newDeck addObject:playingCard];
        }
        
        // Heart
        {
            PlayingCard *playingCard = [[PlayingCard alloc] init];
            playingCard.suit = PlayingCardSuitHeart;
            playingCard.rank = rank;
            [newDeck addObject:playingCard];
        }
        
        // Club
        {
            PlayingCard *playingCard = [[PlayingCard alloc] init];
            playingCard.suit = PlayingCardSuitClub;
            playingCard.rank = rank;
            [newDeck addObject:playingCard];
        }
        
        // Diamond
        {
            PlayingCard *playingCard = [[PlayingCard alloc] init];
            playingCard.suit = PlayingCardSuitDiamond;
            playingCard.rank = rank;
            [newDeck addObject:playingCard];
        }
    }
    
    return newDeck;
}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)theCollectionView numberOfItemsInSection:(NSInteger)theSectionIndex
{
    return deck.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PlayingCard *playingCard = [deck objectAtIndex:indexPath.item];
    PlayingCardCell *playingCardCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PlayingCardCell" forIndexPath:indexPath];
    playingCardCell.playingCard = playingCard;
    
    return playingCardCell;
}

#pragma mark - LXReorderableCollectionViewDelegateFlowLayout methods

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath
{
    PlayingCard *cardFrom = [deck objectAtIndex:fromIndexPath.item];

    [deck removeObjectAtIndex:fromIndexPath.item];
    [deck insertObject:cardFrom atIndex:toIndexPath.item];
}

@end

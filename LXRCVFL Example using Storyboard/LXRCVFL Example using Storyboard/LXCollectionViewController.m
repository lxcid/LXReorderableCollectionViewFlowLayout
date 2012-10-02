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

@interface LXCollectionViewController ()

@end

@implementation LXCollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.deck = [self constructsDeck];
}

- (NSMutableArray *)constructsDeck {
    NSMutableArray *theDeck = [NSMutableArray arrayWithCapacity:52];
    for (NSInteger theRank = 1; theRank <= 13; theRank++) {
        // Spade
        {
            PlayingCard *thePlayingCard = [[PlayingCard alloc] init];
            thePlayingCard.suit = PlayingCardSuitSpade;
            thePlayingCard.rank = theRank;
            [theDeck addObject:thePlayingCard];
        }
        
        // Heart
        {
            PlayingCard *thePlayingCard = [[PlayingCard alloc] init];
            thePlayingCard.suit = PlayingCardSuitHeart;
            thePlayingCard.rank = theRank;
            [theDeck addObject:thePlayingCard];
        }
        
        // Club
        {
            PlayingCard *thePlayingCard = [[PlayingCard alloc] init];
            thePlayingCard.suit = PlayingCardSuitClub;
            thePlayingCard.rank = theRank;
            [theDeck addObject:thePlayingCard];
        }
        
        // Diamond
        {
            PlayingCard *thePlayingCard = [[PlayingCard alloc] init];
            thePlayingCard.suit = PlayingCardSuitDiamond;
            thePlayingCard.rank = theRank;
            [theDeck addObject:thePlayingCard];
        }
    }
    return theDeck;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)theCollectionView numberOfItemsInSection:(NSInteger)theSectionIndex {
    switch (theSectionIndex) {
        case 0: {
            return [[self valueForKeyPath:@"deck.@count"] integerValue];
        } break;
        default: {
            return 0;
        } break;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)theCollectionView cellForItemAtIndexPath:(NSIndexPath *)theIndexPath {
    NSInteger theSectionIndex = theIndexPath.section;
    NSInteger theItemIndex = theIndexPath.item;
    switch (theSectionIndex) {
        case 0: {
            PlayingCard *thePlayingCard = [self.deck objectAtIndex:theItemIndex];
            PlayingCardCell *thePlayingCardCell = [theCollectionView dequeueReusableCellWithReuseIdentifier:@"PlayingCardCell" forIndexPath:theIndexPath];
            thePlayingCardCell.playingCard = thePlayingCard;
            return thePlayingCardCell;
        } break;
        default: {
            return nil;
        } break;
    }
}

#pragma mark - LXReorderableCollectionViewDelegateFlowLayout methods

- (void)itemAtIndexPath:(NSIndexPath *)theFromIndexPath willMoveToIndexPath:(NSIndexPath *)theToIndexPath {
    id theFromItem = [self.deck objectAtIndex:theFromIndexPath.item];
    [self.deck removeObjectAtIndex:theFromIndexPath.item];
    [self.deck insertObject:theFromItem atIndex:theToIndexPath.item];
}

@end

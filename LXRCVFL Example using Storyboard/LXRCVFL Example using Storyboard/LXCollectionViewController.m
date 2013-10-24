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

#pragma mark - Private

- (void)logDeck {
    NSLog(@"self.deck: (");
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    NSInteger splitCount = (UIInterfaceOrientationIsPortrait(statusBarOrientation) ? 4 : 5);
    
    NSInteger index = 0;
    for (PlayingCard *thePlayingCard in self.deck) {
        printf("\t%-8s", [[thePlayingCard description] UTF8String]);
        index++;
        if (index % splitCount == 0) {
            printf("\n");
        }
    }
    printf("\n");
    NSLog(@")");
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

#pragma mark - LXReorderableCollectionViewDataSource methods

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    PlayingCard *thePlayingCard = [self.deck objectAtIndex:indexPath.item];

    // can move everything except hearts
    return (thePlayingCard.suit != PlayingCardSuitHeart);
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {

    // can move anywhere
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView willMoveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
    NSLog(@"%s%@:%@", __PRETTY_FUNCTION__, fromIndexPath, toIndexPath);
    [self logDeck];
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
    NSLog(@"%s%@:%@", __PRETTY_FUNCTION__, fromIndexPath, toIndexPath);

    id theFromItem = [self.deck objectAtIndex:fromIndexPath.item];
    [self.deck removeObjectAtIndex:fromIndexPath.item];
    [self.deck insertObject:theFromItem atIndex:toIndexPath.item];
}

- (void)collectionView:(UICollectionView *)collectionView didMoveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
    NSLog(@"%s%@:%@", __PRETTY_FUNCTION__, fromIndexPath, toIndexPath);
    [self logDeck];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canDropItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
    PlayingCard *thePlayingCard = [self.deck objectAtIndex:toIndexPath.item];
    
    // can drop only on hearts
    return (thePlayingCard.suit == PlayingCardSuitHeart);
}

- (void)collectionView:(UICollectionView *)collectionView willDropItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
    NSLog(@"%s%@:%@", __PRETTY_FUNCTION__, fromIndexPath, toIndexPath);
    [self logDeck];
}

- (void)collectionView:(UICollectionView *)collectionView dropItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
    NSLog(@"%s%@:%@", __PRETTY_FUNCTION__, fromIndexPath, toIndexPath);
    
    // remove old card
    id theToItem = [self.deck objectAtIndex:toIndexPath.item];
    [self.deck removeObject:theToItem];
    [collectionView deleteItemsAtIndexPaths:@[toIndexPath]];

    id theFromItem = [self.deck objectAtIndex:fromIndexPath.item];
    // insert new card
    [self.deck removeObjectAtIndex:fromIndexPath.item];
    [self.deck insertObject:theFromItem atIndex:toIndexPath.item];
}

- (void)collectionView:(UICollectionView *)collectionView didDropItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
    NSLog(@"%s%@:%@", __PRETTY_FUNCTION__, fromIndexPath, toIndexPath);
    [self logDeck];
}

@end

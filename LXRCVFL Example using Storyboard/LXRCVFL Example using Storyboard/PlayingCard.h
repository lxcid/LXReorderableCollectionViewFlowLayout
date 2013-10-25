//
//  PlayingCard.h
//  LXRCVFL Example using Storyboard
//
//  Created by Stan Chang Khin Boon on 3/10/12.
//  Copyright (c) 2012 d--buzz. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PlayingCardSuit) {
    PlayingCardSuitSpade,
    PlayingCardSuitHeart,
    PlayingCardSuitClub,
    PlayingCardSuitDiamond
};

typedef NS_ENUM(NSInteger, PlayingCardRank) {
    PlayingCardRankBack,
    PlayingCardRankAce,
    PlayingCardRankTwo,
    PlayingCardRankThree,
    PlayingCardRankFour,
    PlayingCardRankFive,
    PlayingCardRankSix,
    PlayingCardRankSeven,
    PlayingCardRankEight,
    PlayingCardRankNine,
    PlayingCardRankTen,
    PlayingCardRankJack,
    PlayingCardRankQueen,
    PlayingCardRankKing,
    PlayingCardRankJokerBlack = 1000,
    PlayingCardRankJokerRed
};

@interface PlayingCard : NSObject

@property (assign, nonatomic) PlayingCardSuit suit;
@property (assign, nonatomic) NSInteger rank;
@property (assign, nonatomic, getter = isVisible) BOOL visible;

@property (copy, nonatomic, readonly) NSString *imageName;
@property (copy, nonatomic, readonly) NSString *suiteName;
@property (copy, nonatomic, readonly) NSString *rankName;

@end

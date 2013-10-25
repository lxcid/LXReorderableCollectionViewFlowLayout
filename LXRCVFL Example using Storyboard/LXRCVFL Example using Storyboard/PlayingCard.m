//
//  PlayingCard.m
//  LXRCVFL Example using Storyboard
//
//  Created by Stan Chang Khin Boon on 3/10/12.
//  Copyright (c) 2012 d--buzz. All rights reserved.
//

#import "PlayingCard.h"

@implementation PlayingCard

- (NSString *)imageName {
    switch (self.suit) {
        case PlayingCardSuitSpade: {
            return [NSString stringWithFormat:@"Content/Images/cards_png/s%i.png", self.rank];
        } break;
        case PlayingCardSuitHeart: {
            return [NSString stringWithFormat:@"Content/Images/cards_png/h%i.png", self.rank];
        } break;
        case PlayingCardSuitClub: {
            return [NSString stringWithFormat:@"Content/Images/cards_png/c%i.png", self.rank];
        } break;
        case PlayingCardSuitDiamond: {
            return [NSString stringWithFormat:@"Content/Images/cards_png/d%i.png", self.rank];
        } break;
    }
}

- (NSString *)suiteName {
    switch (self.suit) {
        case PlayingCardSuitSpade: {
            return @"♠";
        } break;
        case PlayingCardSuitHeart: {
            return @"♥";
        } break;
        case PlayingCardSuitClub: {
            return @"♣";
        } break;
        case PlayingCardSuitDiamond: {
            return @"♦";
        } break;
    }
}

- (NSString *)rankName {
    switch (self.rank) {
        case PlayingCardRankAce: {
            return @"A";
        } break;
        case PlayingCardRankJack: {
            return @"J";
        } break;
        case PlayingCardRankQueen: {
            return @"Q";
        } break;
        case PlayingCardRankKing: {
            return @"K";
        } break;
        default: {
            return [NSString stringWithFormat:@"%i", self.rank];
        } break;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@", self.suiteName, self.rankName];
}

@end

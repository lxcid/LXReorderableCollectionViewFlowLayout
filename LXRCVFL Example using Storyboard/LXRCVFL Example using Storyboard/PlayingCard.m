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
            return [NSString stringWithFormat:@"Content/Images/cards_png/s%d.png", self.rank];
        } break;
        case PlayingCardSuitHeart: {
            return [NSString stringWithFormat:@"Content/Images/cards_png/h%d.png", self.rank];
        } break;
        case PlayingCardSuitClub: {
            return [NSString stringWithFormat:@"Content/Images/cards_png/c%d.png", self.rank];
        } break;
        case PlayingCardSuitDiamond: {
            return [NSString stringWithFormat:@"Content/Images/cards_png/d%d.png", self.rank];
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
        case 1: {
            return @"A";
        } break;
        case 11: {
            return @"J";
        } break;
        case 12: {
            return @"Q";
        } break;
        case 13: {
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

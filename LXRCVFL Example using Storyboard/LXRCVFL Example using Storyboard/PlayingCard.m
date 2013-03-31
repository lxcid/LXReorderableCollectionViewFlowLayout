//
//  PlayingCard.m
//  LXRCVFL Example using Storyboard
//
//  Created by Stan Chang Khin Boon on 3/10/12.
//  Copyright (c) 2012 d--buzz. All rights reserved.
//

#import "PlayingCard.h"

@implementation PlayingCard
@synthesize suit;
@synthesize rank;

- (NSString *)imageName
{
    switch (self.suit) {
        case PlayingCardSuitSpade:
            return [NSString stringWithFormat:@"Content/Images/cards_png/s%d.png", rank];
        case PlayingCardSuitHeart:
            return [NSString stringWithFormat:@"Content/Images/cards_png/h%d.png", rank];
        case PlayingCardSuitClub:
            return [NSString stringWithFormat:@"Content/Images/cards_png/c%d.png", rank];
        case PlayingCardSuitDiamond:
            return [NSString stringWithFormat:@"Content/Images/cards_png/d%d.png", rank];
    }
}

@end

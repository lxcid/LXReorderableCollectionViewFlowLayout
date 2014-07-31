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
        case PlayingCardSuitSpade:
            return [NSString stringWithFormat:@"Content/Images/cards_png/s%ld.png", (long)self.rank];
        case PlayingCardSuitHeart:
            return [NSString stringWithFormat:@"Content/Images/cards_png/h%ld.png", (long)self.rank];
        case PlayingCardSuitClub:
            return [NSString stringWithFormat:@"Content/Images/cards_png/c%ld.png", (long)self.rank];
        case PlayingCardSuitDiamond:
            return [NSString stringWithFormat:@"Content/Images/cards_png/d%ld.png", (long)self.rank];
    }
}

@end

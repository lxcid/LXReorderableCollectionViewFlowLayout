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

@interface PlayingCard : NSObject

@property (assign, nonatomic) PlayingCardSuit suit;
@property (assign, nonatomic) NSInteger rank;
@property (readonly, nonatomic) NSString *imageName;

@end

//
//  PlayingCardCell.m
//  LXRCVFL Example using Storyboard
//
//  Created by Stan Chang Khin Boon on 3/10/12.
//  Copyright (c) 2012 d--buzz. All rights reserved.
//

#import "PlayingCardCell.h"
#import "PlayingCard.h"

@implementation PlayingCardCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setPlayingCard:(PlayingCard *)thePlayingCard {
    _playingCard = thePlayingCard;
    
    self.playingCardImageView.image = [UIImage imageNamed:self.playingCard.imageName];
}

- (void)setHighlighted:(BOOL)theHighlighted {
    [super setHighlighted:theHighlighted];
    
    self.playingCardImageView.alpha = theHighlighted ? 0.75f : 1.0f;
}

@end

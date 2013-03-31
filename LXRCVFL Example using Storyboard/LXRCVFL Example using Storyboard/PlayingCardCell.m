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
@synthesize playingCard;

- (void)setPlayingCard:(PlayingCard *)thePlayingCard
{
    playingCard = thePlayingCard;
    self.playingCardImageView.image = [UIImage imageNamed:playingCard.imageName];
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.playingCardImageView.alpha = highlighted ? 0.75f : 1.0f;
}

@end

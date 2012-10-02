//
//  PlayingCardCell.h
//  LXRCVFL Example using Storyboard
//
//  Created by Stan Chang Khin Boon on 3/10/12.
//  Copyright (c) 2012 d--buzz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PlayingCard;

@interface PlayingCardCell : UICollectionViewCell

@property (weak, nonatomic) PlayingCard *playingCard;

@property (weak, nonatomic) IBOutlet UIImageView *playingCardImageView;


@end

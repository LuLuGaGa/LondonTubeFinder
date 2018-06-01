//
//  TrainsTableViewCell.h
//  LondonTubeFinder
//
//  Created by Lucyna Galik on 23/04/2018.
//  Copyright © 2018 Lucyna Galik. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrainsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel    *destiantionLabel;
@property (weak, nonatomic) IBOutlet UILabel    *timeDueLabel;
@property (weak, nonatomic) IBOutlet UIView     *lineColourOutline;


@end

//
//  StationTableViewCell.h
//  LondonTubeFinder
//
//  Created by Lucyna Galik on 22/04/2018.
//  Copyright © 2018 Lucyna Galik. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StationTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *stationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *linesOblongs;


@end

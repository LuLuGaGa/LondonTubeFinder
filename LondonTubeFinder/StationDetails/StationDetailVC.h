//
//  StationDetailVC.h
//  LondonTubeFinder
//
//  Created by Lucyna Galik on 22/04/2018.
//  Copyright © 2018 Lucyna Galik. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface StationDetailVC : UIViewController <UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic) NSString *naptanId;
@property (strong, nonatomic) NSString *stationName;

@end

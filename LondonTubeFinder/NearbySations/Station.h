//
//  Station.h
//  LondonTubeFinder
//
//  Created by Lucyna Galik on 18/04/2018.
//  Copyright © 2018 Lucyna Galik. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface Station : NSObject

@property (nonatomic, strong)   NSString    *naptanId;
@property (nonatomic, strong)   NSString    *commonName;
@property (nonatomic)           int         distance;
@property (nonatomic, strong)   NSArray     *lineNames;

@end

//
//  Train.h
//  LondonTubeFinder
//
//  Created by Lucyna Galik on 22/04/2018.
//  Copyright © 2018 Lucyna Galik. All rights reserved.
//

#import <Foundation/Foundation.h>
//
@interface Train : NSObject

@property (nonatomic, strong)   NSString    *destiantionName;
@property (nonatomic)           int         timeDue;
@property (nonatomic, strong)   NSString    *lineName;

@end

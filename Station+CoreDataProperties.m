//
//  Station+CoreDataProperties.m
//  CitymapperCodingChallenge
//
//  Created by Lucyna Galik on 18/04/2018.
//  Copyright © 2018 Lucyna Galik. All rights reserved.
//
//

#import "Station+CoreDataProperties.h"

@implementation Station (CoreDataProperties)

+ (NSFetchRequest<Station *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Station"];
}

@dynamic name;
@dynamic longitude;
@dynamic latitude;

@end

//
//  Station+CoreDataProperties.h
//  CitymapperCodingChallenge
//
//  Created by Lucyna Galik on 18/04/2018.
//  Copyright © 2018 Lucyna Galik. All rights reserved.
//
//

#import "Station+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Station (CoreDataProperties)

+ (NSFetchRequest<Station *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *name;
@property (nonatomic) double longitude;
@property (nonatomic) double latitude;

@end

NS_ASSUME_NONNULL_END

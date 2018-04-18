//
//  AppDelegate.h
//  CitymapperCodingChallenge
//
//  Created by Lucyna Galik on 18/04/2018.
//  Copyright © 2018 Lucyna Galik. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end


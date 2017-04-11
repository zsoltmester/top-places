//
//  AppDelegate.h
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 04..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic, readonly) NSManagedObjectContext *databaseContext;

+ (AppDelegate *)sharedAppDelegate;

@end


//
//  RecentsRepository.h
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 06..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecentsRepository : NSObject

+ (void)addPhoto:(NSDictionary *)photo;
+ (NSArray *)getRecentPhotos; // of NSDictionary

@end

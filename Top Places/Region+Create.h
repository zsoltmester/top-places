//
//  Region+Create.h
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 09..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import "Region+CoreDataClass.h"

@interface Region (Create)

+ (Region *)getOrCreateRegionWithUnique:(NSString *)unique
								andName:(NSString *)name
							 inDatabase:(NSManagedObjectContext *)databaseContext;

@end

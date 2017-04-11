//
//  Photographer+Create.h
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 09..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import "Photographer+CoreDataClass.h"

@interface Photographer (Create)

+ (Photographer *)getOrCreatePhotographerWithUnique:(NSString *)unique
											andName:(NSString *)name
										 inDatabase:(NSManagedObjectContext *)databaseContext;

@end

//
//  Photographer+Create.m
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 09..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import "Photographer+Create.h"

@implementation Photographer (Create)

+ (Photographer *)getOrCreatePhotographerWithUnique:(NSString *)unique
											andName:(NSString *)name
										 inDatabase:(NSManagedObjectContext *)databaseContext;
{
	if (![unique length] || ![name length]) {
		NSLog(@"Error when getOrCreatePhotographerWithUnique: %@ andName: %@", unique, name);
		return nil;
	}

	NSFetchRequest *request = [Photographer fetchRequest];
	request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", unique];

	NSError *error;
	NSArray *matches = [databaseContext executeFetchRequest:request error:&error];

	Photographer *photographer = nil;
	if (!matches || ([matches count] > 1)) {
		NSLog(@"Error at getOrCreatePhotographerWithUnique:andName:inDatabase.");
		return nil;
	} else if (![matches count]) {
		photographer = [NSEntityDescription insertNewObjectForEntityForName:@"Photographer"
													 inManagedObjectContext:databaseContext];
		photographer.unique = unique;
		photographer.name = name;
	} else {
		photographer = [matches lastObject];
	}

	return photographer;
}

@end

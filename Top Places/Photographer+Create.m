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
	unique = [unique stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if (![unique length] || ![name length]) {
		NSLog(@"Error when getOrCreatePhotographerWithUnique: %@ andName: %@", unique, name);
		return nil;
	}

	NSFetchRequest *request = [Photographer fetchRequest];
	request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", unique];

	NSError *error;
	NSArray *matches = [databaseContext executeFetchRequest:request error:&error];

	Photographer *photographer = nil;
	if (!matches || error) {
		NSLog(@"Error when find photographer: %@", error.localizedDescription);
		return nil;
	} else if ([matches count] > 1){
		NSLog(@"More matches for photographer: %@", unique);
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

//
//  Region+Create.m
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 09..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import "Region+Create.h"

@implementation Region (Create)

+ (Region *)getOrCreateRegionWithUnique:(NSString *)unique
								andName:(NSString *)name
							 inDatabase:(NSManagedObjectContext *)databaseContext
{
	unique = [unique stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if (![unique length] || ![name length]) {
		NSLog(@"Error when getOrCreateRegionWithUnique: %@ andName: %@", unique, name);
		return nil;
	}

	NSFetchRequest *request = [Region fetchRequest];
	request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", unique];

	NSError *error;
	NSArray *matches = [databaseContext executeFetchRequest:request error:&error];

	Region *region = nil;
	if (!matches || error) {
		NSLog(@"Error when find region: %@", error.localizedDescription);
		return nil;
	} else if ([matches count] > 1){
		NSLog(@"More matches for region: %@", unique);
	} else if (![matches count]) {
		region = [NSEntityDescription insertNewObjectForEntityForName:@"Region"
													 inManagedObjectContext:databaseContext];
		region.unique = unique;
		region.name = name;
		region.popularity = 0;
	} else {
		region = [matches lastObject];
	}

	return region;
}

@end

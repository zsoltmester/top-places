//
//  Photo+Flickr.m
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 09..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import "Photo+Flickr.h"
#import "FlickrFetcher.h"
#import "Photographer+CoreDataClass.h"
#import "Region+CoreDataClass.h"
#import "Photographer+Create.h"
#import "Region+Create.h"

@implementation Photo (Flickr)

+ (Photo *)getOrCreatePhotoWithFlickrInfo:(NSDictionary *)infoFromFlickr
							andRegionName:(NSString *)regionName
							   inDatabase:(NSManagedObjectContext *)databaseContext;
{
	regionName = [regionName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if (![regionName length]) {
		NSLog(@"Error when getOrCreatePhotoWithFlickrInfo: %@ andRegionName: %@", infoFromFlickr, regionName);
		return nil;
	}

	NSString *photoId = [infoFromFlickr[FLICKR_PHOTO_ID] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSFetchRequest *fetchRequest = [Photo fetchRequest];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"unique = %@", photoId];

	NSError *error;
	NSArray *matches = [databaseContext executeFetchRequest:fetchRequest error:&error];

	Photo *photo = nil;
	if (!matches || error) {
		NSLog(@"Error when find photo: %@", error.localizedDescription);
	} else if ([matches count] > 1){
		NSLog(@"More matches for photo: %@", photoId);
	} else if ([matches count]) {
		photo = [matches firstObject];
	} else {
		NSString *photographerUnique = [infoFromFlickr valueForKeyPath:FLICKR_PHOTO_OWNER_ID];
		NSString *photographerName = [infoFromFlickr valueForKeyPath:FLICKR_PHOTO_OWNER_NAME];
		NSString *regionUnique = [infoFromFlickr valueForKeyPath:FLICKR_PLACE_ID];
		if (!photographerUnique || !photographerName || !regionUnique) {
			return nil;
		}

		photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo"
											  inManagedObjectContext:databaseContext];
		photo.unique = [[infoFromFlickr valueForKeyPath:FLICKR_PHOTO_ID] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		photo.title = [[infoFromFlickr valueForKeyPath:FLICKR_PHOTO_TITLE] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		photo.desc = [[infoFromFlickr valueForKeyPath:FLICKR_PHOTO_DESCRIPTION] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

		photo.whoTook = [Photographer getOrCreatePhotographerWithUnique:photographerUnique
																andName:photographerName
															 inDatabase:databaseContext];

		photo.whereTook = [Region getOrCreateRegionWithUnique:regionUnique
													  andName:regionName
												   inDatabase:databaseContext];
		++photo.whereTook.popularity;
	}

	return photo;
}

@end

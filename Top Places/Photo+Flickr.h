//
//  Photo+Flickr.h
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 09..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import "Photo+CoreDataClass.h"

@interface Photo (Flickr)

+ (Photo *)getOrCreatePhotoWithFlickrInfo:(NSDictionary *)infoFromFlickr
							andRegionName:(NSString *)regionName
							   inDatabase:(NSManagedObjectContext *)databaseContext;

@end

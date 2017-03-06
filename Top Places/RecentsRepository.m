//
//  RecentsRepository.m
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 06..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import "RecentsRepository.h"
#import "FlickrFetcher.h"

@implementation RecentsRepository

static const NSString *USER_DEFAULTS_RECENTS = @"Recents";

+ (void)addPhoto:(NSDictionary *)photo
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

	NSMutableArray *recents = [[userDefaults arrayForKey:(NSString *)USER_DEFAULTS_RECENTS] mutableCopy];
	if (!recents) {
		recents = [NSMutableArray new];
	}

	for (NSDictionary *savedPhoto in recents) {
		if ([photo[FLICKR_PHOTO_ID] isEqualToString:savedPhoto[FLICKR_PHOTO_ID]]) {
			[recents removeObject:savedPhoto];
			break;
		}
	}

	[recents insertObject:photo atIndex:0];

	if ([recents count] > 20) {
		[recents removeLastObject];
	}

	[userDefaults setObject:recents forKey:(NSString *)USER_DEFAULTS_RECENTS];
	[userDefaults synchronize];
}

+ (NSArray *)getRecentPhotos; // of NSDictionary
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	return [[userDefaults arrayForKey:(NSString *)USER_DEFAULTS_RECENTS] mutableCopy];
}

@end

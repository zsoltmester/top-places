//
//  AppDelegate.m
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 04..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import "AppDelegate.h"
#import "FlickrFetcher.h"
#import "Photo+Flickr.h"

@interface AppDelegate () <NSURLSessionDownloadDelegate>

@property (strong, nonatomic, readwrite) NSManagedObjectContext *databaseContext;
@property (strong, nonatomic) NSManagedObjectContext *backgroundDatabaseContext;
@property (strong, nonatomic) NSArray *fetchedPhotos; // of NSDictionary
@property (strong, nonatomic) NSOperationQueue *fetchRegionsQueue;

@end

#define TASK_FETCH_RECENT_PHOTOS @"TASK_FETCH_RECENT_PHOTOS"
#define TASK_FETCH_REGION @"TASK_FETCH_REGION:"

@implementation AppDelegate

+ (AppDelegate *)sharedAppDelegate
{
	return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	//[[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
	self.fetchRegionsQueue = [[NSOperationQueue alloc] init];
	[self startToOpenDatabase];
	return YES;
}

#pragma mark - Database Context


- (NSURL *)getDatabaseURL
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *documentsDirectory = [[fileManager URLsForDirectory:NSDocumentDirectory
													 inDomains:NSUserDomainMask] firstObject];
	NSString *documentName = @"TopPlacesCoreData";
	return [documentsDirectory URLByAppendingPathComponent:documentName];
}

- (void)startToOpenDatabase
{
	NSURL *databaseURL = [self getDatabaseURL];
	UIManagedDocument *document = [[UIManagedDocument alloc] initWithFileURL:databaseURL];
	if ([[NSFileManager defaultManager] fileExistsAtPath:[databaseURL path]]) {
		[document openWithCompletionHandler:^(BOOL success) {
			if (success) {
				[self databaseIsReady:document];
			} else {
				NSLog(@"couldn't open document at %@", databaseURL);
			}
		}];
	} else {
		[document saveToURL:databaseURL forSaveOperation:UIDocumentSaveForCreating
			   completionHandler:^(BOOL success) {
				   if (success) {
					   [self databaseIsReady:document];
				   } else {
					   NSLog(@"couldn't create document at %@", databaseURL);
				   }
			   }];
	}
}

- (void)databaseIsReady:(UIManagedDocument *)database
{
	self.databaseContext = database.managedObjectContext;
	[self startToFetchFlickr];
}

#pragma mark - Flickr Fetching

- (void)startToFetchFlickr
{
	NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:TASK_FETCH_RECENT_PHOTOS];
	NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
														   delegate:self
													  delegateQueue:nil];
	[session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
		if ([downloadTasks count]) {
			// we are working on a fetch
			// let's make sure they are running
			for (NSURLSessionDownloadTask *task in downloadTasks) {
				[task resume];
			}
		} else {
			// no fetch running, let's start one up
			NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[FlickrFetcher URLforRecentGeoreferencedPhotos]];
			task.taskDescription = TASK_FETCH_RECENT_PHOTOS;
			[task resume];
		}
	}];
}

/*
- (void)startFlickrFetch:(NSTimer *)timer // NSTimer target/action always takes an NSTimer as an argument
{
	[self startToFetchFlickr];
}
 */

- (NSArray *)parseFlickrPhotosAtLocation:(NSURL *)location
{
	NSData *resultsJSON = [NSData dataWithContentsOfURL:location];
	NSDictionary *results = [NSJSONSerialization JSONObjectWithData:resultsJSON options:0 error:NULL];
	return [results valueForKeyPath:FLICKR_RESULTS_PHOTOS];
}

- (void)handleRecentPhotosResponseAtLocation:(NSURL *)location
{
	self.fetchedPhotos = [self parseFlickrPhotosAtLocation:location];
	for (NSDictionary *photo in self.fetchedPhotos) {
		NSString *placeId = photo[FLICKR_PLACE_ID];
		if (!placeId) {
			NSLog(@"placeId is nil from self.fetchedPhotos");
			continue;
		}

		NSString *taskId = [TASK_FETCH_REGION stringByAppendingString:placeId];

		NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:taskId];
		NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
														   delegate:self
													  delegateQueue:self.fetchRegionsQueue];
		[session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
			if ([downloadTasks count]) {
				// we are working on a fetch
				// let's make sure they are running
				for (NSURLSessionDownloadTask *task in downloadTasks) {
					[task resume];
				}
			} else {
				// no fetch running, let's start one up
				NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[FlickrFetcher URLforInformationAboutPlace:placeId]];
				task.taskDescription = taskId;
				[task resume];
			}
		}];
	}
}

- (void)handleRegionResponseAtLocation:(NSURL *)location
{
	NSData *resultsJSON = [NSData dataWithContentsOfURL:location];
	if (!resultsJSON) {
		NSLog(@"Error at handleRegionResponseAtLocation: resultsJSON is nil with location: %@", location.absoluteString);
		return;
	}
	NSDictionary *results = [NSJSONSerialization JSONObjectWithData:resultsJSON options:0 error:NULL];
	for (NSDictionary *photo in self.fetchedPhotos) {
		NSString *regionName = [FlickrFetcher extractNameOfPlace:photo[FLICKR_PLACE_ID]
											fromPlaceInformation:results];
		if (!regionName) {
			continue;
		}

		if (!self.backgroundDatabaseContext) {
			self.backgroundDatabaseContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
			[self.backgroundDatabaseContext setPersistentStoreCoordinator:[self.databaseContext persistentStoreCoordinator]];
		}
		[self.backgroundDatabaseContext performBlock:^{
			[Photo getOrCreatePhotoWithFlickrInfo:photo
									andRegionName:regionName
									   inDatabase:self.backgroundDatabaseContext];
			[self.backgroundDatabaseContext save:NULL];
		}];
	}
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
	if ([downloadTask.taskDescription isEqualToString:TASK_FETCH_RECENT_PHOTOS]) {
		[self handleRecentPhotosResponseAtLocation:location];
	} else if ([downloadTask.taskDescription hasPrefix:TASK_FETCH_REGION]) {
		[self handleRegionResponseAtLocation:location];
	} else {
		NSLog(@"Invalid task: %@", downloadTask);
	}
}

- (void)URLSession:(NSURLSession *)session
	  downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
}

- (void)URLSession:(NSURLSession *)session
	  downloadTask:(NSURLSessionDownloadTask *)downloadTask
	  didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
	if (error) {
		NSLog(@"Flickr background download failed: %@", error.localizedDescription);
	}
}

@end

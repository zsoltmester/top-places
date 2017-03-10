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
//@property (copy, nonatomic) void (^flickrDownloadBackgroundURLSessionCompletionHandler)();
//@property (strong, nonatomic) NSURLSession *flickrDownloadSession;
//@property (strong, nonatomic) NSTimer *flickrForegroundFetchTimer;

@end

#define TASK_FETCH_RECENT_PHOTOS @"TASK_FETCH_RECENT_PHOTOS"
#define TASK_FETCH_REGION @"TASK_FETCH_REGION:"

// how often (in seconds) we fetch new photos if we are in the foreground
//#define FOREGROUND_FLICKR_FETCH_INTERVAL (20*60)

// how long we'll wait for a Flickr fetch to return when we're in the background
//#define BACKGROUND_FLICKR_FETCH_TIMEOUT (10)

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

/*
// this is called occasionally by the system WHEN WE ARE NOT THE FOREGROUND APPLICATION
// in fact, it will LAUNCH US if necessary to call this method
// the system has lots of smarts about when to do this, but it is entirely opaque to us

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
	// in lecture, we relied on our background flickrDownloadSession to do the fetch by calling [self startFlickrFetch]
	// that was easy to code up, but pretty weak in terms of how much it will actually fetch (maybe almost never)
	// that's because there's no guarantee that we'll be allowed to start that discretionary fetcher when we're in the background
	// so let's simply make a non-discretionary, non-background-session fetch here
	// we don't want it to take too long because the system will start to lose faith in us as a background fetcher and stop calling this as much
	// so we'll limit the fetch to BACKGROUND_FETCH_TIMEOUT seconds (also we won't use valuable cellular data)

	if (self.databaseContext) {
		NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
		sessionConfig.allowsCellularAccess = NO;
		sessionConfig.timeoutIntervalForRequest = BACKGROUND_FLICKR_FETCH_TIMEOUT; // want to be a good background citizen!
		NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
		NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[FlickrFetcher URLforRecentGeoreferencedPhotos]];
		NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
														completionHandler:^(NSURL *localFile, NSURLResponse *response, NSError *error) {
															if (error) {
																NSLog(@"Flickr background fetch failed: %@", error.localizedDescription);
																completionHandler(UIBackgroundFetchResultNoData);
															} else {
																[self loadFlickrPhotosFromLocalURL:localFile
																					   intoContext:self.databaseContext
																			   andThenExecuteBlock:^{
																				   completionHandler(UIBackgroundFetchResultNewData);
																			   }
																 ];
															}
														}];
		[task resume];
	} else {
		completionHandler(UIBackgroundFetchResultNoData); // no app-switcher update if no database!
	}
}

// this is called whenever a URL we have requested with a background session returns and we are in the background
// it is essentially waking us up to handle it
// if we were in the foreground iOS would just call our delegate method and not bother with this

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
	// this completionHandler, when called, will cause our UI to be re-cached in the app switcher
	// but we should not call this handler until we're done handling the URL whose results are now available
	// so we'll stash the completionHandler away in a property until we're ready to call it
	// (see flickrDownloadTasksMightBeComplete for when we actually call it)
	self.flickrDownloadBackgroundURLSessionCompletionHandler = completionHandler;
}
 */

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

/*
// we do some stuff when our Photo database's context becomes available
// we kick off our foreground NSTimer so that we are fetching every once in a while in the foreground
// we post a notification to let others know the context is available

- (void)setDatabaseContext:(NSManagedObjectContext *)photoDatabaseContext
{
	_databaseContext = photoDatabaseContext;

	// every time the context changes, we'll restart our timer
	// so kill (invalidate) the current one
	// (we didn't get to this line of code in lecture, sorry!)
	[self.flickrForegroundFetchTimer invalidate];
	self.flickrForegroundFetchTimer = nil;

	if (self.databaseContext)
	{
		// this timer will fire only when we are in the foreground
		self.flickrForegroundFetchTimer = [NSTimer scheduledTimerWithTimeInterval:FOREGROUND_FLICKR_FETCH_INTERVAL
																		   target:self
																		 selector:@selector(startFlickrFetch:)
																		 userInfo:nil
																		  repeats:YES];
	}

	// let everyone who might be interested know this context is available
	// this happens very early in the running of our application
	// it would make NO SENSE to listen to this radio station in a View Controller that was segued to, for example
	// (but that's okay because a segued-to View Controller would presumably be "prepared" by being given a context to work in)
	NSDictionary *userInfo = self.databaseContext ? @{ PhotoDatabaseAvailabilityContext : self.databaseContext } : nil;
	[[NSNotificationCenter defaultCenter] postNotificationName:PhotoDatabaseAvailabilityNotification
														object:self
													  userInfo:userInfo];
}
 */

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

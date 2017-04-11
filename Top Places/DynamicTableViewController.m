//
//  NetworkBasedTableViewController.m
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 06..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import "DynamicTableViewController.h"

@implementation DynamicTableViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	if (self.URL) {
		[self download];
	}
}

- (IBAction)download
{
	[self.refreshControl beginRefreshing];
	NSURLRequest *request = [NSURLRequest requestWithURL:self.URL];
	NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
	NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
	NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
													completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
														if (error) {
															NSLog(@"[ERROR] Download failed with reason: %@", error);
															return;
														}
														NSData *resultsJSON = [NSData dataWithContentsOfURL:location];
														NSDictionary *results = [NSJSONSerialization JSONObjectWithData:resultsJSON options:0 error:NULL];
														[self handleResponse:results];
														[self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
													}];
	[task resume];
}

- (void)handleResponse:(NSDictionary *)response // abstract
{
}

- (void)updateUI
{
	[self.refreshControl endRefreshing];
	[self.tableView reloadData];
}

@end

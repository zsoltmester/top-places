//
//  PhotoListTableViewController.m
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 06..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import "PhotoListTableViewController.h"
#import "PhotoViewController.h"
#import "FlickrFetcher.h"
#import "RecentsRepository.h"

@implementation PhotoListTableViewController

- (void)handleResponse:(NSDictionary *)response
{
	self.photos = [response valueForKeyPath:FLICKR_RESULTS_PHOTOS];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.photos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Photo" forIndexPath:indexPath];

	NSDictionary *photo = self.photos[indexPath.row];
	cell.textLabel.text = photo[FLICKR_PHOTO_TITLE];
	if ([cell.textLabel.text isEqualToString:@""]) {
		cell.textLabel.text = @"(Unknown)";
	}
	cell.detailTextLabel.text = [photo valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];

	return cell;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
	if (![sender isKindOfClass:[UITableViewCell class]]
		|| ![segue.identifier isEqualToString:@"Show Photo"]
		|| ![segue.destinationViewController isKindOfClass:[PhotoViewController class]]
		|| !indexPath) {
		return;
	}

	[RecentsRepository addPhoto:self.photos[indexPath.row]];

	segue.destinationViewController.title = ((UITableViewCell *)sender).textLabel.text;
	((PhotoViewController *)segue.destinationViewController).URL = [FlickrFetcher URLforPhoto:self.photos[indexPath.row] format:FlickrPhotoFormatLarge];
}

@end

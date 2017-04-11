//
//  RecentsTableViewController.m
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 06..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import "RecentsTableViewController.h"
#import "PhotoViewController.h"
#import "RecentsRepository.h"
#import "FlickrFetcher.h"

@implementation RecentsTableViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.photos = [RecentsRepository getRecentPhotos];
	[self.tableView reloadData];
}

@end

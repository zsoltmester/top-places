//
//  TopRegionsCoreDataTableViewController.m
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 09..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import "TopRegionsCoreDataTableViewController.h"
#import "FlickrFetcher.h"
#import "AppDelegate.h"
#import "Region+CoreDataProperties.h"

@interface TopRegionsCoreDataTableViewController ()

@end

@implementation TopRegionsCoreDataTableViewController

-(void)viewDidLoad
{
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Region"];
	request.predicate = nil;
	request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name"
															  ascending:YES
															   selector:@selector(localizedStandardCompare:)]];

	self.debug = YES;
	self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
																		managedObjectContext:[AppDelegate sharedAppDelegate].databaseContext
																		  sectionNameKeyPath:nil
																				   cacheName:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Region Cell"];

	Region *region = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	cell.textLabel.text = region.name;

	return cell;
}

@end

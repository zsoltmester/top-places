//
//  TopPlacesTableViewController.m
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 04..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import "TopPlacesTableViewController.h"
#import "PhotoListTableViewController.h"
#import "FlickrFetcher.h"

@interface TopPlacesTableViewController ()

@property (nonatomic, strong) NSMutableDictionary *topPlaces;

@end

@implementation TopPlacesTableViewController

- (void)viewDidLoad {
	self.URL = [FlickrFetcher URLforTopPlaces];
    [super viewDidLoad];
}

- (void)handleResponse:(NSDictionary *)response
{
	self.topPlaces = [NSMutableDictionary new];
	NSArray *places = [response valueForKeyPath:FLICKR_RESULTS_PLACES];
	for (NSDictionary* place in places) {
		NSString *country = [FlickrFetcher extractCountryFromPlaceName:place[FLICKR_PLACE_NAME]];
		NSMutableArray *placesForCountry = self.topPlaces[country];
		if (placesForCountry) {
			[placesForCountry addObject:place];
		} else {
			placesForCountry = [[NSMutableArray alloc] initWithObjects:place, nil];
		}
		self.topPlaces[country] = placesForCountry;
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.topPlaces count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [self.topPlaces allKeys][section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.topPlaces[[self.topPlaces allKeys][section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Top Place" forIndexPath:indexPath];

	NSDictionary *place = self.topPlaces[[self.topPlaces allKeys][indexPath.section]][indexPath.row];
	cell.textLabel.text = [FlickrFetcher extractCityFromPlaceName:place[FLICKR_PLACE_NAME]];
	cell.detailTextLabel.text = [FlickrFetcher extractDetailFromPlaceName:place[FLICKR_PLACE_NAME]];

    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
	if (![sender isKindOfClass:[UITableViewCell class]]
		|| ![segue.identifier isEqualToString:@"Show Photos For Place"]
		|| ![segue.destinationViewController isKindOfClass:[PhotoListTableViewController class]]
		|| !indexPath) {
		return;
	}

	NSString *placeID = self.topPlaces[[self.topPlaces allKeys][indexPath.section]][indexPath.row][FLICKR_PLACE_ID];
	segue.destinationViewController.title = ((UITableViewCell *)sender).textLabel.text;
	((PhotoListTableViewController *)segue.destinationViewController).URL = [FlickrFetcher URLforPhotosInPlace:placeID maxResults:50];
}

@end

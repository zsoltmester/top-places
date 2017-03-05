//
//  TopPlacesTableViewController.m
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 04..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import "TopPlacesTableViewController.h"
#import "FlickrFetcher.h"

@interface TopPlacesTableViewController ()

@property (nonatomic, strong) NSMutableDictionary *topPlaces;

@end

@implementation TopPlacesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[self downloadTopPlaces];
}

- (IBAction)downloadTopPlaces
{
	[self.refreshControl beginRefreshing];
	NSURLRequest *request = [NSURLRequest requestWithURL:[FlickrFetcher URLforTopPlaces]];
	NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
	NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
	NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
													completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
														if (error) {
															NSLog(@"[ERROR] Failed to download the top places: %@", error);
															return;
														}
														NSData *resultsJSON = [NSData dataWithContentsOfURL:location];
														NSDictionary *results = [NSJSONSerialization JSONObjectWithData:resultsJSON options:0 error:NULL];
														[self handleTopPlacesResponse:results];
													}];
	[task resume];
}

- (void)handleTopPlacesResponse:(NSDictionary *)response
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
	[self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
}

- (void)updateUI
{
	[self.refreshControl endRefreshing];
	[self.tableView reloadData];
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
    return [[self.topPlaces objectForKey:[[self.topPlaces allKeys] objectAtIndex:section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Top Place" forIndexPath:indexPath];

	NSDictionary *place = [[self.topPlaces objectForKey:[[self.topPlaces allKeys] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
	cell.textLabel.text = [FlickrFetcher extractCityFromPlaceName:place[FLICKR_PLACE_NAME]];
	cell.detailTextLabel.text = [FlickrFetcher extractDetailFromPlaceName:place[FLICKR_PLACE_NAME]];

    return cell;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

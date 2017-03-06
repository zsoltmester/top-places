//
//  PhotoListTableViewController.m
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 06..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import "PhotoListTableViewController.h"
#import "FlickrFetcher.h"

@interface PhotoListTableViewController ()

@property (nonatomic, strong) NSArray *photos;

@end

@implementation PhotoListTableViewController

- (void)handleResponse:(NSDictionary *)response
{
	self.photos = [response valueForKeyPath:FLICKR_RESULTS_PHOTOS];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.photos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Photo" forIndexPath:indexPath];

	NSDictionary *photo = self.photos[indexPath.row];
	cell.textLabel.text = photo[FLICKR_PHOTO_TITLE];
	if ([cell.textLabel.text isEqualToString:@""]) {
		cell.textLabel.text = @"(Unknown)";
	}
	cell.detailTextLabel.text = [photo valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];

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

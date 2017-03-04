//
//  ViewController.m
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 04..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import "ViewController.h"
#import "FlickrFetcher.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

	NSData *topPlacesJSON = [NSData dataWithContentsOfURL:[FlickrFetcher URLforTopPlaces]];
	NSDictionary *topPlaces = [NSJSONSerialization JSONObjectWithData:topPlacesJSON options:0 error:NULL];
	NSLog(@"%@", topPlaces.description);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


@end

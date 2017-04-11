//
//  NetworkBasedTableViewController.h
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 06..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DynamicTableViewController : UITableViewController

@property (nonatomic, strong) NSURL *URL;

- (void)handleResponse:(NSDictionary *)response; // abstract
- (void)updateUI;

@end

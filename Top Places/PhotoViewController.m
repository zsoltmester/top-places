//
//  PhotoViewController.m
//  Top Places
//
//  Created by Zsolt Mester on 2017. 03. 06..
//  Copyright © 2017. Zsolt Mester. All rights reserved.
//

#import "PhotoViewController.h"

@interface PhotoViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImage *image;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation PhotoViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.scrollView.delegate = self;
	self.scrollView.contentSize = CGSizeZero;
	self.scrollView.minimumZoomScale = 0.01;
	self.scrollView.maximumZoomScale = 10;

	self.imageView = [UIImageView new];
	[self.scrollView addSubview:self.imageView];

	[self downloadImage];
}

- (void)downloadImage
{
	NSURLRequest *request = [NSURLRequest requestWithURL:self.URL];
	NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
	NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
	NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
													completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
														if (error) {
															NSLog(@"[ERROR] Download failed with reason: %@", error);
															return;
														}
														self.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:location]];
														[self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
													}];
	[task resume];
}

- (void)updateUI
{
	self.imageView.image = self.image;
	self.imageView.frame = CGRectMake(0, 0, self.image.size.width, self.image.size.height);
	self.scrollView.contentSize = self.image.size;
	[self.scrollView zoomToRect:self.imageView.frame animated:NO];
	self.scrollView.minimumZoomScale = self.scrollView.zoomScale;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return self.imageView;
}

@end

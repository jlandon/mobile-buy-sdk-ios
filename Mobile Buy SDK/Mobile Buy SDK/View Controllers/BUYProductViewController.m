//
//  BUYProductViewController.m
//  Mobile Buy SDK
//
//  Created by Rune Madsen on 2015-07-07.
//  Copyright (c) 2015 Shopify Inc. All rights reserved.
//

#import "BUYGradientView.h"
#import "BUYImageView.h"
#import "BUYNavigationController.h"
#import "BUYPresentationControllerWithNavigationController.h"
#import "BUYProductViewController.h"
#import "BUYProductViewFooter.h"
#import "BUYProductViewHeader.h"
#import "BUYProductHeaderCell.h"
#import "BUYProductVariantCell.h"
#import "BUYProductDescriptionCell.h"

@interface BUYProductViewController () <UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate, UIAdaptivePresentationControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) BUYProductViewHeader *productViewHeader;
@property (nonatomic, strong) BUYProductViewFooter *productViewFooter;
@property (nonatomic, strong) BUYGradientView *topGradientView;

@property (nonatomic, strong) NSString *productId;
@property (nonatomic, strong) BUYProduct *product;
@property (nonatomic, strong) BUYProductVariant *selectedProductVariant;

@end

@implementation BUYProductViewController

- (instancetype)initWithShopDomain:(NSString *)shopDomain apiKey:(NSString *)apiKey channelId:(NSString *)channelId
{
	BUYClient *client = [[BUYClient alloc] initWithShopDomain:shopDomain apiKey:apiKey channelId:channelId];
	self = [self initWithClient:client];
	return self;
}

- (instancetype)initWithClient:(BUYClient *)client
{
	self = [super initWithClient:client];
	if (self) {
		self.view.backgroundColor = [UIColor clearColor];
		self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
		self.transitioningDelegate = self;
	}
	return self;
}

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
	BUYPresentationControllerWithNavigationController *presentationController = [[BUYPresentationControllerWithNavigationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
	presentationController.delegate = self;
	return presentationController;
}

- (void)loadProduct:(NSString *)productId completion:(void (^)(BOOL success, NSError *error))completion
{
	self.productId = productId;
	[self.client getProductById:productId completion:^(BUYProduct *product, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			self.product = product;
			self.selectedProductVariant = [self.product.variants firstObject];
			[self.productViewHeader.productImageView loadImageWithURL:[self imageSrcForVariant:self.selectedProductVariant]];
			[self.tableView reloadData];
			[self.productViewHeader setContentOffset:self.tableView.contentOffset];
			if (completion) {
				completion(error == nil, error);
			}
		});
	}];
}

- (void)loadView {
	[super loadView];
	
	self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
	self.tableView.estimatedRowHeight = 60.0;
	self.tableView.rowHeight = UITableViewAutomaticDimension;
	self.tableView.tableFooterView = [UIView new];
	[self.view addSubview:self.tableView];
	
	[self.tableView registerClass:[BUYProductHeaderCell class] forCellReuseIdentifier:@"Cell"];
	[self.tableView registerClass:[BUYProductVariantCell class] forCellReuseIdentifier:@"variantCell"];
	[self.tableView registerClass:[BUYProductDescriptionCell class] forCellReuseIdentifier:@"descriptionCell"];
	
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_tableView]|"
																	  options:0
																	  metrics:nil
																		views:NSDictionaryOfVariableBindings(_tableView)]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_tableView]|"
																	  options:0
																	  metrics:nil
																		views:NSDictionaryOfVariableBindings(_tableView)]];
	
	self.productViewHeader = [[BUYProductViewHeader alloc] init];
	[self.productViewHeader setFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), CGRectGetWidth([[UIScreen mainScreen] bounds]))];
	self.tableView.tableHeaderView = self.productViewHeader;
	
	self.productViewFooter = [[BUYProductViewFooter alloc] init];
	self.productViewFooter.translatesAutoresizingMaskIntoConstraints = NO;
	[self.productViewFooter.buyPaymentButton addTarget:self action:@selector(checkoutWithApplePay) forControlEvents:UIControlEventTouchUpInside];
	[self.productViewFooter.checkoutButton addTarget:self action:@selector(checkoutWithShopify) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:self.productViewFooter];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_productViewFooter]|"
																	  options:0
																	  metrics:nil
																		views:NSDictionaryOfVariableBindings(_productViewFooter)]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_productViewFooter(60)]|"
																	  options:0
																	  metrics:nil
																		views:NSDictionaryOfVariableBindings(_productViewFooter)]];
	[self.productViewFooter setApplePayButtonVisible:self.isApplePayAvailable];
	
	
	self.topGradientView = [[BUYGradientView alloc] init];
	self.topGradientView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:self.topGradientView];
	
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_topGradientView]|"
																	  options:0
																	  metrics:nil
																		views:NSDictionaryOfVariableBindings(_topGradientView)]];
	[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.topGradientView
														  attribute:NSLayoutAttributeTop
														  relatedBy:NSLayoutRelationEqual
															 toItem:self.view
														  attribute:NSLayoutAttributeTop
														 multiplier:1.0
														   constant:0]];
	[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.topGradientView
														  attribute:NSLayoutAttributeHeight
														  relatedBy:NSLayoutRelationEqual
															 toItem:nil
														  attribute:NSLayoutAttributeNotAnAttribute
														 multiplier:1.0
														   constant:64]];
}

- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	self.tableView.separatorInset = self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, CGRectGetHeight(self.productViewFooter.frame), self.tableView.contentInset.right);
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// Return the number of sections.
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.product ? 3 : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == 0) {
		BUYProductHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
		cell.titleLabel.text = self.product.title;
		cell.priceLabel.text = @"$9.99";
		return cell;
	}
	else if (indexPath.row == 1) {
		BUYProductVariantCell *cell = [tableView dequeueReusableCellWithIdentifier:@"variantCell"];
		cell.productVariant = self.selectedProductVariant;
		return cell;
	}
	else {
		BUYProductDescriptionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"descriptionCell"];
		cell.descriptionHTML = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce non eleifend lectus, nec efficitur velit. Etiam ligula elit, sagittis at velit ac, vehicula efficitur nulla. Vivamus nec nulla vel lacus sollicitudin bibendum. Mauris mattis neque eu arcu scelerisque blandit condimentum vehicula eros. Suspendisse potenti. Proin ornare ut augue eu posuere. Ut volutpat, massa a tempor suscipit, enim augue sodales nulla, non efficitur urna magna vel nunc. Aenean commodo turpis nec orci consectetur, luctus suscipit purus laoreet. Phasellus mi nisi, viverra eu diam in, scelerisque tempor velit. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nunc ut tristique arcu, in scelerisque diam. Sed sem dolor, euismod tristique maximus a, viverra sed metus. Donec ex nisi, facilisis at lacus condimentum, vulputate malesuada turpis.\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce non eleifend lectus, nec efficitur velit. Etiam ligula elit, sagittis at velit ac, vehicula efficitur nulla. Vivamus nec nulla vel lacus sollicitudin bibendum. Mauris mattis neque eu arcu scelerisque blandit condimentum vehicula eros. Suspendisse potenti. Proin ornare ut augue eu posuere. Ut volutpat, massa a tempor suscipit, enim augue sodales nulla, non efficitur urna magna vel nunc. Aenean commodo turpis nec orci consectetur, luctus suscipit purus laoreet. Phasellus mi nisi, viverra eu diam in, scelerisque tempor velit. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nunc ut tristique arcu, in scelerisque diam. Sed sem dolor, euismod tristique maximus a, viverra sed metus. Donec ex nisi, facilisis at lacus condimentum, vulputate malesuada turpis.";// self.product.htmlDescription;
		cell.separatorInset = UIEdgeInsetsMake(0, CGRectGetWidth(self.tableView.bounds), 0, 0);
		return cell;
	}
}

#pragma mark Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self.productViewHeader setContentOffset:scrollView.contentOffset];
}

- (NSURL*)imageSrcForVariant:(BUYProductVariant*)productVariant {
	for (BUYImage *image in productVariant.product.images) {
		for (NSNumber *variantId in image.variantIds) {
			if ([variantId isEqualToNumber:productVariant.identifier]) {
				return [NSURL URLWithString:image.src];
			}
		}
	}
	return nil;
}

#pragma mark Checkout

- (BUYCart*)cart
{
	BUYCart *cart = [[BUYCart alloc] init];
	[cart addVariant:self.selectedProductVariant];
	return cart;
}

- (void)checkoutWithApplePay
{
	[self startApplePayCheckoutWithCart:[self cart]];
}

- (void)checkoutWithShopify
{
	[self startWebCheckoutWithCart:[self cart]];
}

#pragma mark UIStatusBar appearance

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
	return UIStatusBarAnimationFade;
}

@end

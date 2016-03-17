//
//  FavouriteViewController.h
//  Weather App
//
//  Created by Mac-Mini-2 on 15/03/16.
//  Copyright © 2016 Mac-Mini-2. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FavouriteViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UISearchResultsUpdating,UISearchControllerDelegate,UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet UIView *setting;
@property (weak, nonatomic) IBOutlet UISegmentedControl *unit;
@property (strong, nonatomic) IBOutlet UISearchController *search;
@property FavouriteViewController *searchResultsController;

- (IBAction)setUnit:(UISegmentedControl *)sender;

@property BOOL searchIsActive;
@property BOOL searchIsFirstResponder;

@end

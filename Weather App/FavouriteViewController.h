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

- (IBAction)setUnit:(UISegmentedControl *)sender;

@property (strong, nonatomic) IBOutlet UISearchController *search;


@end

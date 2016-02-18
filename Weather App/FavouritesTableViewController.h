//
//  FavouritesTableViewController.h
//  Weather App
//
//  Created by Mac-Mini-2 on 05/02/16.
//  Copyright © 2016 Mac-Mini-2. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>


@class ViewController;
@class FavouritesTableViewController;

@protocol FavouritesTableViewControllerDelegate<NSObject>

- (void)senDetailsViewController:(FavouritesTableViewController *)controller didFinishEnteringItem:(NSDictionary *)item;

@end

@interface FavouritesTableViewController : UITableViewController <UISearchControllerDelegate,UISearchBarDelegate,UITableViewDataSource,UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UISearchController *search;
@property (nonatomic, weak) id <FavouritesTableViewControllerDelegate> delegate;

@end

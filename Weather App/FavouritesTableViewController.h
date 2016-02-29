//
//  FavouritesTableViewController.h
//  Weather App
//
//  Created by Mac-Mini-2 on 05/02/16.
//  Copyright © 2016 Mac-Mini-2. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface FavouritesTableViewController : UITableViewController <UISearchControllerDelegate,UISearchBarDelegate,UITableViewDataSource,UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UISearchController *search;

- (IBAction)setToCelcius:(UIButton *)sender;
- (IBAction)setToFarenheit:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIButton *setCel;
@property (weak, nonatomic) IBOutlet UIButton *setFarenheit;

@end

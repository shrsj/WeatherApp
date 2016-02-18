//
//  ForecastViewController.h
//  Weather App
//
//  Created by Mac-Mini-2 on 10/02/16.
//  Copyright © 2016 Mac-Mini-2. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ForecastViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *place;
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property NSString *Area;
@property NSString *Country;

@end

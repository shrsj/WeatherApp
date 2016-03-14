//
//  ForecastViewController.h
//  Weather App
//
//  Created by Mac-Mini-2 on 10/02/16.
//  Copyright © 2016 Mac-Mini-2. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Reachability.h"

@interface ForecastViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *weatherLabel;
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *tempLabel;

@property (weak, nonatomic) IBOutlet UILabel *place;
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property NSString *area;
@property NSString *latitude;
@property NSString *longitude;
@property NSString *tempf;
@property NSString *tempc;
@property NSString *weatherType;

@end

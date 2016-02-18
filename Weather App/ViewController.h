//
//  ViewController.h
//  Weather App
//
//  Created by Mac-Mini-2 on 01/02/16.
//  Copyright © 2016 Mac-Mini-2. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "FavouritesTableViewController.h"

@interface ViewController : UIViewController <CLLocationManagerDelegate,FavouritesTableViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *weatherIcon;
@property (weak, nonatomic) IBOutlet UILabel *Place;
@property (weak, nonatomic) IBOutlet UILabel *Temperature;
@property (weak, nonatomic) IBOutlet UILabel *unit;
@property (weak, nonatomic) IBOutlet UILabel *weatherText;
@property (weak, nonatomic) IBOutlet UITextView *Info;
@property (weak, nonatomic) IBOutlet UILabel *summary;

@property (strong,nonatomic) NSString *longitude;
@property (strong,nonatomic) NSString *latitude;
@property (strong,nonatomic) NSString *locationName;
@property BOOL setLocation;




@property (weak, nonatomic) IBOutlet UIScrollView *scroll;


- (IBAction)forecast:(UIButton *)sender;
- (IBAction)Share:(UIButton *)sender;
- (IBAction)history:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activIndicator;

- (IBAction)favbutton:(id)sender;

@end


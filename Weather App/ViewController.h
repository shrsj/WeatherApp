//
//  ViewController.h
//  Weather App
//
//  Created by Mac-Mini-2 on 01/02/16.
//  Copyright © 2016 Mac-Mini-2. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Reachability.h"


@interface ViewController : UIViewController <CLLocationManagerDelegate>


@property (weak, nonatomic) IBOutlet UIImageView *weatherIcon;
@property (weak, nonatomic) IBOutlet UILabel *place;
@property (weak, nonatomic) IBOutlet UILabel *temperature;
@property (weak, nonatomic) IBOutlet UILabel *weatherText;
@property (weak, nonatomic) IBOutlet UITextView *info;
@property (weak, nonatomic) IBOutlet UILabel *summary;
@property (weak, nonatomic) IBOutlet UILabel *tempUnit;

//passing data for location
@property (strong,nonatomic) NSString *longitude;
@property (strong,nonatomic) NSString *latitude;
@property (strong,nonatomic) NSString *locationName;
@property BOOL setLocation;

//images
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *blurredImageView;
@property (nonatomic, assign) CGFloat screenHeight;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activIndicator;
@property (weak, nonatomic) IBOutlet UIScrollView *scroll;


- (IBAction)forecast:(UIButton *)sender;
- (IBAction)Share:(UIButton *)sender;


- (IBAction)favbutton:(id)sender;

@end


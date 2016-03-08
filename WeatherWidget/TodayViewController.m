//
//  TodayViewController.m
//  WeatherWidget
//
//  Created by Mac-Mini-2 on 08/03/16.
//  Copyright © 2016 Mac-Mini-2. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#define API_KEY @"b706ffe1f894f6be"

@interface TodayViewController () <NCWidgetProviding>
{
    CLLocationManager *locationManager;
    NSDictionary *json;
    NSString *Area;
    NSString *weatherType;
    NSString *currentTemp_f;
    NSString *currentTemp_c;
    NSString *latitude;
    NSString *longitude;
    
    
    BOOL resultsUpdated;
    BOOL metric;
    BOOL interfaceupdate;
    
}
@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.SJI.Weather-App"];
    [defaults synchronize];
    locationManager = [CLLocationManager new];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    [locationManager requestAlwaysAuthorization];
    [locationManager startUpdatingLocation];
    self.preferredContentSize = CGSizeMake(0, 70);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets
{
    defaultMarginInsets.bottom = 10.0f;
    return defaultMarginInsets;
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData
    [locationManager startUpdatingLocation];
    if (resultsUpdated)
    {
        [self UpdateInterface];
        resultsUpdated = NO;
        completionHandler(NCUpdateResultNewData);
    }
    else
    {
        completionHandler(NCUpdateResultNoData);
    }
}
#pragma mark CLLocationManger Delegate method


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *currentLocation = [locations lastObject];
    NSLog(@"longi is %f",currentLocation.coordinate.latitude);
    NSLog(@"%f",currentLocation.coordinate.longitude);
    NSString *lat = [NSString stringWithFormat:@"%f",currentLocation.coordinate.latitude];
    NSString *longi= [NSString stringWithFormat:@"%f",currentLocation.coordinate.longitude];
    [self weatherDetails:lat longitude:longi];
}

-(void)weatherDetails:(NSString *)lat
            longitude:(NSString *)longi
{
    [locationManager stopUpdatingLocation];
    NSURLSession *session = [NSURLSession sharedSession];
    NSString *ApiCall = [NSString stringWithFormat:@"https://api.wunderground.com/api/%@/conditions/q/%@,%@.json",API_KEY,lat,longi];
    NSString* encodedUrl = [ApiCall stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:encodedUrl] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        if (data)
        {
            json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSDictionary *conditions = [json objectForKey:@"current_observation"];
            NSDictionary *placemark = [conditions objectForKey:@"display_location"];
            weatherType = [conditions objectForKey:@"icon"];
            currentTemp_f = [NSString stringWithFormat:@"%@",[conditions objectForKey:@"temp_f"]];
            currentTemp_c = [NSString stringWithFormat:@"%@",[conditions objectForKey:@"temp_c"]];
            Area = [placemark objectForKey:@"full"];
            resultsUpdated = YES;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self UpdateInterface];
            });
        }
    }];
    [dataTask resume];
}

-(void)UpdateInterface
{
    self.icon.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@",weatherType]];
    if (metric)
    {
        self.temperature.text = [NSString stringWithFormat:@"%@ ℃",currentTemp_c];
    }
    else
    {
        self.temperature.text = [NSString stringWithFormat:@"%@ ℉",currentTemp_f];
    }
    self.Condition.text = weatherType;
    self.place.text = Area;
}

@end

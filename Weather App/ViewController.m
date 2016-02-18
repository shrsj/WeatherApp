//
//  ViewController.m
//  Weather App
//
//  Created by Mac-Mini-2 on 01/02/16.
//  Copyright © 2016 Mac-Mini-2. All rights reserved.
//

#import "ViewController.h"
#import "ForecastViewController.h"
#import <Social/Social.h>

@interface ViewController () <FavouritesTableViewControllerDelegate>
{
    CLLocationManager *locationManager;
    NSMutableData *responseData;
    NSDictionary *json;
    NSDictionary *conditions;
    
    //Current Observation
    NSString *full;
    NSString *weatherType;
    NSString *icon;
    NSString *humidity;
    NSString *windString;
    NSString *precipitation_string;
    NSString *visibilityString;
    
    NSString *currentTemp_f;
    NSString *currentTemp_c;
    NSString *feels_f;
    NSString *feels_c;
    NSString *heatIndex_f;
    NSString *heatIndex_c;
    
    //forecast
    NSDictionary *forecastDict;
    NSInteger *maxTemp;
    NSInteger *minTemp;
    NSString *sumary;
    
    
    //Hourly
    NSArray *hourlyForecast;
    NSString *hourTime;
    NSString *hourly_Temp_c;
    NSString *hourly_Temp_f;
    NSString *hourly_icon;
    NSString *hourly_condition;
    
    //geolocation
    NSString *Area;
    NSString *Country;
    //Error messages
    NSString *errorMsg;
    NSString *errorType;
    
    BOOL Metric;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    locationManager = [CLLocationManager new];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    FavouritesTableViewController *faVC = [[FavouritesTableViewController alloc] init];
    faVC.delegate = self;
    
    [locationManager requestAlwaysAuthorization];
    
    if (self.setLocation)
    {
        [self weatherDetails:self.latitude longitude:self.longitude];
    }
    else
    {
        [locationManager startUpdatingLocation];
    }
    self.activIndicator.center = self.view.center;
    [self.view addSubview:self.activIndicator];
    [self.activIndicator startAnimating];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    if (self.setLocation)
    {
        [self weatherDetails:self.latitude longitude:self.longitude];
    }
    else
    {
        [locationManager startUpdatingLocation];
    }
}

#pragma mark Weather Forecast

-(void)weatherDetails:(NSString *)lat
            longitude:(NSString *)longi
{
    //[self.activIndicator startAnimating];
    NSURLSession *session = [NSURLSession sharedSession];
    NSString *ApiCall = [NSString stringWithFormat:@"https://api.wunderground.com/api/cdad743a382da6d1/hourly/forecast/conditions/q/%@,%@.json",lat,longi];
    NSString* encodedUrl = [ApiCall stringByAddingPercentEscapesUsingEncoding:
                            NSUTF8StringEncoding];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:encodedUrl] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        if (data)
        {
            json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            conditions = [json objectForKey:@"current_observation"];
            if (conditions == NULL)
            {
                NSDictionary *response = [json objectForKey:@"response"];
                NSDictionary *error = [response objectForKey:@"error"];
                errorMsg = [error objectForKey:@"description"];
                errorType = [error objectForKey:@"type"];
                [self performSelectorOnMainThread:@selector(displayAlert) withObject:NULL waitUntilDone:YES];
            }
            
            //Location Display
            NSDictionary *placemark = [conditions objectForKey:@"display_location"];
            full = [placemark objectForKey:@"full"];
            
            // Display Current Temperatures
            weatherType = [conditions objectForKey:@"icon"];
            humidity = [conditions objectForKey:@"relative_humidity"];
            icon = [conditions objectForKey:@"icon_url"];
            windString = [conditions objectForKey:@"wind_string"];
            precipitation_string = [conditions objectForKey:@"precip_today_string"];
            visibilityString = [NSString stringWithFormat:@"is upto %@ Kms / %@ Miles.",[conditions objectForKey:@"visibility_km"],[conditions objectForKey:@"visibility_mi"]];
            
            currentTemp_f = [conditions objectForKey:@"temp_f"];
            currentTemp_c = [conditions objectForKey:@"temp_c"];
            feels_f = [conditions objectForKey:@"feelslike_f"];
            feels_c = [conditions objectForKey:@"feelslike_c"];
            heatIndex_f = [conditions objectForKey:@"heat_index_f"];
            heatIndex_c = [conditions objectForKey:@"heat_index_c"];
            
            
            //Forecast
            forecastDict = [json objectForKey:@"forecast"];
            NSDictionary *txtForecast = [forecastDict objectForKey:@"txt_forecast"];
            NSArray *forecastday = [txtForecast objectForKey:@"forecastday"];
            sumary = [forecastday[0] valueForKey:@"fcttext_metric"];
            
            //NSDictionary *simpleForecast = [forecastDict objectForKey:@"simpleforecast"];
            //NSArray *sForecastday = [txtForecast objectForKey:@"forecastday"];
            
            //hourly
            hourlyForecast = [json objectForKey:@"hourly_forecast"];
            
            [self performSelectorOnMainThread:@selector(updateInfo) withObject:NULL waitUntilDone:NO];
        }
        else
        {
            NSLog(@"no data");
        }
    }];
    [dataTask resume];
}
#pragma mark View Update Methods

-(void)createScroll :(NSArray *)forecast
{
    ////scroll properties
    
    NSInteger hours = 24,width = 0;
    float labelwidth = 100.0f;
    self.scroll.contentSize = CGSizeMake((labelwidth * hours), 100);
    UIView *hourlyScroll = [[UIView alloc] initWithFrame:CGRectMake(0, 0, (labelwidth*hours), 80)];
    hourlyScroll.backgroundColor = [UIColor clearColor];
    
    for(int i = 0; i < hours; i++)
    {
        NSArray *timings = [forecast[i] valueForKey:@"FCTTIME"];
        
        //time label
        UILabel *time =  [[UILabel alloc] initWithFrame: CGRectMake(width,0,labelwidth,14)];
        time.textAlignment = NSTextAlignmentCenter;
        time.adjustsFontSizeToFitWidth = YES;
        time.text = [NSString stringWithFormat:@"%@",[timings valueForKey:@"civil"]]; //etc...
        [time sizeToFit]; // resize the width and height to fit the text
        time.backgroundColor = [UIColor clearColor];
        
        //image icons
        NSString *imageN = [NSString stringWithFormat:@"%@",[forecast[i] valueForKey:@"icon"]];
        UIImage *myShot = [UIImage imageNamed:imageN];
        UIImageView *myImageView = [[UIImageView alloc] initWithImage:myShot];
        CGRect myFrame = CGRectMake(width , 16.0f, labelwidth,40);
        [myImageView setFrame:myFrame];
        
        //If your image is bigger than the frame then you can scale it
        [myImageView setContentMode:UIViewContentModeScaleAspectFit];
        
        
        //max min
        UILabel *labelMaxMin =  [[UILabel alloc] initWithFrame: CGRectMake(width,56,labelwidth,14)];
        labelMaxMin.adjustsFontSizeToFitWidth = YES;
        labelMaxMin.textAlignment = NSTextAlignmentCenter;
        NSDictionary *temp = [forecast[i] valueForKey:@"temp"];
        NSString *temp_c = [temp valueForKey:@"metric"];
        NSString *temp_f = [temp valueForKey:@"english"];
        
        if (Metric)
        {
            NSString *tempt = temp_c;
            labelMaxMin.text = [NSString stringWithFormat:@" %@ ℃",tempt]; //etc...[forecast[i] valueForKey:@"condition"],
        }
        else
        {
            NSString *tempt = temp_f;
            labelMaxMin.text = [NSString stringWithFormat:@" %@ ℉",tempt]; //etc...[forecast[i] valueForKey:@"condition"],
        }
        
        labelMaxMin.backgroundColor = [UIColor clearColor];
        
        
        width+=labelwidth;
        [hourlyScroll addSubview:time];
        [hourlyScroll addSubview:myImageView];
        [hourlyScroll addSubview:labelMaxMin];
    }
    [self.scroll addSubview:hourlyScroll];
}


-(void)updateInfo
{
    [self.activIndicator stopAnimating];
    [self.activIndicator removeFromSuperview];
    self.Place.text = full;
    if (Metric)
    {
        self.Temperature.text = [NSString stringWithFormat:@"%@",currentTemp_c];
        self.Info.text = [NSString stringWithFormat:@"Humidity : %@\nFeels Like : %@\nHeat Index : %@\nWind Conditions : %@\nPrecipitation : %@\nVisibility : %@\n",humidity,feels_c,heatIndex_c,windString,precipitation_string,visibilityString];
    }
    else
    {
        self.Temperature.text = [NSString stringWithFormat:@"%@",currentTemp_f];
        self.Info.text = [NSString stringWithFormat:@"Humidity : %@\nFeels Like : %@\nHeat Index : %@\nWind Conditions : %@\nPrecipitation : %@\nVisibility : %@\n",humidity,feels_f,heatIndex_f,windString,precipitation_string,visibilityString];
    }
    self.weatherText.text = weatherType;
    self.Info.textColor = [UIColor whiteColor];
    
    self.weatherIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@",weatherType]];
    self.summary.text = sumary;
    [self createScroll:hourlyForecast];
}

#pragma mark CLLocationManger Delegate method

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *currentLocation = [locations lastObject];
    [locationManager stopUpdatingLocation];
    NSLog(@"%f",currentLocation.coordinate.latitude);
    NSLog(@"%f",currentLocation.coordinate.longitude);
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init] ;
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error)
     {
         if (!(error))
         {
             CLPlacemark *placemark = [placemarks objectAtIndex:0];
             Area = [[NSString alloc]initWithString:placemark.locality];
             Country = [[NSString alloc]initWithString:placemark.country];
             NSString *lt = [NSString stringWithFormat:@"%f",currentLocation.coordinate.latitude];
             NSString *lng = [NSString stringWithFormat:@"%f",currentLocation.coordinate.longitude];
             [self weatherDetails:lt longitude:lng];
         }
         else
         {
             NSLog(@"Geocode failed with error %@", error);
             NSLog(@"\nCurrent Location Not Detected\n");
             return;
         }
     }];
}


- (IBAction)favbutton:(id)sender
{
    FavouritesTableViewController *faVC = [[FavouritesTableViewController alloc] init];
    faVC.delegate = self;
    [[self navigationController] pushViewController:faVC animated:YES];
}

-(void) displayAlert
{
    NSString *msg = @"Oops....";
    NSString *fullMessage = [NSString stringWithFormat:@"%@ %@\n %@",msg,errorMsg,errorType];
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"RSS Feeds"
                                  message:fullMessage
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"OK"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [alert dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    
    [alert addAction:ok];
    
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)forecast:(UIButton *)sender
{
    ForecastViewController *sendDetails = [[ForecastViewController alloc] init];
    NSArray *seperate = [full componentsSeparatedByString:@", "];
    Area = seperate[0];
    Country = seperate[1];
    sendDetails.Area = Area;
    sendDetails.Country = Country;
    
}

- (IBAction)Share:(UIButton *)sender
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        SLComposeViewController *vc = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        NSString *status = [NSString stringWithFormat:@"Hi, Here's what You got for todays weather %@",sumary];
        [vc setInitialText:status];
        [vc addImage:[UIImage imageNamed:icon]];
        [self presentViewController:vc animated:YES completion:nil];
    }
    else
    {
        NSString *message = @"It seems that we cannot talk to Facebook at the moment or you have not yet added your Facebook account to this device. Go to the Settings application to add your Facebook account to this device.";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    ForecastViewController *sendDetails = segue.destinationViewController;
    if ([[segue identifier] isEqualToString:@"forecast"])
    {
        sendDetails.Area = Area;
        sendDetails.Country = Country;
    }
}


- (IBAction)history:(UIButton *)sender {
}

-(void)senDetailsViewController:(FavouritesTableViewController *)controller didFinishEnteringItem:(NSDictionary *)item
{
    self.latitude = [item valueForKey:@"lat"];
    self.longitude = [item valueForKey:@"long"];
    self.locationName = [item valueForKey:@"name"];
    self.setLocation = YES;
}

@end



/* if([NSThread isMainThread])
 {
 NSLog(@"Running on main Thread");
 
 }
 else{
 NSLog(@"no main thread");
 }
 */
/*---- For more results
 placemark.region);
 placemark.country);
 placemark.locality);
 placemark.name);
 placemark.ocean);
 placemark.postalCode);
 placemark.subLocality);
 placemark.location);
 ------*/
/*
 CLLocation *loca = [[CLLocation alloc] init];
 NSLog(@"\nCurrent Location Detected\n");
 NSString *locatedAt = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
 NSString *Address = [[NSString alloc]initWithString:locatedAt];
 loca = placemark.location;
 CLLocationCoordinate2D coordinate = loca.coordinate;
 float longitude = coordinate.longitude;
 float latitude = coordinate.latitude;
 */


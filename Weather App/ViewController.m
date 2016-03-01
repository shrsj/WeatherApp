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

#define API_KEY @"b706ffe1f894f6be"
#define API_KEY2 @"cdad743a382da6d1"

@interface ViewController () 
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
    
    //response from Core Data
    NSMutableArray *cd_array;
    
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
    
    //get from Core Data
    NSMutableArray *presentConditions;
    NSMutableArray *allLocations;
    NSMutableArray *place;
    NSMutableArray *lats;
    NSMutableArray *longs;
    NSString *visited;
    NSDate *lastVisited;
    
    BOOL Metric;
    BOOL infoUpdated;
    
    UIColor *fontColor;
    UIImage *background;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    locationManager = [CLLocationManager new];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    [locationManager requestAlwaysAuthorization];
    
    fontColor = [UIColor whiteColor];
    self.screenHeight = [UIScreen mainScreen].bounds.size.height;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *check = [defaults objectForKey:@"favSet"];
    
    if ([check isEqualToString:@"clear"]) {
        self.setLocation = NO;
    }
    else
    {
        [self getAllLocations];
        self.setLocation = YES;
        self.locationName = check;
        NSUInteger storedIndex = [place indexOfObject:check];
        self.latitude = [lats objectAtIndex:storedIndex];
        self.longitude = [longs objectAtIndex:storedIndex];
        NSLog(@"%lu %@ %@",(unsigned long)storedIndex,self.latitude,self.longitude);
        NSLog(@"%@ %@",place,check);
    }
    
    Metric = [defaults boolForKey:@"metric"];
    infoUpdated = NO;
    NSString *dated = [defaults objectForKey:@"lastVisited"];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"dd MM yyyy ZZZZ"];
    lastVisited = [format dateFromString:dated];
    
    Reachability *reach = [Reachability reachabilityWithHostName:@"www.google.com"];
    NSInteger x = [reach currentReachabilityStatus];
    self.activIndicator.center = self.view.center;
    [self.view addSubview:self.activIndicator];
    [self.activIndicator startAnimating];
    
    if (self.setLocation)
    {
        if (x > 0)
        {
            [self weatherDetails:self.latitude longitude:self.longitude];
        }
        else
        {
            [self getData];
            if ([presentConditions count] != 0) {
                
                [self UpdateFromDB];
                [self updateInfo];
            }
            else
            {
                errorMsg = @"Data unavailable.\nPlease ensure You are connected to the Network";
                [self performSelectorOnMainThread:@selector(displayAlert) withObject:NULL waitUntilDone:YES];
            }
        }
        [reach startNotifier];
    }
    else
    {
        if (x > 0)
        {
            [locationManager startUpdatingLocation];
        }
        else
        {
            self.locationName = [defaults objectForKey:@"location"];
            [self getData];
            
            if ([presentConditions count] != 0) {
                [self UpdateFromDB];
                [self updateInfo];
            }
            else
            {
                errorMsg = @"Oops!! Data unavailable.\nPlease ensure we are connected to the Network";
                [self displayAlert];
            }
        }
        [reach startNotifier];
    }
}
-(void)viewWillDisappear:(BOOL)animated
{
    infoUpdated = NO;
}

#pragma mark Weather Forecast
//when network is present
-(void)weatherDetails:(NSString *)lat
            longitude:(NSString *)longi
{
    [locationManager stopUpdatingLocation];
    NSURLSession *session = [NSURLSession sharedSession];
    NSString *ApiCall = [NSString stringWithFormat:@"https://api.wunderground.com/api/%@/hourly/forecast/conditions/q/%@,%@.json",API_KEY,lat,longi];
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
                errorMsg = [NSString stringWithFormat:@"%@,\n%@",[error objectForKey:@"description"],[error objectForKey:@"type"]];
                [self performSelectorOnMainThread:@selector(displayAlert) withObject:NULL waitUntilDone:YES];
            }
            
            //Location Display
            NSDictionary *placemark = [conditions objectForKey:@"display_location"];
            if (self.setLocation) {
                full = self.locationName;
            }
            else
            {
                full = [placemark objectForKey:@"full"];
            }
            // Display Current Temperatures
            weatherType = [conditions objectForKey:@"icon"];
            humidity = [conditions objectForKey:@"relative_humidity"];
            windString = [conditions objectForKey:@"wind_string"];
            precipitation_string = [conditions objectForKey:@"precip_today_string"];
            visibilityString = [NSString stringWithFormat:@"is upto %@ Kms / %@ Miles.",[conditions objectForKey:@"visibility_km"],[conditions objectForKey:@"visibility_mi"]];
            
            currentTemp_f = [NSString stringWithFormat:@"%@",[conditions objectForKey:@"temp_f"]];
            currentTemp_c = [NSString stringWithFormat:@"%@",[conditions objectForKey:@"temp_c"]];
            feels_f = [NSString stringWithFormat:@"%@",[conditions objectForKey:@"feelslike_f"]];
            feels_c = [NSString stringWithFormat:@"%@",[conditions objectForKey:@"feelslike_c"]];
            heatIndex_f = [NSString stringWithFormat:@"%@",[conditions objectForKey:@"heat_index_f"]];
            heatIndex_c = [NSString stringWithFormat:@"%@",[conditions objectForKey:@"heat_index_c"]];
            
            //Forecast
            forecastDict = [json objectForKey:@"forecast"];
            NSDictionary *txtForecast = [forecastDict objectForKey:@"txt_forecast"];
            NSArray *forecastday = [txtForecast objectForKey:@"forecastday"];
            sumary = [forecastday[0] valueForKey:@"fcttext_metric"];
            
            //hourly
            hourlyForecast = [json objectForKey:@"hourly_forecast"];
            if (!infoUpdated ) {
                [self performSelectorOnMainThread:@selector(updateInfo) withObject:NULL waitUntilDone:NO];
                [self performSelectorOnMainThread:@selector(createScroll) withObject:NULL waitUntilDone:NO];
            }
            NSUInteger entries = [self getCount];
            long diff = [self daysBetween:lastVisited and:[NSDate date]];
            if (entries == 0)
            {
                [self insertData];
            }
            else
            {
                if (diff > 1 )
                {
                    [self deleteData];
                    [self insertData];
                }
            }
        }
        else
        {
            NSLog(@"no data");
        }
    }];
    [dataTask resume];
}
#pragma mark View Update Methods

-(void)createScroll
{
    ////scroll properties
    
    NSInteger hours = 24,width = 0;
    float labelwidth = 100.0f;
    self.scroll.contentSize = CGSizeMake((labelwidth * hours), 80);
    self.scroll.backgroundColor = [UIColor clearColor];
    
    for (UIView *subview in self.scroll.subviews)
    {
        [subview removeFromSuperview];
    }
    
    UIView *hourlyScroll = [[UIView alloc] init];
    hourlyScroll.frame = CGRectMake(0, 0, (labelwidth*hours), 80);
    hourlyScroll.backgroundColor = [UIColor clearColor];
    
    for(int i = 0; i < hours; i++)
    {
        NSArray *timings = [hourlyForecast[i] valueForKey:@"FCTTIME"];
        
        //time label
        UILabel *time =  [[UILabel alloc] initWithFrame: CGRectMake(width,2,labelwidth,16)];
        time.textAlignment = NSTextAlignmentCenter;
        time.textColor = fontColor;
        time.text = nil;
        [time setFont:[UIFont systemFontOfSize:10]];
        time.backgroundColor = [UIColor clearColor];
        
        time.text = [NSString stringWithFormat:@"%@",[timings valueForKey:@"civil"]]; //etc...
        
        //image icons
        NSString *imageN = [NSString stringWithFormat:@"%@",[hourlyForecast[i] valueForKey:@"icon"]];
        UIImage *myShot = [[UIImage alloc] init];
        myShot = [UIImage imageNamed:imageN];
        UIImageView *myImageView = [[UIImageView alloc] initWithImage:myShot];
        CGRect myFrame = CGRectMake(width , 20, labelwidth,40);
        [myImageView setFrame:myFrame];
        
        [myImageView setContentMode:UIViewContentModeScaleAspectFit];
        
        UILabel *labelMaxMin =  [[UILabel alloc] initWithFrame: CGRectMake(width,62,labelwidth,14)];
        labelMaxMin.text = @"";
        labelMaxMin.adjustsFontSizeToFitWidth = YES;
        labelMaxMin.textColor = fontColor;
        labelMaxMin.textAlignment = NSTextAlignmentCenter;
        [labelMaxMin setFont:[UIFont systemFontOfSize:10]];
        NSDictionary *temp = [hourlyForecast[i] valueForKey:@"temp"];
        NSString *temp_c = [temp valueForKey:@"metric"];
        NSString *temp_f = [temp valueForKey:@"english"];
        
        if (Metric)
        {
            NSString *tempt = temp_c;
            labelMaxMin.text = [NSString stringWithFormat:@" %@ ℃",tempt];
        }
        else
        {
            NSString *tempt = temp_f;
            labelMaxMin.text = [NSString stringWithFormat:@" %@ ℉",tempt];
        }
        labelMaxMin.backgroundColor = [UIColor clearColor];
        width+=labelwidth;
        
        [hourlyScroll addSubview:time];
        [hourlyScroll addSubview:myImageView];
        [hourlyScroll addSubview:labelMaxMin];
    }
    infoUpdated = YES;
    [self.scroll addSubview:hourlyScroll];
}


-(void)updateInfo
{
    [self.activIndicator stopAnimating];
    [self.activIndicator removeFromSuperview];
    self.Place.text = full;
    if (self.setLocation) {
        self.locationName = self.locationName;
    }
    else
    {
        self.locationName = full;
        
    }
    if (Metric)
    {
        NSString *tempc = currentTemp_c;
        if (tempc.length > 1) {
            tempc = [tempc substringToIndex:2];
        }
        
        self.Temperature.text = [NSString stringWithFormat:@"%@",tempc];
        self.tempUnit.text = @"℃";
        self.Info.text = [NSString stringWithFormat:@"Humidity : %@\nFeels Like : %@℃\nHeat Index : %@℃\nWind Conditions : %@\nPrecipitation : %@\nVisibility : %@\n",humidity,feels_c,heatIndex_c,windString,precipitation_string,visibilityString];
    }
    else
    {
        NSString *tempf = currentTemp_f;
        if (tempf.length > 1) {
            tempf = [tempf substringToIndex:2];
        }
        self.Temperature.text = [NSString stringWithFormat:@"%@",tempf];
        self.tempUnit.text = @"℉";
        self.Info.text = [NSString stringWithFormat:@"Humidity : %@\nFeels Like : %@℉\nHeat Index : %@℉\nWind Conditions : %@\nPrecipitation : %@\nVisibility : %@\n",humidity,feels_f,heatIndex_f,windString,precipitation_string,visibilityString];
    }
    self.weatherText.text = weatherType;
    self.Info.textColor = [UIColor whiteColor];
    
    self.weatherIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@",weatherType]];
    self.summary.text = sumary;
    
    [self saveAppDetails];
    
}
//When network doesnt exist update from db
-(void)UpdateFromDB
{
    NSManagedObject *show = [presentConditions objectAtIndex:0];
    full = [show valueForKey:@"place"];
    
    // Display Current Temperatures
    weatherType = [show valueForKey:@"weather"];
    humidity = [show valueForKey:@"humidity"];
    windString = [show valueForKey:@"wind"];
    precipitation_string = [show valueForKey:@"precip"];
    visibilityString = [show valueForKey:@"visibility"];
    
    currentTemp_f = [show valueForKey:@"tempf"];
    currentTemp_c = [show valueForKey:@"tempc"];
    feels_f = [show valueForKey:@"feelsf"];
    feels_c = [show valueForKey:@"feelsc"];
    heatIndex_f = [show valueForKey:@"heatf"];
    heatIndex_c = [show valueForKey:@"heatc"];
    sumary = [show valueForKey:@"summary"];
}

#pragma mark CLLocationManger Delegate method


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *currentLocation = [locations lastObject];
    NSLog(@"longi is %f",currentLocation.coordinate.latitude);
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
             self.latitude = lt;
             self.longitude = lng;
             [self weatherDetails:lt longitude:lng];
         }
         else
         {
             NSLog(@"Geocode failed with error %@", error);
             NSLog(@"\nCurrent Location Not Detected\n");
             return;
         }
     }];
    [locationManager stopUpdatingLocation];
}


#pragma mark Core data functions

- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)getAllLocations
{
    NSManagedObjectContext *managedObjContext = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Place"];
    allLocations = [[managedObjContext executeFetchRequest:request error:nil] mutableCopy];
    
    place = [[NSMutableArray alloc] init];
    lats = [[NSMutableArray alloc] init];
    longs = [[NSMutableArray alloc] init];
    
    for (NSManagedObject *location in allLocations)
    {
        [place addObject:[location valueForKey:@"placeName"]];
        [lats addObject:[location valueForKey:@"latitude"]];
        [longs addObject:[location valueForKey:@"longitude"]];
    }
}
-(NSUInteger)getCount
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"PresentConditions"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"place = %@", self.locationName]];
    [request setFetchLimit:1];
    NSUInteger count = [context countForFetchRequest:request error:&error];
    if (count == NSNotFound)
    {
        errorMsg = @"some error occured while accessing data";
        [self displayAlert];
        return 0;
    }
    else if (count == 0)
    {
        return 0;
    }
    else
    {
        return count;
    }
}

-(void)deleteData
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *all = [[NSFetchRequest alloc] init];
    [all setEntity:[NSEntityDescription entityForName:@"PresentConditions" inManagedObjectContext:context]];
    [all setIncludesPropertyValues:NO];
    [all setPredicate:[NSPredicate predicateWithFormat:@"place == %@",_locationName]];
    NSError *error = nil;
    NSArray *data = [context executeFetchRequest:all error:&error];
    
    for (NSManagedObject *conditn in data) {
        [context deleteObject:conditn];
    }
    if ([context save:&error] == NO) {
        NSAssert(NO, @"Save should not fail\n%@", [error localizedDescription]);
        abort();
    }
}

-(void)insertData
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSManagedObjectModel *condition = [NSEntityDescription insertNewObjectForEntityForName:@"PresentConditions" inManagedObjectContext:context];
    
    //Insert new updated info
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"EEEE, dd : MMMM : yyyy"];
    date = [dateFormat dateFromString:[dateFormat stringFromDate:[NSDate date]]];
    
    NSLog(@"inserted data for location %@ ",full);
    [condition setValue:date forKey:@"day"];
    [condition setValue:feels_f forKey:@"feelsf"];
    [condition setValue:feels_c forKey:@"feelsc"];
    [condition setValue:heatIndex_c forKey:@"heatc"];
    [condition setValue:heatIndex_f forKey:@"heatf"];
    [condition setValue:humidity forKey:@"humidity"];
    [condition setValue:full forKey:@"place"];
    [condition setValue:precipitation_string forKey:@"precip"];
    [condition setValue:sumary forKey:@"summary"];
    [condition setValue:currentTemp_f forKey:@"tempf"];
    [condition setValue:currentTemp_c forKey:@"tempc"];
    [condition setValue:visibilityString forKey:@"visibility"];
    [condition setValue:weatherType forKey:@"weather"];
    [condition setValue:windString forKey:@"wind"];
    NSError *error = nil;
    
    error = nil;
    // Save the object to persistent store
    if (![context save:&error])
    {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
}

-(void)getData
{
    NSManagedObjectContext *managedObjContext = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"PresentConditions"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"place == %@",self.locationName]];
    presentConditions = [[managedObjContext executeFetchRequest:request error:nil] mutableCopy];
}

#pragma mark button actions

-(void) displayAlert
{
    NSString *msg = @"Oops....";
    NSString *fullMessage = [NSString stringWithFormat:@"%@\n %@",msg,errorMsg];
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

- (IBAction)favbutton:(id)sender
{
    FavouritesTableViewController *faVC = [self.storyboard instantiateViewControllerWithIdentifier:@"fvController"];
    [self.navigationController pushViewController:faVC animated:YES];
}

- (IBAction)forecast:(UIButton *)sender
{
}

- (IBAction)Share:(UIButton *)sender
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        SLComposeViewController *vc = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        NSString *status = [NSString stringWithFormat:@"Hi, Here's what You got for todays weather %@",sumary];
        [vc setInitialText:status];
        [vc addImage:[UIImage imageNamed:weatherType]];
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
        sendDetails.Area = self.locationName;
        sendDetails.longitude = self.longitude;
        sendDetails.latitude = self.latitude;
        sendDetails.tempf = currentTemp_f;
        sendDetails.tempc = currentTemp_c;
        sendDetails.weatherType = weatherType;
    }
}

#pragma mark UserDefaults

-(void)saveAppDetails
{
    // Store the data
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"dd MM yyyy ZZZZ"];
    visited = [format stringFromDate:[NSDate date]];
    
    [defaults setObject:self.locationName forKey:@"location"];
    [defaults setObject:self.latitude forKey:@"latitude"];
    [defaults setObject:self.longitude forKey:@"longitude"];
    [defaults setObject:visited forKey:@"lastVisited"];
    
    [defaults synchronize];
    
    NSLog(@"Data saved");
}

- (long)daysBetween:(NSDate *)dt1 and:(NSDate *)dt2 {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:dt1 toDate:dt2 options:0];
    return [components day]+1;
}
-(void)checkDayTime
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH.mm"];
    NSString *strCurrentTime = [dateFormatter stringFromDate:[NSDate date]];
    
    NSLog(@"Check float value: %.2f",[strCurrentTime floatValue]);
    if ([strCurrentTime floatValue] >= 18.00 || [strCurrentTime floatValue]  <= 6.00)
    {
        NSLog(@"It's night time");
        background = [UIImage imageNamed:@"znight"];
    }else{
        NSLog(@"It's day time");
        background = [UIImage imageNamed:@"znight"];
    }
}

@end


/*
 ForecastViewController *sendDetails = [[ForecastViewController alloc] init];
 NSArray *seperate = [full componentsSeparatedByString:@", "];
 Area = seperate[0];
 Country = seperate[1];
 sendDetails.Area = Area;
 sendDetails.Country = Country;
 NSLog(@"%@%@",self.longitude,self.latitude);
 
 sendDetails.longitude = lt;
 sendDetails.latitude = ln;*/
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


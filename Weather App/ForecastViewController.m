//
//  ForecastViewController.m
//  Weather App
//
//  Created by Mac-Mini-2 on 10/02/16.
//  Copyright © 2016 Mac-Mini-2. All rights reserved.
//

#import "ForecastViewController.h"

@interface ForecastViewController ()
{
    NSDictionary *Forecast;
    NSDictionary *jsonf;
    NSArray *simpleForecast;
    NSArray *details;
    NSMutableArray *forecastConditions;
    
    NSString *errorType;
    NSString *errorMsg;
    NSInteger count;
    
    NSString *locationName;
    
    BOOL metric;
    BOOL reachable;
}
@end

@implementation ForecastViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.table.delegate = self;
    self.table.dataSource = self;
    self.place.text = [NSString stringWithFormat:@"%@, %@",self.Area,self.Country];
    locationName = [NSString stringWithFormat:@"%@, %@",self.Area,self.Country];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    metric = [defaults boolForKey:@"metric"];
    Reachability *reach = [Reachability reachabilityWithHostName:@"www.google.com"];
    NSInteger x = [reach currentReachabilityStatus];
    if (x > 0)
    {
        reachable = YES;
        NSLog(@"%@, %@",self.latitude,self.longitude);
        [self getForecast:self.latitude longitudes:self.longitude];
        
    }
    else
    {
        reachable = NO;
        [self getData];
        errorMsg = @"Because of unavailability of Network Realtime information wont be available.";
        [self performSelectorOnMainThread:@selector(displayAlert) withObject:NULL waitUntilDone:YES];
    }
    [reach startNotifier];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)getForecast:(NSString *)latitude
        longitudes:(NSString *)longitude
{
    [self.activityIndicator startAnimating];
    [self.view addSubview:self.activityIndicator];
    NSURLSession *session = [NSURLSession sharedSession];
    NSString *ApiCall = [NSString stringWithFormat:@"https://api.wunderground.com/api/cdad743a382da6d1/forecast10day/q/%@,%@.json",latitude,longitude];
    NSString* encodedUrl = [ApiCall stringByAddingPercentEscapesUsingEncoding:
                            NSUTF8StringEncoding];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:encodedUrl] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        if (data)
        {
            jsonf = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            Forecast = [jsonf objectForKey:@"forecast"];
            NSDictionary *temp = [Forecast objectForKey:@"simpleforecast"];
            simpleForecast = [temp objectForKey:@"forecastday"];
            details = [simpleForecast valueForKey:@"date"];
            count = [simpleForecast count];
            [self UpdateData];
            
            [self.table performSelectorOnMainThread:@selector(reloadData) withObject:Nil waitUntilDone:NO];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.activityIndicator stopAnimating];
                [self.activityIndicator removeFromSuperview];
            });
            if (Forecast == NULL)
            {
                NSDictionary *response = [jsonf objectForKey:@"response"];
                NSDictionary *error = [response objectForKey:@"error"];
                errorMsg = [error objectForKey:@"description"];
                errorType = [error objectForKey:@"type"];
                [self performSelectorOnMainThread:@selector(displayAlert) withObject:NULL waitUntilDone:YES];
            }
        }
    }];
    [dataTask resume];
}

#pragma mark Core Data
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)UpdateData
{
    //deletes data since we have updated info
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *all = [[NSFetchRequest alloc] init];
    [all setEntity:[NSEntityDescription entityForName:@"Forecast" inManagedObjectContext:context]];
    [all setPredicate:[NSPredicate predicateWithFormat:@"location == %@",locationName]];
    
    NSError *error = nil;
    NSArray *data = [context executeFetchRequest:all error:&error];
    //error handling goes here
    for (NSManagedObject *conditn in data) {
        [context deleteObject:conditn];
    }
    if ([context save:&error] == NO) {
        NSAssert(NO, @"Save should not fail\n%@", [error localizedDescription]);
        abort();
    }
    //Insert new updated info
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd MM yyyy"];
    date = [dateFormat dateFromString:[dateFormat stringFromDate:[NSDate date]]];
    
    for (int i = 0; i< count; i++)
    {
        NSDictionary *tempohigh = [simpleForecast[i] valueForKey:@"high"];
        NSDictionary *tempolow = [simpleForecast[i] valueForKey:@"low"];
        
        NSString *weekday = [details[i] valueForKey:@"weekday"];
        NSString *maxfar = [NSString stringWithFormat:@"%@",[tempohigh objectForKey:@"fahrenheit"]];
        NSString *maxcel = [NSString stringWithFormat:@"%@",[tempohigh objectForKey:@"celsius"]];
        NSString *minfar = [NSString stringWithFormat:@"%@",[tempolow objectForKey:@"fahrenheit"]];
        NSString *mincel = [NSString stringWithFormat:@"%@",[tempolow objectForKey:@"celsius"]];
        NSString *averghum = [NSString stringWithFormat:@"%@",[simpleForecast[i] valueForKey:@"avehumidity"]];
        NSString *icon = [simpleForecast[i] valueForKey:@"icon"];
        NSString *conditions = [simpleForecast[i] valueForKey:@"conditions"];
        
        
        NSManagedObjectModel *condition = [NSEntityDescription insertNewObjectForEntityForName:@"Forecast" inManagedObjectContext:context];
        
        if (weekday != NULL) {
            [condition setValue:weekday forKey:@"day"];
        }
        if (maxfar != NULL) {
            [condition setValue:maxfar forKey:@"maxf"];
        }
        if (maxcel != NULL) {
            [condition setValue:maxcel forKey:@"maxc"];
        }
        if ( minfar != NULL) {
            [condition setValue:minfar forKey:@"minf"];
        }
        if (mincel != NULL) {
            [condition setValue:mincel forKey:@"minc"];
        }
        if (averghum != NULL) {
            [condition setValue:averghum forKey:@"humidity"];
        }
        if (locationName != NULL) {
            [condition setValue:locationName forKey:@"location"];
        }
        if (icon != NULL) {
            [condition setValue:icon forKey:@"icon"];
        }
        if (conditions != NULL) {
            [condition setValue:conditions forKey:@"condition"];
        }
        
        error = nil;
        // Save the object to persistent store
        if (![context save:&error])
        {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }
    }
}

-(void)getData
{
    NSManagedObjectContext *managedObjContext = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Forecast"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"location == %@",locationName]];
    forecastConditions = [[NSMutableArray alloc]init];
    forecastConditions = [[managedObjContext executeFetchRequest:request error:nil] mutableCopy];
    count = [forecastConditions count];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
        [self.activityIndicator removeFromSuperview];
        [self.table reloadData];
    });
}

#pragma mark TableView Delegate Methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return count;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80.0f;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * identifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    UILabel *Day = (UILabel *)[cell viewWithTag:101];
    UILabel *Conditions = (UILabel *)[cell viewWithTag:102];
    UIImageView *icon = (UIImageView *)[cell viewWithTag:103];
    UILabel *temp = (UILabel *)[cell viewWithTag:104];
    NSString *high;
    NSString *low;
    
    if (reachable)
    {
        Day.text = [details[indexPath.row] valueForKey:@"weekday"];
        Conditions.text = [simpleForecast[indexPath.row] valueForKey:@"conditions"];
        NSString *imageN = [simpleForecast[indexPath.row] valueForKey:@"icon"];
        NSDictionary *tempohigh = [simpleForecast[indexPath.row] valueForKey:@"high"];
        NSDictionary *tempolow = [simpleForecast[indexPath.row] valueForKey:@"low"];
        if (metric)
        {
            high = [tempohigh objectForKey:@"fahrenheit"];
            low = [tempolow objectForKey:@"fahrenheit"];
        }
        else
        {
            high = [tempohigh objectForKey:@"celsius"];
            low = [tempolow objectForKey:@"celsius"];
        }
        temp.text = [NSString stringWithFormat:@"Max %@, Min %@",high,low];
        UIImage *myShot = [UIImage imageNamed:imageN];
        icon.image = myShot;
    }
    else
    {
        NSManagedObject *fore = forecastConditions[indexPath.row];
        Day.text = [fore valueForKey:@"day"];
        Conditions.text = [fore valueForKey:@"condition"];
        NSString *imageN = [fore valueForKey:@"icon"];
        if(metric)
        {
            high = [fore valueForKey:@"maxc"];
            low = [fore valueForKey:@"minc"];
        }
        else{
            high = [fore valueForKey:@"maxf"];
            low = [fore valueForKey:@"minf"];
        }
        temp.text = [NSString stringWithFormat:@"Max %@, Min %@",high,low];
        icon.image = [UIImage imageNamed:imageN];
    }
    
    /*CGRect myFrame = CGRectMake(250, 6, 70, 60);
     [icon setFrame:myFrame];
     [cell addSubview:Day];
     [cell addSubview:Conditions];
     [cell addSubview:temp];
     [cell addSubview:icon];*/
    return cell;
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

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end

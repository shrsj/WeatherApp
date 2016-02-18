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
    
    NSString *errorType;
    NSString *errorMsg;
    NSInteger count;
    
    BOOL metric;
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
    
    [self getForecast:self.Area countryName:self.Country];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)getForecast:(NSString *)area
       countryName:(NSString *)country
{
    [self.activityIndicator startAnimating];
    [self.view addSubview:self.activityIndicator];
    NSURLSession *session = [NSURLSession sharedSession];
    NSString *ApiCall = [NSString stringWithFormat:@"https://api.wunderground.com/api/cdad743a382da6d1/forecast10day/q/%@/%@.json",country,area];
    NSString* encodedUrl = [ApiCall stringByAddingPercentEscapesUsingEncoding:
                            NSUTF8StringEncoding];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:encodedUrl] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        if (data)
        {
            jsonf = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            Forecast = [jsonf objectForKey:@"forecast"];
            NSDictionary *temp = [Forecast objectForKey:@"simpleforecast"];
            simpleForecast = [temp objectForKey:@"forecastday"];
            count = [simpleForecast count];
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
    // If I have available a cell with this identifier: secondReusableIdentifier, let's go to use it.
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil){
        // If not, we create a new cell with this identifier. This methods is previous to storyboard, and this methods create a new cell, but does´t look in Storyboard if this identifier exist, or something like that.
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    NSArray *details = [simpleForecast valueForKey:@"date"];
    //UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    UILabel *Day = (UILabel *)[cell viewWithTag:101];
    Day.text = [details[indexPath.row] valueForKey:@"weekday"];
    
    
    UILabel *Conditions = (UILabel *)[cell viewWithTag:102];
    Conditions.text = [simpleForecast[indexPath.row] valueForKey:@"conditions"];
    
    
    UIImageView *icon = (UIImageView *)[cell viewWithTag:103];
    NSString *imageN = [simpleForecast[indexPath.row] valueForKey:@"icon"];
    UIImage *myShot = [UIImage imageNamed:imageN];
    icon.image = myShot;
    
    UILabel *temp = (UILabel *)[cell viewWithTag:104];
    NSDictionary *tempohigh = [simpleForecast[indexPath.row] valueForKey:@"high"];
    NSDictionary *tempolow = [simpleForecast[indexPath.row] valueForKey:@"low"];
    NSString *high;
    NSString *low;
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

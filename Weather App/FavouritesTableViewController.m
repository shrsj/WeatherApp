//
//  FavouritesTableViewController.m
//  Weather App
//
//  Created by Mac-Mini-2 on 05/02/16.
//  Copyright © 2016 Mac-Mini-2. All rights reserved.
//

#import "FavouritesTableViewController.h"
#import "ViewController.h"

@interface FavouritesTableViewController ()
{
    BOOL isFiltered;
    NSMutableDictionary *searchDetails;
    NSDictionary *searches;
    NSString *cityName;
    NSMutableArray *searchList;
    NSMutableArray *favLocations;
    
    NSMutableArray *conditions;
    NSString *weatherType;
    NSString *currentTemp;
    
    BOOL metric;
}

@end

@implementation FavouritesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.search.searchBar.delegate = self;
    favLocations = [[NSMutableArray alloc] init];
    searchList = [[NSMutableArray alloc]init];
    CGRect frame = CGRectMake(0, 504, self.view.bounds.size.width, 94);
    frame.origin.y = [UIScreen mainScreen].bounds.size.height -self.footers.frame.size.height;
    self.footers.frame = frame;
    [self.navigationController.view addSubview:self.footers];
    /* UILayoutGuide *margin = self.view.layoutMarginsGuide;
     [self.footers.bottomAnchor constraintEqualToAnchor:margin.bottomAnchor].active  = YES;
     
     [NSLayoutConstraint constraintWithItem:self.footers attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottomMargin multiplier:1.0 constant:0];
     self.footers.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;*/
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.SJI.Weather-App"];
    metric = [defaults boolForKey:@"metric"];
    if (metric)
    {
        self.selector.selectedSegmentIndex = 0;
    }
    else
    {
        self.selector.selectedSegmentIndex = 1;
    }
    [self getalldata];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.footers removeFromSuperview];
}

#pragma mark Coredata methods

- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)getalldata
{
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Place"];
    favLocations = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
}

-(void)getPresentConditions:(NSString *)locationName
{
    NSManagedObjectContext *cont = [self managedObjectContext];
    NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:@"PresentConditions"];
    [fetch setPredicate:[NSPredicate predicateWithFormat:@"place == %@",locationName]];
    conditions = [[NSMutableArray alloc] init];
    NSError *error = nil;
    conditions = [[cont executeFetchRequest:fetch error:&error] mutableCopy];
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(isFiltered == YES)
    {
        NSLog(@"count is %lu",(unsigned long)[searchList count]);
        return [searchList count];
    }
    else
    {
        NSInteger count =[favLocations count];
        return count;
    }
}

#pragma mark Table View Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self setSettingsView];
}
-(void)setSettingsView
{
    CGRect frame = self.footers.frame;
    frame.origin.y = self.tableView.frame.size.height -self.footers.frame.size.height;
    self.footers.frame = frame;
    [self.view bringSubviewToFront:self.footers];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    return 80;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObjectContext *context = [self managedObjectContext];
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [context deleteObject:[favLocations objectAtIndex:indexPath.row]];
        NSError *error = nil;
        if ([context save:&error] == NO) {
            NSAssert(NO, @"Save should not fail\n%@", [error localizedDescription]);
            abort();
        }
        [favLocations removeObjectAtIndex:[indexPath row]];
        [self.tableView reloadData];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
    }   
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    if (isFiltered == YES)
    {
        cell.textLabel.text = [searchList[indexPath.row] valueForKey:@"name"];
        cell.backgroundView = NULL;
    }
    else
    {
        if (!(favLocations == 0))
        {
            NSManagedObject *device = [favLocations objectAtIndex:indexPath.row];
            UILabel *name = (UILabel *)[cell viewWithTag:1];
            name.text = [device valueForKey:@"placeName"];
            UILabel *ll = (UILabel *)[cell viewWithTag:2];
            [self getPresentConditions:[device valueForKey:@"placeName"]];
            UIImageView *av = [[UIImageView alloc] init];
            av.backgroundColor = [UIColor clearColor];
            av.opaque = NO;
            if ([conditions count] != 0 )
            {
                NSManagedObject *detail = [conditions objectAtIndex:0];
                NSString *imgname = [self backgroundImage:[detail valueForKey:@"weather"]];
                av.image= [UIImage imageNamed:imgname];
                
                cell.backgroundView = av;
                if (metric)
                {
                    ll.text = [NSString stringWithFormat:@"%@ , %@℃",[detail valueForKey:@"weather"],[detail valueForKey:@"tempc"]];
                }
                else
                {
                    ll.text = [NSString stringWithFormat:@"%@ , %@℉",[detail valueForKey:@"weather"],[detail valueForKey:@"tempf"]];
                }
            }
            else
            {
                ll.text = @" ";
            }
        }
    }
    return cell;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    
    return @"Favourite Locations";
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (isFiltered == YES)
    {
        NSManagedObjectContext *context = [self managedObjectContext];
        NSManagedObjectModel *place = [NSEntityDescription insertNewObjectForEntityForName:@"Place" inManagedObjectContext:context];
        NSString *places =[searchList[indexPath.row] valueForKey:@"name"];
        if (![favLocations containsObject:places])
        {
            NSString *lati = [searchList[indexPath.row] valueForKey:@"lat"];
            NSString *longi = [searchList[indexPath.row] valueForKey:@"lon"];
            if (places != NULL && lati != NULL && longi != NULL)
            {
                [place setValue:places forKey:@"placeName"];
                [place setValue:lati forKey:@"latitude"];
                [place setValue:longi forKey:@"longitude"];
            }
            NSError *error = nil;
            // Save the object to persistent store
            if (![context save:&error]) {
                NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
            }
            [self.search setActive:NO];
            isFiltered = NO;
            [self getalldata];
            [self.tableView reloadData];
        }
        else
        {
            [self.search setActive:NO];
            isFiltered = NO;
            [self getalldata];
            [self.tableView reloadData];
        }
    }
    else if (isFiltered == NO)
    {
        if ([indexPath section] == 0) {
            NSManagedObject *device = [favLocations objectAtIndex:indexPath.row];
            NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.SJI.Weather-App"];
            [defaults setObject:[device valueForKey:@"placeName"] forKey:@"favSet"];
            [[self navigationController] popToRootViewControllerAnimated:YES];
        }
    }
}

#pragma mark - SearchBar Delegate Methods.

- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)searchText
{
    [favLocations removeAllObjects];
    if (searchText.length == 0)
    {
        //Set boolean flag
        isFiltered = NO;
    }
    else
    {
        isFiltered = YES;
        searchDetails = [[NSMutableDictionary alloc] init];
        cityName = @"name";
        NSString* encodedUrl = [searchText stringByAddingPercentEscapesUsingEncoding:
                                NSUTF8StringEncoding];
        
        [self locationSearchCall:encodedUrl];
        /* NSURLSession *session = [NSURLSession sharedSession];
         
         NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://autocomplete.wunderground.com/aq?query=%@",encodedUrl]] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
         {
         if (data.length > 0 && error == nil) {
         searches = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
         searchList = [searches objectForKey:@"RESULTS"];
         NSLog(@"reloading list");
         dispatch_async(dispatch_get_main_queue(),^{
         [self.tableView reloadData];
         });
         }
         }];
         [dataTask resume];
         */
    }
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    //searchList = nil;
    [searchList removeAllObjects];
    NSLog(@"%@",searchList);
    isFiltered = NO;
    [searchBar resignFirstResponder];
    [self getalldata];
    [self.tableView reloadData];
}

- (IBAction)selectUnit:(id)sender {
    if (self.selector.selectedSegmentIndex == 0)
    {
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.SJI.Weather-App"];
        [defaults setBool:YES forKey:@"metric"];
        metric = YES;
        [self.tableView reloadData];
        [[[sender subviews] objectAtIndex:0] setBackgroundColor:[UIColor clearColor]];
        [[[sender subviews] objectAtIndex:1] setBackgroundColor:[UIColor whiteColor]];
    }
    else if (self.selector.selectedSegmentIndex == 1)
    {
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.SJI.Weather-App"];
        [defaults setBool:NO forKey:@"metric"];
        metric = NO;
        [self.tableView reloadData];
        [[[sender subviews] objectAtIndex:1] setBackgroundColor:[UIColor clearColor]];
        [[[sender subviews] objectAtIndex:0] setBackgroundColor:[UIColor whiteColor]];        
    }
}

-(NSString *) backgroundImage:(NSString *)weatherStatus
{
    weatherStatus = [weatherStatus lowercaseString];
    NSString * string = [[NSString alloc] init];
    if([weatherStatus containsString:@"cloudy"] || [weatherStatus containsString:@"mostly cloudy"] || [weatherStatus containsString:@"partly"])
    {
        string = @"bgCloudy";
    }
    else if([weatherStatus containsString:@"clear"] || [weatherStatus containsString:@"sunny"])
    {
        string = @"bgClear";
    }
    else if([weatherStatus containsString:@"rain"] || [weatherStatus containsString:@"sleet"])
    {
        string = @"bgrainy";
    }
    else if([weatherStatus containsString:@"snow"] || [weatherStatus containsString:@"flurries"])
    {
        string = @"bgSnow";
    }
    else if ([weatherStatus containsString:@"hazy"] ||[weatherStatus containsString:@"fog"])
    {
        string = @"bgHazy";
    }
    else if ([weatherStatus containsString:@"storms"])
    {
        string = @"bglightning";
    }
    return string;
}

-(void) locationSearchCall: (NSString *)searchText
{
    NSString *urlString = [NSString stringWithFormat:@"https://autocomplete.wunderground.com/aq?query=%@",searchText];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue ]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data, NSError *connectionError)
     {
         if(data.length > 0 && connectionError == nil)
         {
             searches = [[NSMutableDictionary alloc] init];
             //   searchList = [[NSArray alloc] init];
             
             searches = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
             searchList =[[searches objectForKey:@"RESULTS"] mutableCopy];
             
             if([searchList count] > 0)
             {
                 [self.tableView reloadData];
             }
         }
     }];
}
@end


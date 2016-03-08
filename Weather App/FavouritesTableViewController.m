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
    NSArray *searchList;
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
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    CGRect frame = self.footers.frame;
    frame.origin.y = self.tableView.frame.size.height -self.footers.frame.size.height;
    self.footers.frame = frame;
    [self.navigationController.view addSubview:self.footers];
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.SJI.Weather-App"];
    metric = [defaults boolForKey:@"metric"];
    if (metric)
    {
        self.setCel.alpha = 1.0;
        self.setFarenheit.alpha = 0.5;
    }
    else
    {
        self.setFarenheit.alpha = 1.0;
        self.setCel.alpha = 0.5;
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
    if ([indexPath section] == 0)
    {
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        if (isFiltered == YES)
        {
            cell.textLabel.text = [searchList[indexPath.row] valueForKey:@"name"];
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
                if ([conditions count] != 0 )
                {
                    NSManagedObject *detail = [conditions objectAtIndex:0];
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
    else
    {
        static NSString *CellIdentifier = @"settingsCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        return cell;
    }
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
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[device valueForKey:@"placeName"] forKey:@"favSet"];
            [[self navigationController] popToRootViewControllerAnimated:YES];
        }
    }
}

#pragma mark - SearchBar Delegate Methods.

- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)searchText
{
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
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://autocomplete.wunderground.com/aq?query=%@",encodedUrl]] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            
            searches = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            searchList = [searches objectForKey:@"RESULTS"];
            NSLog(@"reloading list");
            dispatch_async(dispatch_get_main_queue(),^{
                [self.tableView reloadData];
            });
        }];
        [dataTask resume];
    }
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchList = nil;
    isFiltered = NO;
    dispatch_async(dispatch_get_main_queue(),^{
        [self.tableView reloadData];
    });
}
- (IBAction)setToCelcius:(UIButton *)sender {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.SJI.Weather-App"];
    [defaults setBool:YES forKey:@"metric"];
    self.setFarenheit.alpha = 0.5;
    self.setCel.alpha = 1.0;
    self.setCel.font = [UIFont boldSystemFontOfSize:20];
    self.setFarenheit.font = [UIFont systemFontOfSize:18];
    metric = YES;
    [self.tableView reloadData];
}

- (IBAction)setToFarenheit:(UIButton *)sender {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.SJI.Weather-App"];
    [defaults setBool:NO forKey:@"metric"];
    self.setFarenheit.alpha = 1.0;
    self.setCel.alpha = 0.5;
    self.setFarenheit.font = [UIFont boldSystemFontOfSize:20];
    self.setCel.font = [UIFont systemFontOfSize:18];
    metric = NO;
    [self.tableView reloadData];
}
@end


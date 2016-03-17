//
//  FavouriteViewController.m
//  Weather App
//
//  Created by Mac-Mini-2 on 15/03/16.
//  Copyright © 2016 Mac-Mini-2. All rights reserved.
//

#import "FavouriteViewController.h"
#import <CoreData/CoreData.h>

@interface FavouriteViewController ()
{
    BOOL filtered;
    BOOL metric;
    
    NSMutableArray *favList;
    NSMutableArray *searchList;
    NSMutableArray *conditions;
}
@end

@implementation FavouriteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.SJI.Weather-App"];
    metric = [defaults boolForKey:@"metric"];
    if (metric)
    {
        self.unit.selectedSegmentIndex = 0;
    }
    else
    {
        self.unit.selectedSegmentIndex = 1;
    }
    favList = [[NSMutableArray alloc] init];
    searchList = [[NSMutableArray alloc]init];
    self.table.dataSource = self;
    self.table.delegate = self;
    
    [self initSearch];
    [self getalldata];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // restore the searchController's active state
    if (self.searchIsActive) {
        self.search.active = self.searchIsActive;
        _searchIsActive = NO;
        
        if (self.searchIsFirstResponder) {
            [self.search.searchBar becomeFirstResponder];
            _searchIsFirstResponder = NO;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark UI Search methods

-(void) initSearch
{
    self.search = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.definesPresentationContext = NO;
    self.table.tableHeaderView = self.search.searchBar;
    self.search.searchResultsUpdater = self;
    self.search.searchBar.delegate = self;
    self.search.dimsBackgroundDuringPresentation = NO;
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = [self.search.searchBar text];
    
    if ([searchString length] == 0) {
        
        _searchIsFirstResponder = YES;
        return;
    }
    else if(searchString.length > 0)
    {
        _searchIsActive = YES;
        [self locationSearchCall:searchString];
    }
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    _searchIsActive = NO;
    _searchIsFirstResponder = NO;
    self.search.active = NO;
    [searchList removeAllObjects];
    [self getalldata];
    [self.table reloadData];
}

#pragma mark tableView delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"Favourite Locations";
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.search.active)
    {
        return [searchList count];
    }
    else
    {
        return [favList count];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObjectContext *context = [self managedObjectContext];
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [context deleteObject:[favList objectAtIndex:indexPath.row]];
        NSError *error = nil;
        if ([context save:&error] == NO) {
            NSAssert(NO, @"Save should not fail\n%@", [error localizedDescription]);
            abort();
        }
        [favList removeObjectAtIndex:[indexPath row]];
        [self.table reloadData];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL status = self.search.active;
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    if (status)
    {
        cell.textLabel.text = [searchList[indexPath.row] valueForKey:@"name"];
        cell.backgroundView = NULL;
        cell.detailTextLabel.text = @"";
    }
    else
    {
        if ([favList count] != 0)
        {
            NSManagedObject *locationDetail = [favList objectAtIndex:indexPath.row];
            cell.textLabel.text = [locationDetail valueForKey:@"placeName"];
            [self getPresentConditions:[locationDetail valueForKey:@"placeName"]];
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
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ , %@℃",[detail valueForKey:@"weather"],[detail valueForKey:@"tempc"]];
                }
                else
                {
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ , %@℉",[detail valueForKey:@"weather"],[detail valueForKey:@"tempf"]];
                }
            }
            else
            {
                cell.detailTextLabel.text = @" ";
            }
        }
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.search.active) {
        NSManagedObjectContext *context = [self managedObjectContext];
        NSManagedObjectModel *place = [NSEntityDescription insertNewObjectForEntityForName:@"Place" inManagedObjectContext:context];
        NSString *places =[searchList[indexPath.row] valueForKey:@"name"];
        if (![favList containsObject:places])
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
        }
        [self.search setActive:NO];
        filtered = NO;
        [self getalldata];
        [self.table reloadData];
        
    }
    else
    {
        NSManagedObject *device = [favList objectAtIndex:indexPath.row];
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.SJI.Weather-App"];
        [defaults setObject:[device valueForKey:@"placeName"] forKey:@"favSet"];
        [[self navigationController] popToRootViewControllerAnimated:YES];
    }
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

-(void)getalldata
{
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Place"];
    favList = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
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

#pragma mark methods

- (IBAction)setUnit:(UISegmentedControl *)sender {
    
    NSInteger num = sender.selectedSegmentIndex;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.SJI.Weather-App"];
    if (num == 0)
    {
        
        [defaults setBool:YES forKey:@"metric"];
        metric = YES;
        [self.table reloadData];
    }
    else if (num == 1)
    {
        [defaults setBool:NO forKey:@"metric"];
        metric = NO;
        [self.table reloadData];
    }
    else
    {
        metric = [defaults boolForKey:@"metric"];
        if (metric)
        {
            self.unit.selectedSegmentIndex = 0;
        }
        else
        {
            self.unit.selectedSegmentIndex = 1;
        }
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
    NSString* encoded = [searchText stringByAddingPercentEscapesUsingEncoding:
                         NSUTF8StringEncoding];
    NSString *urlString = [NSString stringWithFormat:@"https://autocomplete.wunderground.com/aq?query=%@",encoded];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue ]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data, NSError *connectionError)
     {
         if(data.length > 0 && connectionError == nil)
         {
             NSMutableDictionary *searches = [[NSMutableDictionary alloc] init];
             //   searchList = [[NSArray alloc] init];
             
             searches = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
             searchList =[[searches objectForKey:@"RESULTS"] mutableCopy];
             
             if([searchList count] > 0)
             {
                 [self.table reloadData];
             }
         }
     }];
}

@end

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
}

@end

@implementation FavouritesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.search.searchBar.delegate = self;
    favLocations = [[NSMutableArray alloc] init];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Fetch the devices from persistent data store
    [self getalldata];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
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
    }
    else
    {
        if (!(favLocations == 0))
        {
            //cell.textLabel.text = [favLocations[indexPath.row] valueForKey:@"name"];
            NSManagedObject *device = [favLocations objectAtIndex:indexPath.row];
            NSLog(@"%@ ",[device valueForKey:@"placeName"]);
            UILabel *name = (UILabel *)[cell viewWithTag:1];
            name.text = [device valueForKey:@"placeName"];
            UILabel *ll = (UILabel *)[cell viewWithTag:2];
            ll.text = [NSString stringWithFormat:@"%@ , %@",[device valueForKey:@"latitude"],[device valueForKey:@"longitude"]];
        }
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSManagedObjectModel *place = [NSEntityDescription insertNewObjectForEntityForName:@"Place" inManagedObjectContext:context];
    if (isFiltered == YES)
    {
        NSString *places =[searchList[indexPath.row] valueForKey:@"name"];
        if (![favLocations containsObject:places])
        {
            [place setValue:places forKey:@"placeName"];
            [place setValue:[searchList[indexPath.row] valueForKey:@"lat"] forKey:@"latitude"];
            [place setValue:[searchList[indexPath.row] valueForKey:@"lon"] forKey:@"longitude"];
            NSError *error = nil;
            // Save the object to persistent store
            if (![context save:&error]) {
                NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
            }
            [self.search setActive:NO];
            isFiltered = NO;
            [self.tableView reloadData];
        }
        else
        {
            [self.search setActive:NO];
            isFiltered = NO;
            [self.tableView reloadData];
        }
    }
    else if (isFiltered == NO)
    {
        NSManagedObject *device = [favLocations objectAtIndex:indexPath.row];
        NSMutableDictionary *send = [[NSMutableDictionary alloc] init];
        [send setObject:[device valueForKey:@"latitude"] forKey:@"lat"];
        [send setObject:[device valueForKey:@"longitude"] forKey:@"long"];
        [send setObject:[device valueForKey:@"placeName"] forKey:@"name"];
        ViewController *vc = [[ViewController alloc] init];
        vc.latitude = [device valueForKey:@"latitude"];
        vc.longitude = [device valueForKey:@"latitude"];
        vc.setLocation = YES;
        
        [self.navigationController popToRootViewControllerAnimated:YES];
        [self.delegate senDetailsViewController:self didFinishEnteringItem:send];
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

// Delete the row from the data source
//[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];


// Uncomment the following line to preserve selection between presentations.
// self.clearsSelectionOnViewWillAppear = NO;
// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
// self.navigationItem.rightBarButtonItem = self.editButtonItem;

/* NSManagedObjectContext *context = [self managedObjectContext];
 // Create a new managed object
 NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
 NSEntityDescription *entity = [NSEntityDescription
 entityForName:@"Place" inManagedObjectContext:context];
 [fetchRequest setEntity:entity];
 NSError *error = nil;
 NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
 for (NSManagedObject *locations in fetchedObjects)
 {
 NSString *location = [locations valueForKey:@"placeName"];
 NSString *lati = [locations valueForKey:@"latitude"];
 NSString *longi = [locations valueForKey:@"longitude"];
 NSMutableDictionary *locationDict = [[NSMutableDictionary alloc] init];
 
 [locationDict setObject:location forKey:@"location"];
 [locationDict setObject:lati forKey:@"latitude"];
 [locationDict setObject:longi forKey:@"longitude"];
 [favLocations addObject:locationDict];
 }
 NSLog(@"%lu %@",(unsigned long)[fetchedObjects count],favLocations);*/
/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end

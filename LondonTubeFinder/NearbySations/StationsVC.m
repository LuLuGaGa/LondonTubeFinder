//
//  StationsVC.m
//  LondonTubeFinder
//
//  Created by Lucyna Galik on 18/04/2018.
//  Copyright © 2018 Lucyna Galik. All rights reserved.
//

#import "StationsVC.h"
#import "Station.h"
#import "StationTableViewCell.h"
#import "StationDetailVC.h"


@interface StationsVC ()

@property (strong,  nonatomic)  NSMutableArray                   *stationsArray;
@property                       BOOL                             dowloadingStations;

@property (strong,  nonatomic)  UIRefreshControl                 *refreshStations;
@property (weak,    nonatomic)  IBOutlet UITableView             *tableView;
@property (weak,    nonatomic)  IBOutlet UIActivityIndicatorView *fetchingStationsSpinner;

@property (strong,  nonatomic)  CLLocationManager                *locationManager;
@property (strong,  nonatomic)  CLLocation                       *currentLocation;

@end

static NSString *const  kStationCellResusableIndentifier = @"stationCell";
static NSString *const  KStationDetailSegueIdentifier = @"stationDetail";

static double   const   kDefaultLatitude = 51.5076801;
static double   const   kDefaultLongitude = -0.1098001;
static NSString *const  kTubeLineNames = @"Bakerloo,Cable Car,Central,Circle,Crossrail,District,DLR,Hammersmith & City,Jubilee,Metropolitan,Northern,Overground,Piccadilly,Tramlink,Victoria,Waterloo & City";
static NSString *const  kFetchNearestTubeStationsURL = @"https://api.tfl.gov.uk/stoppoint?lat=%f&lon=%f&radius=2000&stoptypes=NaptanMetroStation&useStopPointHierarchy=false"; //needs latitude and longitude


@implementation StationsVC


#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.stationsArray = [[NSMutableArray alloc] init];
    
    self.refreshStations = [[UIRefreshControl alloc] init];
    self.refreshStations.tintColor = [UIColor colorNamed: @"Cable Car"];
    [self.refreshStations addTarget:self action:@selector(refreshStationsJSON) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = self.refreshStations;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    [self findCurrentLocation];
}


#pragma mark - Table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.stationsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    StationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: kStationCellResusableIndentifier];
    
    Station *station = self.stationsArray[indexPath.row];
    NSString *stationName = station.commonName;
    
    for (int i = 0; i < cell.linesOblongs.count; i++) {
        UIView *oblong = (UIView *) cell.linesOblongs[i];
        if (i < station.lineNames.count) {
            oblong.backgroundColor = [UIColor colorNamed: station.lineNames[i]];
        } else {
            oblong.backgroundColor = [UIColor clearColor];
        }
    }

    cell.stationNameLabel.text = stationName;
    cell.distanceLabel.text = [self textForDistanceLabel: station];
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier: KStationDetailSegueIdentifier sender:indexPath];
}

- (NSString *)textForDistanceLabel: (Station *) station  {
    int meters = station.distance;
    if (meters < 1000) {
        return [NSString stringWithFormat:@"%i m", meters];
    } else {
        return [NSString stringWithFormat:@"%.01f km", meters/1000.0];
    }
}


#pragma mark - JSON

- (void) fetchJSONFeed {
    if (!self.dowloadingStations) {
        self.dowloadingStations = YES;
        [self.fetchingStationsSpinner startAnimating];
        
        __block NSDictionary *jsonFeed = [[NSMutableDictionary alloc] init];
        __block NSMutableArray *fetchedStationsArray = [[NSMutableArray alloc] initWithCapacity:0];
        
        NSURLSession *session = [NSURLSession sharedSession];
        double lat = self.currentLocation.coordinate.latitude;
        double lon = self.currentLocation.coordinate.longitude;
        NSURL *apiURL = [NSURL URLWithString: [NSString stringWithFormat: kFetchNearestTubeStationsURL, lat, lon]];
        NSURLSessionDataTask *dataTask =
        [session dataTaskWithURL:apiURL
               completionHandler: ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                   jsonFeed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                   NSArray *stationFeed = [[NSArray alloc] initWithArray: jsonFeed[@"stopPoints"]];
                   NSArray *tubeLineNames = [kTubeLineNames componentsSeparatedByString:@","];
                   for (int i = 0; i < [stationFeed count]; i++) {
                       Station *station = [[Station alloc] init];
                       NSArray *lines = [stationFeed[i] valueForKey: @"lines"];
                       NSMutableArray *lineNames = [[NSMutableArray alloc] initWithCapacity:0];
                       for (int j = 0; j < [lines count]; j++) {
                           if ([tubeLineNames containsObject: [lines[j] valueForKey: @"name"]]) {
                               [lineNames addObject: [lines[j] valueForKey: @"name"]];
                           }
                       }
                       station.lineNames = [lineNames copy];
                       station.naptanId = [stationFeed[i] valueForKey: @"naptanId"];
                       station.commonName = [[[stationFeed[i] valueForKey: @"commonName"]  stringByReplacingOccurrencesOfString:@" Station" withString:@""] stringByReplacingOccurrencesOfString:@" Underground" withString:@""];
                       station.distance = (int)[[stationFeed[i] valueForKey: @"distance"] integerValue];
                       [fetchedStationsArray addObject: station];
                   }
                   
                   dispatch_async(dispatch_get_main_queue(), ^{
                       [self.stationsArray removeAllObjects];
                       self.stationsArray = [fetchedStationsArray mutableCopy];
                       
                       [self.tableView reloadData];
                       
                       [self.fetchingStationsSpinner stopAnimating];
                       self.dowloadingStations = NO;
                   });
               }];
        [dataTask resume];
    }
}

- (void) refreshStationsJSON {
    if (!self.dowloadingStations) {
        [self findCurrentLocation];
        [self.refreshStations endRefreshing];
    }
}


#pragma mark - Navigation

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString: KStationDetailSegueIdentifier]) {
        StationDetailVC *destination = segue.destinationViewController;
        if ([destination respondsToSelector:@selector(setNaptanId:)]) {
            NSIndexPath *indexPath = (NSIndexPath *)sender;
            Station *station = self.stationsArray[indexPath.row];
            destination.naptanId = station.naptanId;
            destination.stationName = station.commonName;
        }
    }
}


#pragma mark - Location

- (void) findCurrentLocation {
    
    if (nil == self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
    
    CLAuthorizationStatus authorisationSatus = CLLocationManager.authorizationStatus;
    self.currentLocation = [[CLLocation alloc] initWithLatitude: 0.0 longitude: 0.0];
    
    if (authorisationSatus == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    if (authorisationSatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager startUpdatingLocation];
    } else {
        //if no authorisation use default location
        self.currentLocation = [[CLLocation alloc] initWithLatitude: kDefaultLatitude longitude: kDefaultLongitude];
        [self fetchJSONFeed];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    self.currentLocation = [locations lastObject];
    if (self.currentLocation.coordinate.latitude != 0.0 && self.currentLocation.coordinate.longitude != 0.0) {
        if (![self isLondonLocation: self.currentLocation]) {
            //if not in London use default location
            self.currentLocation = [[CLLocation alloc] initWithLatitude: kDefaultLatitude longitude: kDefaultLongitude];
        }
        [self fetchJSONFeed];
        [self.locationManager stopUpdatingLocation];
    }
    
}

- (BOOL) isLondonLocation: (CLLocation *) location {
    return (location.coordinate.latitude < 51.68881 && location.coordinate.latitude > 51.29319 && location.coordinate.longitude > -0.49922 && location.coordinate.longitude < 0.32116);
}

@end

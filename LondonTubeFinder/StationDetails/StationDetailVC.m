//
//  StationDetailVC.m
//  LondonTubeFinder
//
//  Created by Lucyna Galik on 22/04/2018.
//  Copyright © 2018 Lucyna Galik. All rights reserved.
//

#import "StationDetailVC.h"
#import "FacilitiesCollectionViewCell.h"
#import "Train.h"
#import "TrainsTableViewCell.h"
#import "FacilityVC.h"


@interface StationDetailVC ()

@property (strong,  nonatomic) NSMutableArray   *trainsArray;
@property (strong,  nonatomic) NSMutableArray   *facilitiesArray;
@property                      BOOL             dowmloadingTrains;

@property (weak,    nonatomic) IBOutlet UICollectionView        *collectionView;
@property (weak,    nonatomic) IBOutlet UITableView             *tableView;
@property (weak,    nonatomic) IBOutlet UIActivityIndicatorView *fetchingFacilitiesSpinner;
@property (weak,    nonatomic) IBOutlet UIActivityIndicatorView *fetchingTrainsSpinner;
@property (strong,  nonatomic) UIRefreshControl                 *refreshTrains;

@property (strong,  nonatomic) NSTimer          *timer;

@end

static NSString *const  kTrainCellResusableIndentifier = @"trainCell";
static NSString *const  kFacilitiesCellResusableIndentifier = @"facilitiesCell";
static NSString *const  kFacilityDetailSegueIdentifier = @"facilityDetail";

static double   const   kRefreshTime = 30.0; //in seconds

static NSString *const  kFetchArrivalsForStationURL = @"https://api.tfl.gov.uk/StopPoint/%@/Arrivals"; //needs station's naptanId
static NSString *const  kFetchFacilitiesForStationURL = @"https://api.tfl.gov.uk/Stoppoint/%@"; //needs station's naptanId

@implementation StationDetailVC


#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.stationName;
    
    self.trainsArray = [[NSMutableArray alloc] initWithCapacity:0];
    self.facilitiesArray = [[NSMutableArray alloc] initWithCapacity:0];
    
    [self fetchFacilitiesForStation: self.naptanId];
    
    
    self.refreshTrains = [[UIRefreshControl alloc] init];
    self.refreshTrains.tintColor = [UIColor colorNamed: @"Cable Car"];
    [self.refreshTrains addTarget:self action:@selector(refreshTrainsJSON) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = self.refreshTrains;
    
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    [self fetchTrainsForStation: self.naptanId];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
    
    [self.timer invalidate];
}


#pragma mark - JSONs

- (void) fetchFacilitiesForStation:(NSString*) naptanID {
    [self.fetchingFacilitiesSpinner startAnimating];
    
    __block NSDictionary *jsonFeed = [[NSDictionary alloc] init];
    [self.facilitiesArray removeAllObjects];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *apiURL = [NSURL URLWithString: [NSString stringWithFormat: kFetchFacilitiesForStationURL, self.naptanId]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:apiURL
                                            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                jsonFeed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                NSArray *facilitiesFeed = [[NSArray alloc] initWithArray: jsonFeed[@"additionalProperties"]];
                for (int i = 0; i < [facilitiesFeed count]; i++) {
                    NSDictionary *property = facilitiesFeed[i];
                    if ([[property valueForKey: @"category"]  isEqual: @"Facility"]) {
                        // ignore facilities that are not in the station
                        if (![[property valueForKey: @"value"] isEqual: @"no"] && ![[property valueForKey: @"value"] isEqual: @"0"]) {
                            [self.facilitiesArray addObject: [property valueForKey: @"key"]];
                        }
                    }
                }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
            
            [self.fetchingFacilitiesSpinner stopAnimating];
        });
    }];
    [dataTask resume];
}



- (void) fetchTrainsForStation:(NSString*) naptanID {
    if (!self.dowmloadingTrains) {
        self.dowmloadingTrains = YES;
        [self.fetchingTrainsSpinner startAnimating];
        
        __block NSArray *jsonFeed = [[NSArray alloc] init];
        __block NSMutableArray *fetchedTrainsArray = [[NSMutableArray alloc] initWithCapacity:0];
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURL *apiURL = [NSURL URLWithString: [NSString stringWithFormat: kFetchArrivalsForStationURL, self.naptanId]];
        NSURLSessionDataTask *dataTask = [session dataTaskWithURL:apiURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            jsonFeed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            
            for (int i = 0; i < [jsonFeed count]; i++) {
                NSDictionary *object = jsonFeed[i];
                //ignore trains terminating at this station
                if (![[object valueForKey: @"destinationNaptanId"] isEqualToString: self.naptanId]) {
                    Train *train = [[Train alloc] init];
                    train.destiantionName = [[[object valueForKey: @"destinationName"]  stringByReplacingOccurrencesOfString:@" Station" withString:@""]stringByReplacingOccurrencesOfString:@" Underground" withString:@""];
                    train.timeDue = [[object valueForKey:@"timeToStation"] intValue];
                    train.lineName = [object valueForKey:@"lineName"];
                    [fetchedTrainsArray addObject: train];
                }
            }
            [fetchedTrainsArray sortUsingComparator:^(Train* obj1, Train* obj2) {
                
                if (obj1.timeDue > obj2.timeDue) {
                    return (NSComparisonResult)NSOrderedDescending;
                }
                
                if (obj1.timeDue < obj2.timeDue) {
                    return (NSComparisonResult)NSOrderedAscending;
                }
                return (NSComparisonResult)NSOrderedSame;
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.timer invalidate];
                
                [self.trainsArray removeAllObjects];
                self.trainsArray = [fetchedTrainsArray mutableCopy];
                
                self->_timer = [NSTimer scheduledTimerWithTimeInterval:kRefreshTime target:self selector:@selector(updateTrainTimes:) userInfo:nil repeats:YES];
                
                [self.tableView reloadData];
                
                [self.fetchingTrainsSpinner stopAnimating];
                self.dowmloadingTrains = NO;
            });
        }];
        [dataTask resume];
    }
}

-(void) refreshTrainsJSON {
    if (!self.dowmloadingTrains) {
        [self fetchTrainsForStation: self.naptanId];
        [self.refreshTrains endRefreshing];
    }
}


#pragma mark - Table view

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    TrainsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: kTrainCellResusableIndentifier];
    
    Train *train = self.trainsArray[indexPath.row];
    cell.destiantionLabel.text = train.destiantionName;
    cell.timeDueLabel.text = [self textForTimeDueLabel: train];
    cell.lineColourOutline.backgroundColor = [UIColor colorNamed: train.lineName];
    
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.trainsArray.count > 3) {
        return 3; //as per instructions
    }
    return self.trainsArray.count;
}

- (NSString *)textForTimeDueLabel: (Train *) train  {
    int seconds = train.timeDue;
    if (seconds < 60) {
        return @"due";
    } else {
        return [NSString stringWithFormat:@"%i min", seconds/60];
    }
}


#pragma mark - Collection view

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    FacilitiesCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier: kFacilitiesCellResusableIndentifier
                                                                                   forIndexPath:indexPath];
    NSString *facility = self.facilitiesArray[indexPath.row];
    
    cell.facilitiesLabel.text = facility;
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.facilitiesArray.count;
}


#pragma mark - Navigation

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString: kFacilityDetailSegueIdentifier]) {
        FacilityVC *destination = segue.destinationViewController;
        if ([destination respondsToSelector:@selector(setFacilityName:)]) {
            NSArray *indexPaths = [self.collectionView indexPathsForSelectedItems];
            NSIndexPath *indexPath = [indexPaths objectAtIndex:0];
            NSString *facility = self.facilitiesArray[indexPath.row];
            destination.facilityName = facility;
        }
    }
}


#pragma mark - Timer

- (void) updateTrainTimes: (NSTimer *)timer {
    int endIndex = (int)self.trainsArray.count - 1;
    for (int i = endIndex ; i >= 0 ; i--) {
        Train *train = self.trainsArray[i];
        train.timeDue -= kRefreshTime;
        if (train.timeDue < 0) {
            [self.trainsArray removeObjectAtIndex: i];
        }
    }
    [self.tableView reloadData];
    if (self.trainsArray.count < 5) {
        [self fetchTrainsForStation: self.naptanId];
    }
}

@end

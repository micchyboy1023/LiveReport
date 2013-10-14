//
//  PostListViewController.m
//  LiveReport2013
//
//  Created by Ueta Masamichi on 2013/03/28.
//  Copyright (c) 2013年 Ueta Masamichi. All rights reserved.
//

#import "PostListViewController.h"

#import "TweetData.h"
#import "TwitterTableViewCell.h"
#import "UIDevice+VersionCheck_h.h"

#import "PrettyKit.h"
#import <QuartzCore/QuartzCore.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>

@interface PostListViewController ()

@end

@implementation PostListViewController
@synthesize postListTable=_postListTable;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)FromInterfaceOrientation {
    if(bannerIsVisible){
        adBannerView.frame = CGRectMake(adBannerView.frame.origin.x, adBannerView.frame.origin.y, self.view.frame.size.width, adBannerView.frame.size.height);
        _postListTable.frame = CGRectMake(_postListTable.frame.origin.x, _postListTable.frame.origin.y + adBannerView.frame.size.height, _postListTable.frame.size.width, _postListTable.frame.size.height - adBannerView.frame.size.height);
    }
    else{
        _postListTable.frame = CGRectMake(_postListTable.frame.origin.x, 0, _postListTable.frame.size.width, self.view.frame.size.height);
    }
    
}


#pragma mark -
#pragma mark Initialization
- (void) initNavBar{
    if([[UIDevice currentDevice] systemMajorVersion] < 7)
    {
        self.navigationController.navigationBar.tintColor = [UIColor colorWithHex:0xCC3599];
    }
    self.navigationItem.title = NSLocalizedString(@"Tweet of everyone", @"Tweet of everyone");
}

- (void) initTableView{
    _postListTable.delegate = self;
    _postListTable.dataSource = self;
    _postListTable.scrollsToTop = YES;
    //[_postListTable dropShadows];
    //_postListTable.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
}

- (void) initEGORefreshTableHeaderView{
    if (refreshHeaderView == nil) {
		
		EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - _postListTable.bounds.size.height, _postListTable.frame.size.width, _postListTable.bounds.size.height)];
		view.delegate = self;
        view.backgroundColor = [UIColor whiteColor];
		[_postListTable addSubview:view];
		refreshHeaderView = view;
		
	}
	
	//  update the last update date
	[refreshHeaderView refreshLastUpdatedDate];
}

-(void) initIAd{
    adBannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
    adBannerView.delegate = self;
    adBannerView.frame = CGRectOffset(adBannerView.frame, 0.0, -adBannerView.frame.size.height);
    bannerIsVisible=NO;
    [self.view addSubview:adBannerView];
}



#pragma mark -
#pragma mark View Life Cycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if([self respondsToSelector:@selector(edgesForExtendedLayout)])
        [self setEdgesForExtendedLayout:UIRectEdgeBottom];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self initNavBar];
    [self initTableView];
    [self initEGORefreshTableHeaderView];
    [self initIAd];
    
    tweetList = [NSMutableArray array];
    imageStore = [[ImageStore alloc] initWithDelegate:self];
    
    
    ACAccountStore *accountStore = [[ACAccountStore alloc]init];
	ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
	
	[accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
		if(granted)
		{
			NSArray *accounts = [accountStore accountsWithAccountType:accountType];
			if([accounts count] > 0)
			{
				ACAccount *account = accounts[0];
				self.accountId = [NSString stringWithString:account.identifier];
                [self getTweets];
			}
		}
	}];
    
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark UITableView Delegate Methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}



-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if([tweetList count] != 0){
        TweetData *tweet = [tweetList objectAtIndex:indexPath.row];
        TwitterTableViewCell *cellForHeight = [[TwitterTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
        [cellForHeight setupRowData:tweet];
        
        CGSize size;
        size.width = _postListTable.frame.size.width;
        size.height = TweetMaxCellHeight;
        size = [cellForHeight sizeThatFits:size];
        
        if(size.height < TweetMinCellHeight){
            return TweetMinCellHeight;
        }
        else    return size.height;
    }
    else return 60;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if([tweetList count] != 0){
        return [tweetList count];
    }
    else return 1;
}


-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIdentifier = @"Cell";
    
    TwitterTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[TwitterTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.tableViewBackgroundColor = tableView.backgroundColor;
    }
    
    if([[UIDevice currentDevice] systemMajorVersion] < 7){
        cell.cornerRadius = 5;
        cell.customSeparatorColor = [UIColor colorWithHex:0xCC3599];
        cell.borderColor = [UIColor colorWithHex:0xCC3599];
        [cell prepareForTableView:tableView indexPath:indexPath];
    }
    else{
        cell.customSeparatorStyle = UITableViewCellSeparatorStyleNone;
    }
    if([tweetList count] != 0){
        cell.textLabel.text = nil;
        [cell setupRowData:[tweetList objectAtIndex:indexPath.row]];
        
        UIImage *iconImage = [imageStore getImage:[[tweetList objectAtIndex:indexPath.row] iconImageURL]];
        
        
        if(iconImage != nil){
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            cell.imageView.image = iconImage;
            cell.imageView.layer.masksToBounds = YES;
            cell.imageView.layer.cornerRadius = 5.0f;
        }
        else {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            cell.imageView.image = [UIImage imageNamed:@"nouser"];
        }
    }
    else{
        cell.textLabel.text = NSLocalizedString(@"No Result", @"No Result");
    }

    
    return cell;
    
}


#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource{
	
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
	reloading = YES;
    
    [self getTweets];
	
}

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
	reloading = NO;
	[refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_postListTable];
	
}


#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	
	[refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
	[refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
	
}


#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	
	[self reloadTableViewDataSource];
	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:3.0];
	
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	
	return reloading; // should return if data source model is reloading
	
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	
	return [NSDate date]; // should return date data source was last changed
	
}



- (void)getTweets{
    ACAccountStore *accountStore = [[ACAccountStore alloc]init];
	ACAccount *account = [accountStore accountWithIdentifier:self.accountId];
    NSString *requestString = @"https://api.twitter.com/1.1/search/tweets.json?q=#岡平健治&result_type=mixed&count=100";
	NSURL *url = [NSURL URLWithString:[requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:url parameters:nil];
	[request setAccount:account];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	[request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
		if(responseData)
		{
			if(urlResponse.statusCode == 200)
			{
				[tweetList removeAllObjects];
				NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                
                for(int i=0; i<[[jsonDictionary objectForKey:@"statuses"] count]; i++){
                    TweetData *rowData = [[TweetData alloc] init];
                    rowData.userName = [[[jsonDictionary objectForKey:@"statuses"] objectAtIndex:i] objectForKey:@"from_user"];
                    rowData.status = [[[jsonDictionary objectForKey:@"statuses"] objectAtIndex:i] objectForKey:@"text"];
                    rowData.createdAt = [[[jsonDictionary objectForKey:@"statuses"] objectAtIndex:i] objectForKey:@"created_at"];
                    rowData.iconImageURL = [[[[jsonDictionary objectForKey:@"statuses"] objectAtIndex:i] objectForKey:@"user"] objectForKey:@"profile_image_url"];
                    
                    [tweetList addObject:rowData];
                }
                [_postListTable
                 performSelectorOnMainThread:@selector(reloadData)
                 withObject:nil
                 waitUntilDone:NO
                 ];
                if(reloading) [self doneLoadingTableViewData];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
			}
			else
			{
				// 認証エラー、レートリミットオーバーなど
				NSLog(@"Error. %@",[[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding]);
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                if(reloading) [self doneLoadingTableViewData];
			}
		}
		else
		{
			// レスポンスを受け取れなかった場合
            NSLog(@"Error");
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            if(reloading) [self doneLoadingTableViewData];
			
		}
	}];
}


#pragma mark -
#pragma mark - ImageStore Delegate Methods
- (void)imageStoreDidGetNewImage:(ImageStore*)sender url:(NSString*)url
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [_postListTable
     performSelectorOnMainThread:@selector(reloadData)
     withObject:nil
     waitUntilDone:NO
     ];
    
}



#pragma mark -
#pragma mark AdBannerView Delegate Methods
-(void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    if (!bannerIsVisible)
    {
        [UIView beginAnimations:@"animateAdBannerOn" context:NULL];
        banner.frame = CGRectOffset(banner.frame, 0, adBannerView.frame.size.height);
        [UIView commitAnimations];
        
        bannerIsVisible = YES;
        adBannerView.frame = CGRectMake(adBannerView.frame.origin.x, adBannerView.frame.origin.y, self.view.frame.size.width, adBannerView.frame.size.height);
        _postListTable.frame = CGRectMake(_postListTable.frame.origin.x, _postListTable.frame.origin.y + adBannerView.frame.size.height, _postListTable.frame.size.width, _postListTable.frame.size.height - adBannerView.frame.size.height);
    }
}


-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    if (bannerIsVisible)
    {
        [UIView beginAnimations:@"animateAdBannerOff" context:NULL];
        banner.frame = CGRectOffset(banner.frame, 0, -adBannerView.frame.size.height);
        [UIView commitAnimations];
        bannerIsVisible = NO;
        _postListTable.frame = CGRectMake(_postListTable.frame.origin.x, 0, _postListTable.frame.size.width, self.view.frame.size.height);
    }
}


@end

//
//  ViewController.m
//  GiveThemAHome
//
//  Created by Evan on 2016/6/28.
//  Copyright © 2016年 Evan. All rights reserved.
//

#import "ViewController.h"
#import "ImageModel.h"
#import "ImageCache.h"
#import "Cell.h"

@interface ViewController ()<NSURLSessionDelegate,UITableViewDelegate,UITableViewDataSource>
{
    int currentPage;
    NSURLSessionConfiguration *defaultConfigObject;
    NSURLSession *defaultSession;
//    BOOL hiddenFooter;
}
//@property (weak, nonatomic) IBOutlet UIButton *btn;
@property (weak, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *footerViewHeight;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *arr_ImgURL;
@property (nonatomic, strong) NSMutableArray *arr_Result;
@property (nonatomic, strong) NSOperationQueue *imageQueue;
@property (nonatomic, strong) ImageCache *cache;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initProperty];
    [self getResultData];
}

//-(void) viewDidLayoutSubviews
//{
//    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)])
//    {
//        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
//    }
//    
//    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)])
//    {
//        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
//    }
//}

-(void)initProperty
{
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.hidden = YES;
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 36)];
    view.backgroundColor = [UIColor grayColor];
    UIActivityIndicatorView *ac = [[UIActivityIndicatorView alloc]
                                   initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [ac startAnimating];
    [view addSubview:ac]; // <-- Your UIActivityIndicatorView
    self.tableView.tableFooterView = view;
//    self.tableView.tableFooterView.hidden = YES;
    _cache = [ImageCache sharedImageCache];
    _arr_ImgURL = [[NSMutableArray alloc] init];
    _imageQueue = [[NSOperationQueue alloc] init];
    _imageQueue.maxConcurrentOperationCount = 3;
    _arr_Result = [[NSMutableArray alloc] init];
    [_tableView registerNib:[UINib nibWithNibName:@"Cell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    [self.tableView setSeparatorColor:[UIColor blackColor]];
    _tableView.estimatedRowHeight = 270.f;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _footerViewHeight.constant = 0;
    currentPage = 0;
//    hiddenFooter = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
- (IBAction)add:(id)sender
{
    currentPage = currentPage +3;
    [self getResultData];
}

-(void)getResultData
{
    NSString *urlString = [NSString stringWithFormat:@"http://data.coa.gov.tw/Service/OpenData/AnimalOpenData.aspx?$top=3&$skip=%i",currentPage];
//    NSString *urlString = @"http://data.coa.gov.tw/Service/OpenData/AnimalOpenData.aspx?$top=1000";
    NSURL * url = [NSURL URLWithString:urlString];
    
    defaultConfigObject = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];
    
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURLSessionDataTask * dataTask = [defaultSession dataTaskWithURL:url
                                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                            if(error == nil)
                                                            {
                                                                [self saveResultData:data];
                                                                _tableView.hidden = NO;
//                                                                self.tableView.tableFooterView.hidden = YES;
//                                                                _footerViewHeight.constant = 0;
                                                            }
                                                        }];
        
        [dataTask resume];
//    });
}

-(void)saveResultData:(NSData *)data
{
    NSError *error = nil;
    NSArray *arrTemp = [[NSArray alloc] init];
    
    arrTemp = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &error];
    [_arr_Result addObjectsFromArray:arrTemp];
    for (int i = 0; i < arrTemp.count ; i++)
    {
        NSDictionary * dic = [arrTemp objectAtIndex:i];
        NSString *imgString = [dic objectForKey:@"album_file"];
        NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:imgString,@"album_file", nil];
        ImageModel *m = [ImageModel modelImageWithDic:d];
        [_arr_ImgURL addObject:m];
    }
    
    [_tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _arr_ImgURL.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell * cell = [[UITableViewCell alloc] init];
    Cell *cell = (Cell *)[_tableView dequeueReusableCellWithIdentifier:@"Cell"];
    ImageModel *m = [_arr_ImgURL objectAtIndex:indexPath.row];
    if ([_cache.allImageCache objectForKey:m.album_file])
    {
        cell.image.image = [_cache.allImageCache objectForKey:m.album_file];
    }
    else
    {
        cell.image.image = [UIImage imageNamed:@"picture"];
        [self downloadImage:indexPath];
    }
//    cell.textLabel.text = [NSString stringWithFormat:@"%i",indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)])
    {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)])
    {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    
    NSIndexPath *lastRow = [NSIndexPath indexPathForRow:[_arr_ImgURL count]-1 inSection:0];
    
    if (indexPath == lastRow)
    {
//        _footerViewHeight.constant = 30;
//        self.tableView.tableFooterView.hidden = NO;
        [self add:nil];
    }
}

//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section;
//{
//    if (hiddenFooter)
//    {
//        return 0.f;
//    }
//    else
//    {
//        return 30.f;
//    }
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 270;
}

- (void)downloadImage:(NSIndexPath *)indexPath
{
    //判断下载缓存池中是否存在当前下载的操作
    ImageModel *m = [_arr_ImgURL objectAtIndex:indexPath.row];
    if ([_cache.allDownloadOperationCache objectForKey:m.album_file])
    {
        NSLog(@"正在下载ing...");
        return;
    }
    
    defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    defaultConfigObject.timeoutIntervalForResource = 6;
    defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: _imageQueue];
    
    NSURL * url = [NSURL URLWithString:m.album_file];
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURLSessionDownloadTask * downloadImageTask = [defaultSession downloadTaskWithURL:url];
        [downloadImageTask resume];
        
//    });
    [_cache.allDownloadOperationCache setObject:@"xx" forKey:m.album_file];
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSData *data = [NSData dataWithContentsOfURL:location];
    NSString *url = downloadTask.originalRequest.URL.absoluteString;
    NSIndexPath *index = [self getIndexPathWithURL:url];
    UIImage *image = [UIImage imageWithData:data];
    [self.cache.allImageCache setObject:image forKey:url];
    [session invalidateAndCancel];
    //将下载操作从操作缓存池删除(下载操作已经完成)
    [self.cache.allDownloadOperationCache removeObjectForKey:url];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationFade];
    });
}

-(NSIndexPath *)getIndexPathWithURL:(NSString *)url
{
    for (int i = 0; i < _arr_ImgURL.count; i++)
    {
        if ([((ImageModel *)[_arr_ImgURL objectAtIndex:i]).album_file isEqualToString:url])
        {
            NSIndexPath *index = [NSIndexPath indexPathForRow:i inSection:0];
            return index;
        }
    }
    
    return nil;
}
@end

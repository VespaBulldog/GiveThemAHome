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

@interface ViewController ()<NSURLSessionDelegate>
{
    int currentPage;
    NSURLSessionConfiguration *defaultConfigObject;
    NSURLSession *defaultSession;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *arr_ImgURL;
@property (nonatomic, strong) NSMutableArray *arr_Result;
@property (nonatomic, strong) NSOperationQueue *opQueue;
@property (nonatomic, strong) ImageCache *cache;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _arr_ImgURL = [[NSMutableArray alloc] init];
    _cache = [ImageCache sharedImageCache];
    _opQueue = [[NSOperationQueue alloc] init];
    _opQueue.maxConcurrentOperationCount = 3;
    _arr_Result = [[NSMutableArray alloc] init];
    currentPage = 0;
    [self getResultData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];
    
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURLSessionDataTask * dataTask = [defaultSession dataTaskWithURL:url
                                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                            if(error == nil)
                                                            {
                                                                [self saveResultData:data];
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
    return _arr_Result.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [[UITableViewCell alloc] init];
    
    ImageModel *m = [_arr_ImgURL objectAtIndex:indexPath.row];
    if ([_cache.allImageCache objectForKey:m.album_file])
    {
        cell.imageView.image = [_cache.allImageCache objectForKey:m.album_file];
    }
    else
    {
        [self downloadImage:indexPath];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%i",indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 300;
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
    defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: _opQueue];
    
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

//
//  ImageCache.h
//  GiveThemAHome
//
//  Created by Evan on 2016/6/28.
//  Copyright © 2016年 Evan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImageCache : NSObject
@property (nonatomic, retain) NSCache *allImageCache;
@property (nonatomic, strong) NSCache *allDownloadOperationCache;
#pragma mark - Methods
+ (ImageCache*)sharedImageCache;
- (void) AddImage:(NSString *)imageURL :(UIImage *)image;
- (UIImage*) GetImage:(NSString *)imageURL;
- (BOOL) DoesExist:(NSString *)imageURL;
@end
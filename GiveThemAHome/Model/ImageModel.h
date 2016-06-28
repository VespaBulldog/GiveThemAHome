//
//  ModelImage.h
//  testCacheImage
//
//  Created by Evan on 2016/6/24.
//  Copyright © 2016年 Evan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageModel : NSObject
@property (nonatomic, copy) NSString *album_file;
- (instancetype)initWithDic:(NSDictionary *)dic;
+ (instancetype)modelImageWithDic:(NSDictionary *)dic;
@end

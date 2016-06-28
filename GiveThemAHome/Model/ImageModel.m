//
//  ModelImage.m
//  testCacheImage
//
//  Created by Evan on 2016/6/24.
//  Copyright © 2016年 Evan. All rights reserved.
//

#import "ImageModel.h"

@implementation ImageModel
- (instancetype)initWithDic:(NSDictionary *)dic
{
    if (self = [super init])
    {
        [self setValuesForKeysWithDictionary:dic];
    }
    return self;
}
+ (instancetype)modelImageWithDic:(NSDictionary *)dic
{
    return  [[self alloc]initWithDic:dic];
}
@end

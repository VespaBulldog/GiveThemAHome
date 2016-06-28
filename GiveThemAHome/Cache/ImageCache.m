//
//  ImageCache.m
//  testDog
//
//  Created by Evan on 2016/6/24.
//  Copyright © 2016年 Evan. All rights reserved.
//

#import "ImageCache.h"

@implementation ImageCache
@synthesize allImageCache;
@synthesize allDownloadOperationCache;
#pragma mark - Methods
static ImageCache* sharedImageCache = nil;

+(ImageCache*)sharedImageCache
{
    @synchronized([ImageCache class])
    {
        if (!sharedImageCache)
            sharedImageCache= [[self alloc] init];
        
        return sharedImageCache;
    }
    
    return nil;
}

+(id)alloc
{
    @synchronized([ImageCache class])
    {
        NSAssert(sharedImageCache == nil, @"Attempted to allocate a second instance of a singleton.");
        sharedImageCache = [super alloc];
        
        return sharedImageCache;
    }
    
    return nil;
}

-(id)init
{
    self = [super init];
    if (self != nil)
    {
        allImageCache = [[NSCache alloc] init];
        allDownloadOperationCache = [[NSCache alloc] init];
    }
    
    return self;
}

- (void) AddImage:(NSString *)imageURL :(UIImage *)image
{
    [allImageCache setObject:image forKey:imageURL];
}

- (NSString*) GetImage:(NSString *)imageURL
{
    return [allImageCache objectForKey:imageURL];
}

- (BOOL) DoesExist:(NSString *)imageURL
{
    if ([allImageCache objectForKey:imageURL] == nil)
    {
        return false;
    }
    
    return true;
}
@end


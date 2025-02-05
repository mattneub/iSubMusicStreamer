//
//  CacheAlbumsViewController.h
//  iSub
//
//  Created by Ben Baron on 6/16/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CacheAlbumViewController : UITableViewController 

@property (nonatomic, copy) NSString *artistName;
@property (nonatomic, strong) NSMutableArray *listOfAlbums;
@property (nonatomic, strong) NSMutableArray *listOfSongs;
@property (nonatomic, strong) NSArray *sectionInfo;
@property (nonatomic, strong) NSArray *segments;

@end

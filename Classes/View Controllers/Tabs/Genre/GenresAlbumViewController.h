//
//  CacheAlbumsViewController.h
//  iSub
//
//  Created by Ben Baron on 6/16/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GenresAlbumViewController : UITableViewController 

@property (strong) NSMutableArray *listOfAlbums;
@property (strong) NSMutableArray *listOfSongs;
@property NSInteger segment;
@property (copy) NSString *seg1;
@property (copy) NSString *genre;

@end

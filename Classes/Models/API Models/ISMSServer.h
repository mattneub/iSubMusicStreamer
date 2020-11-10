//
//  ISMSServer.h
//  iSub
//
//  Created by Ben Baron on 12/29/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SUBSONIC @"Subsonic"

@interface ISMSServer : NSObject <NSSecureCoding>

@property (copy) NSString *url;
@property (copy) NSString *username;
@property (copy) NSString *password;
@property (copy) NSString *type;
@property (copy) NSString *lastQueryId;
@property (copy) NSString *uuid;

@end
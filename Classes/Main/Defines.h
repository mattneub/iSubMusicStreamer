//
//  Defines.h
//  iSub
//
//  Created by Ben Baron on 9/15/12.
//  Copyright (c) 2012 Ben Baron. All rights reserved.
//

#ifndef iSub_Defines_h
#define iSub_Defines_h

#import "ISMSNotificationNames.h"

// Helper functions
#define n2N(value) (value ? value : [NSNull null])
#define NSStringFromBOOL(value) (value ? @"YES" : @"NO")
#define BytesForSecondsAtBitrate(seconds, bitrate) ((bitrate / 8) * 1024 * seconds)
#define NSIndexPathMake(section, row) ([NSIndexPath indexPathForRow:row inSection:section])

#endif

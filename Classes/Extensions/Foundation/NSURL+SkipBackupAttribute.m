//
//  NSURL+SkipBackupAttribute.m
//  EX2Kit
//
//  Created by Benjamin Baron on 11/21/12.
//
//

#import "NSURL+SkipBackupAttribute.h"
#import "Defines.h"
#import <sys/xattr.h>



@implementation NSURL (SkipBackupAttribute)

- (BOOL)addOrRemoveSkipAttribute:(BOOL)isAdd {
    // This URL must point to a file
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.path]) {
        return NO;
    }
    
    NSError *error = nil;
    BOOL success = NO;
    @try {
        success = [self setResourceValue:@(isAdd) forKey:NSURLIsExcludedFromBackupKey error:&error];
        if (!success) {
            NSLog(@"Error excluding %@ from backup: %@", self.lastPathComponent, error);
        }
    } @catch (NSException *exception) {
        NSLog(@"Exception excluding %@ from backup: %@", self.lastPathComponent, exception);
    }
    return success;
}

- (BOOL)addSkipBackupAttribute {
    return [self addOrRemoveSkipAttribute:YES];
}

- (BOOL)removeSkipBackupAttribute {
    return [self addOrRemoveSkipAttribute:NO];
}

@end

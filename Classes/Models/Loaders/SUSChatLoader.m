//
//  SUSChatLoader.m
//  iSub
//
//  Created by Benjamin Baron on 10/29/11.
//  Copyright (c) 2011 Ben Baron. All rights reserved.
//

#import "SUSChatLoader.h"
#import "NSMutableURLRequest+SUS.h"
#import "RXMLElement.h"
#import "NSError+ISMSError.h"
#import "ISMSChatMessage.h"

@implementation SUSChatLoader

#pragma mark - Lifecycle

- (SUSLoaderType)type {
    return SUSLoaderType_Chat;
}

#pragma mark - Loader Methods

- (NSURLRequest *)createRequest {
    return [NSMutableURLRequest requestWithSUSAction:@"getChatMessages" parameters:nil];
}

- (void)processResponse {
    RXMLElement *root = [[RXMLElement alloc] initFromXMLData:self.receivedData];
    if (!root.isValid) {
        NSError *error = [NSError errorWithISMSCode:ISMSErrorCode_NotXML];
        [self informDelegateLoadingFailed:error];
    } else {
        RXMLElement *error = [root child:@"error"];
        if (error.isValid) {
            NSInteger code = [[error attribute:@"code"] integerValue];
            NSString *message = [error attribute:@"message"];
            [self informDelegateLoadingFailed:[NSError errorWithISMSCode:code message:message]];
        } else {
            NSMutableArray *messages = [[NSMutableArray alloc] init];
            [root iterate:@"chatMessages.chatMessage" usingBlock:^(RXMLElement *e) {
                // Create the chat message object and add it to the array
                ISMSChatMessage *chatMessage = [[ISMSChatMessage alloc] initWithRXMLElement:e];
                [messages addObject:chatMessage];
            }];
            self.chatMessages = messages;
            
            // Notify the delegate that the loading is finished
            [self informDelegateLoadingFinished];
		}
	}
}

@end

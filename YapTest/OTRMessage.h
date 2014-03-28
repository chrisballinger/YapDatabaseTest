//
//  OTRMessage.h
//  YapTest
//
//  Created by Christopher Ballinger on 3/20/14.
//  Copyright (c) 2014 ChatSecure. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSMessageData.h"

@interface OTRMessage : NSObject <JSMessageData, NSCoding, NSCopying>

@property (nonatomic, copy, readwrite) NSString *text;
@property (nonatomic, copy, readwrite) NSString *sender;
@property (nonatomic, strong, readwrite) NSDate *date;
@property (nonatomic, copy, readwrite) NSString *uuid;

@end

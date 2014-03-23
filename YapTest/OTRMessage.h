//
//  OTRMessage.h
//  YapTest
//
//  Created by Christopher Ballinger on 3/20/14.
//  Copyright (c) 2014 ChatSecure. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSQMessage.h"

@interface OTRMessage : JSQMessage <NSCoding, NSCopying>

@property (nonatomic, copy, readwrite) NSString *uniqueIdentifier;

- (instancetype)initWithText:(NSString *)text
                      sender:(NSString *)sender
                        date:(NSDate *)date
            uniqueIdentifier:(NSString*)uniqueIdentifier;

@end

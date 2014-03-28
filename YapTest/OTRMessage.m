//
//  OTRMessage.m
//  YapTest
//
//  Created by Christopher Ballinger on 3/20/14.
//  Copyright (c) 2014 ChatSecure. All rights reserved.
//

#import "OTRMessage.h"

static NSString * const kOTRMessageText = @"kOTRMessageText";
static NSString * const kOTRMessageSender = @"kOTRMessageSender";
static NSString * const kOTRMessageDate = @"kOTRMessageDate";
static NSString * const kOTRMessageUUID = @"kOTRMessageUUID";


@implementation OTRMessage

- (instancetype) init {
    if (self = [super init]) {
        self.uuid = [[NSUUID UUID] UUIDString];
    }
    return self;
}

#pragma mark NSCoding
- (instancetype)initWithCoder:(NSCoder *)decoder // NSCoding deserialization
{
    if (self = [super init]) {
        self.text = [decoder decodeObjectForKey:kOTRMessageText];
        self.sender = [decoder decodeObjectForKey:kOTRMessageSender];
        self.date = [decoder decodeObjectForKey:kOTRMessageDate];
        self.uuid = [decoder decodeObjectForKey:kOTRMessageUUID];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder // NSCoding serialization
{
    [encoder encodeObject:self.text forKey:kOTRMessageText];
    [encoder encodeObject:self.sender forKey:kOTRMessageSender];
    [encoder encodeObject:self.date forKey:kOTRMessageDate];
    [encoder encodeObject:self.uuid forKey:kOTRMessageUUID];
}

#pragma mark NSCopying
- (instancetype) copyWithZone:(NSZone *)zone {
    OTRMessage *copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        copy.text = self.text;
        copy.sender = self.sender;
        copy.date = self.date;
    }
    return copy;
}

@end

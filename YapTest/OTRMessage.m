//
//  OTRMessage.m
//  YapTest
//
//  Created by Christopher Ballinger on 3/20/14.
//  Copyright (c) 2014 ChatSecure. All rights reserved.
//

#import "OTRMessage.h"

static NSString * const kOTRMessageUniqueIdentifier = @"kOTRMessageUniqueIdentifier";


@implementation OTRMessage

- (instancetype)initWithText:(NSString *)text
                      sender:(NSString *)sender
                        date:(NSDate *)date {
    NSString *uniqueIdentifier = [[NSUUID UUID] UUIDString];
    return [self initWithText:text sender:sender date:date uniqueIdentifier:uniqueIdentifier];
}

- (instancetype) initWithText:(NSString *)text sender:(NSString *)sender date:(NSDate *)date uniqueIdentifier:(NSString *)uniqueIdentifier {
    if (self = [super initWithText:text sender:sender date:date]) {
        _uniqueIdentifier = uniqueIdentifier;
    }
    return self;
}

#pragma mark NSCoding
- (instancetype)initWithCoder:(NSCoder *)decoder // NSCoding deserialization
{
    if (self = [super initWithCoder:decoder]) {
        self.uniqueIdentifier = [decoder decodeObjectForKey:kOTRMessageUniqueIdentifier];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder // NSCoding serialization
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.uniqueIdentifier forKey:kOTRMessageUniqueIdentifier];
}

#pragma mark NSCopying
- (instancetype) copyWithZone:(NSZone *)zone {
    OTRMessage *copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        copy.text = self.text;
        copy.sender = self.sender;
        copy.date = self.date;
        copy.uniqueIdentifier = self.uniqueIdentifier;
    }
    return copy;
}

@end

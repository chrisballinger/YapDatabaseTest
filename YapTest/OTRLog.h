//
//  OTRLog.h
//  YapTest
//
//  Created by Christopher Ballinger on 3/20/14.
//  Copyright (c) 2014 ChatSecure. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDLog.h"

#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif
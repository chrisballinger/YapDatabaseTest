//
//  OTRMessageViewController.m
//  YapTest
//
//  Created by Christopher Ballinger on 3/20/14.
//  Copyright (c) 2014 ChatSecure. All rights reserved.
//

#import "OTRMessageViewController.h"
#import "OTRMessage.h"
#import "OTRLog.h"
#import "YapDatabase.h"
#import "YapDatabaseViewMappings.h"
#import "YapDatabaseView.h"

static NSString * const kOTRMessagesCollection = @"messages";
static NSString * const kOTRMessagesGroup = @"messagesGroup";
static NSString * const kOTRMessagesView = @"messagesView";

@interface OTRMessageViewController ()
@property (nonatomic, strong) YapDatabase *database;
@property (nonatomic, strong) YapDatabaseConnection *mainConnection;
@property (nonatomic, strong) YapDatabaseConnection *backgroundConnection;
@end

@implementation OTRMessageViewController

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [self setupDatabase];
    [self setupDatabaseView];
    self.delegate = self;
    self.dataSource = self;
    [super viewDidLoad]; // this call to super has to be after setting the delegate and dataSource

    //[[JSBubbleView appearance] setFont:/* your font for the message bubbles */];
    
    self.title = @"Test";
    
    self.messageInputView.textView.placeHolder = @"Write it up";
    
    self.sender = @"Alice";
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self scrollToBottomAnimated:animated];
}

- (void) setupDatabase {
    NSString *databasePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"db.sqlite"];
    
    YapDatabaseOptions *options = [[YapDatabaseOptions alloc] init];
    options.corruptAction = YapDatabaseCorruptAction_Fail;
    options.passphraseBlock = ^{
        return @"test";
    };
    
    self.database = [[YapDatabase alloc] initWithPath:databasePath objectSerializer:NULL objectDeserializer:NULL metadataSerializer:NULL metadataDeserializer:NULL objectSanitizer:NULL metadataSanitizer:NULL options:options];
    self.mainConnection = [self.database newConnection];
    self.backgroundConnection = [self.database newConnection];
    [self.mainConnection beginLongLivedReadTransaction];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:self.database];
}

- (void) setupDatabaseView {
    YapDatabaseViewBlockType groupingBlockType;
    YapDatabaseViewGroupingWithObjectBlock groupingBlock;
    
    YapDatabaseViewBlockType sortingBlockType;
    YapDatabaseViewSortingWithObjectBlock sortingBlock;
    
    groupingBlockType = YapDatabaseViewBlockTypeWithObject;
    groupingBlock = ^NSString *(NSString *collection, NSString *key, id object){
        if ([object isKindOfClass:[OTRMessage class]]) {
            return kOTRMessagesGroup;
        }
        return nil; // exclude from view
    };
    
    sortingBlockType = YapDatabaseViewBlockTypeWithObject;
    sortingBlock = ^(NSString *group, NSString *collection1, NSString *key1, id obj1,
                     NSString *collection2, NSString *key2, id obj2){
        if ([group isEqualToString:kOTRMessagesGroup]) {
            OTRMessage *message1 = (OTRMessage*)obj1;
            OTRMessage *message2 = (OTRMessage*)obj2;
            return [message1.date compare:message2.date];
        }
        return NSOrderedSame;
    };
    
    YapDatabaseView *databaseView =
    [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock
                                 groupingBlockType:groupingBlockType
                                      sortingBlock:sortingBlock
                                  sortingBlockType:sortingBlockType];
    
    [self.database registerExtension:databaseView withName:kOTRMessagesView];
}

- (void)yapDatabaseModified:(NSNotification *)notification
{
    // End & Re-Begin the long-lived transaction atomically.
    // Also grab all the notifications for all the commits that I jump.
    NSArray *notifications = [self.mainConnection beginLongLivedReadTransaction];
    if ([notifications count] == 0) {
        return; // already processed commit
    }

    if ([self.mainConnection hasChangeForCollection:kOTRMessagesCollection inNotifications:notifications]) {
        DDLogInfo(@"Something changed in collection %@", kOTRMessagesCollection);
    }
}

- (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark JSMessagesViewDelegate
- (void) didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date {
    DDLogInfo(@"Did send text: %@ from sender %@ on date %@", text, sender, date);
    
    [self.backgroundConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRMessage *message = [[OTRMessage alloc] init];
        message.text = text;
        message.sender = sender;
        message.date = date;
        [transaction setObject:message forKey:message.uuid inCollection:kOTRMessagesCollection];
    } completionBlock:^{
        [self finishSend];
        [self scrollToBottomAnimated:YES];
    }];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath {
    return JSBubbleMessageTypeOutgoing;
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type
                       forRowAtIndexPath:(NSIndexPath *)indexPath {
    return [JSBubbleImageViewFactory bubbleImageViewForType:type color:[UIColor whiteColor]];
}

- (JSMessageInputViewStyle)inputViewStyle {
    return JSMessageInputViewStyleFlat;
}

#pragma mark JSMessagesViewData

- (id<JSMessageData>)messageForRowAtIndexPath:(NSIndexPath *)indexPath {
    __block OTRMessage *message = nil;
    [self.mainConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
        message = [[transaction ext:kOTRMessagesView] objectAtIndex:indexPath.row inGroup:kOTRMessagesGroup];
    }];
    return message;
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath sender:(NSString *)sender {
    return nil;
}

#pragma mark UITableViewDataSource

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    __block NSInteger numberOfMessages = 0;
    [self.mainConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
        numberOfMessages = [[transaction ext:kOTRMessagesView] numberOfKeysInGroup:kOTRMessagesGroup];
    }];
    return numberOfMessages;
}

@end

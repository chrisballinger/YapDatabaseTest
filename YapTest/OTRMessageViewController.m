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
    [super viewDidLoad];
    [self setupDatabase];
    [self setupDatabaseView];
    self.delegate = self;
    self.collectionView.dataSource = self;
    
    self.title = @"Test";
    
    self.sender = @"Alice";
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self scrollToBottomAnimated:animated];
}

- (void) setupDatabase {
    NSString *databasePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"db.sqlite"];
    self.database = [[YapDatabase alloc] initWithPath:databasePath objectSerializer:NULL objectDeserializer:NULL metadataSerializer:NULL metadataDeserializer:NULL objectSanitizer:NULL metadataSanitizer:NULL passphrase:@"test"];
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

- (void)messagesViewController:(JSQMessagesViewController *)viewController
                didSendMessage:(JSQMessage *)message {
    [self.backgroundConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRMessage *otrMessage = [[OTRMessage alloc] initWithText:message.text sender:message.sender date:message.date];
        [transaction setObject:otrMessage forKey:otrMessage.uniqueIdentifier inCollection:kOTRMessagesCollection];
    } completionBlock:^{
        [self finishSending];
        [self scrollToBottomAnimated:YES];
    }];
}

- (void)messagesViewController:(JSQMessagesViewController *)viewController
       didPressAccessoryButton:(UIButton *)sender {
    DDLogInfo(@"Pressed accessory button: %@", sender);
}

#pragma mark JSQMessagesCollectionViewDataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView
           messageForItemAtIndexPath:(NSIndexPath *)indexPath {
    __block OTRMessage *message = nil;
    [self.mainConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
        message = [[transaction ext:kOTRMessagesView] objectAtIndex:indexPath.row inGroup:kOTRMessagesGroup];
    }];
    return message;
}

#pragma mark UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    __block NSInteger numberOfMessages = 0;
    [self.mainConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
        numberOfMessages = [[transaction ext:kOTRMessagesView] numberOfKeysInGroup:kOTRMessagesGroup];
        }];
    return numberOfMessages;
}

- (UIImageView *)collectionView:(JSQMessagesCollectionView *)collectionView
                         layout:(JSQMessagesCollectionViewFlowLayout *)layout bubbleImageViewForItemAtIndexPath:(NSIndexPath *)indexPath
                         sender:(NSString *)sender
{
    return nil;
}

- (UIImageView *)collectionView:(JSQMessagesCollectionView *)collectionView
                         layout:(JSQMessagesCollectionViewFlowLayout *)layout avatarImageViewForItemAtIndexPath:(NSIndexPath *)indexPath
                         sender:(NSString *)sender
{
    return nil;
}


@end

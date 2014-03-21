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

@interface OTRMessageViewController ()
@property (nonatomic, strong) NSMutableArray *messages;
@end

@implementation OTRMessageViewController

- (void)viewDidLoad
{
    self.delegate = self;
    self.dataSource = self;
    [super viewDidLoad]; // this call to super has to be after setting the delegate and dataSource

    //[[JSBubbleView appearance] setFont:/* your font for the message bubbles */];
    
    self.title = @"Test";
    
    self.messageInputView.textView.placeHolder = @"Write it up";
    
    self.sender = @"Alice";
    
    OTRMessage *message = [[OTRMessage alloc] init];
    message.text = @"test1";
    message.sender = self.sender;
    message.date = [NSDate date];
    OTRMessage *message1 = [[OTRMessage alloc] init];
    message1.text = @"test2";
    message1.sender = self.sender;
    message1.date = [NSDate date];
    self.messages = [NSMutableArray arrayWithArray:@[message, message1]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark JSMessagesViewDelegate
- (void) didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date {
    DDLogInfo(@"Did send text: %@ from sender %@ on date %@", text, sender, date);
    OTRMessage *message = [[OTRMessage alloc] init];
    message.text = text;
    message.sender = sender;
    message.date = date;
    [self.messages addObject:message];
    //[self.tableView reloadData];
    [self finishSend];
    [self scrollToBottomAnimated:YES];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath {
    return JSBubbleMessageTypeIncoming;
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
    return self.messages[indexPath.row];
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath sender:(NSString *)sender {
    return nil;
}

#pragma mark UITableViewDataSource

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

@end

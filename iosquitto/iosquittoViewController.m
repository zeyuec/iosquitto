//
//  iosquittoViewController.m
//  iosquitto
//
//  Created by Zeyue Chen on 4/9/13.
//  Copyright (c) 2013 obcerver.com. All rights reserved.
//

#import "iosquittoViewController.h"
#import "iosquitto.h"
#import <QuartzCore/QuartzCore.h>

static NSString *clientId = @"demo";


@implementation iosquittoViewController
{
    Iosquitto *iosquitto;
}

@synthesize msgBox, host, port, connectButton, connectStatus;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[msgBox layer] setBorderWidth:1.0f];
    [[msgBox layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [msgBox setTextColor:[UIColor grayColor]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


// delegate methods

- (void) didConnect: (NSUInteger)code
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [connectStatus setTextColor:[UIColor colorWithRed:0 green:0.6 blue:0.2 alpha:1]];
        [connectStatus setText:@"Connection established"];
        [connectButton setEnabled:NO];
        [connectButton setTitle:@"Connected" forState:UIControlStateDisabled];
        [msgBox setText:@""];
        
    });
}

- (void) didConnectFailed:(int)failedCode {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [connectStatus setTextColor:[UIColor redColor]];
        [connectStatus setText:@"Connect failed"];
        [connectButton setEnabled:YES];
        [msgBox setText:@""];
    });
}

- (void) didDisconnect
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [connectStatus setTextColor:[UIColor redColor]];
        [connectStatus setText:@"Disconnected"];
        [connectButton setEnabled:YES];
        [msgBox setText:@""];
    });
}

- (void) didPublish: (NSUInteger)messageId
{
    
}

- (void) didReceiveIosquittoMessage:(IosquittoMessage *)iosquittoMessage {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *messageText = [[NSString alloc] initWithData:[iosquittoMessage payloadData]  encoding:NSUTF8StringEncoding];
        
        NSDateFormatter *dateFormat=[[NSDateFormatter alloc]init];
        [dateFormat setDateFormat:@"HH:mm:ss"];
        NSString* receiveTime=[dateFormat stringFromDate:[NSDate date]];
        
        NSString *showText = [NSString stringWithFormat:@"[%@] %@", receiveTime, messageText];
        
        [msgBox setText:[NSString stringWithFormat:@"%@\n%@",
                         [msgBox text], showText]];
    });
}

- (void) didSubscribe: (NSUInteger)messageId grantedQos:(NSArray*)qos
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [connectStatus setText:@"Subscribe successfully"];
        [msgBox setTextAlignment:NSTextAlignmentLeft];
        [msgBox setTextColor:[UIColor blackColor]];
        [msgBox setText:@"[Sub to 'iosquittoDemo' with qos 2 successfully]"];
    });
}

- (void) didUnsubscribe: (NSUInteger)messageId
{
    
}

- (void) onError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [msgBox setText:@"Error"];
    });
}

- (IBAction)connect:(id)sender {
    iosquitto = [[Iosquitto alloc] initWithClientId:clientId];
    [iosquitto setWill:@"0"
               toTopic:[NSString stringWithFormat:@"iosquittoClients/%@", clientId]
               withQos:2 retain:YES];
    
    iosquitto.delegate = self;
    
    [iosquitto connectToHost:self.host.text port:[self.port.text integerValue]];
    [iosquitto subscribe:@"iosquittoDemo" withQos:2];
    [iosquitto publishMessage:@"1"
                      toTopic:[NSString stringWithFormat:@"iosquittoClients/%@", clientId]
                      withQos:2 retain:YES];
}

@end

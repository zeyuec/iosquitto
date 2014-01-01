//
//  iosquitto.h
//
//  Created by Zeyue Chen on 4/9/13.
//  Copyright (c) 2013 obcerver.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IosquittoMessage.h>

@protocol IosquittoDelegate

- (void) didConnect: (NSUInteger)code;
- (void) didConnectFailed: (int) failedCode;
- (void) didDisconnect;
- (void) didSubscribe: (NSUInteger)messageId grantedQos:(NSArray*)qos;
- (void) didUnsubscribe: (NSUInteger)messageId;
- (void) didPublish: (NSUInteger)messageId;
- (void) didReceiveIosquittoMessage:(IosquittoMessage *)iosquittoMessage;
- (void) onError:(NSError *)error;

@end


@interface Iosquitto : NSObject

@property (readwrite,strong) NSString *host;
@property (readwrite,assign) unsigned short port;
@property (readwrite,strong) NSString *username;
@property (readwrite,strong) NSString *password;
@property (readwrite,assign) unsigned short keepAlive;
@property (readwrite,assign) BOOL cleanSession;
@property (readwrite,strong) id<IosquittoDelegate> delegate;

+ (void) initialize;
+ (NSString*) version;

// Init && Connect
- (id) initWithClientId: (NSString *)clientId;
- (void) setMessageRetry: (NSUInteger)seconds;
- (void) connect;
- (void) connectToHost: (NSString*)host port:(NSInteger)port;
- (void) reconnect;
- (int) disconnect;
- (void) destroy;

// Loop Control
- (void) stopLoop;

// Subscribe && Unsubscribe
- (void) subscribe: (NSString *)topic;
- (void) subscribe: (NSString *)topic withQos:(NSUInteger)qos;
- (void) unsubscribe: (NSString *)topic;

// Publish Message
- (void) publishMessage: (NSString *)payload toTopic:(NSString *)topic withQos:(NSUInteger) qos retain:(BOOL)retain;
- (int) publishCStringMessage:(const char*)payload andLength:(int)len toTopic:(NSString *)topic withQos:(NSUInteger)qos retain:(BOOL)retain;

// Will Function
- (void) setWill: (NSString *)payload toTopic:(NSString *)willTopic withQos:(NSUInteger)willQos retain:(BOOL)retain;
- (void) clearWill;


@end

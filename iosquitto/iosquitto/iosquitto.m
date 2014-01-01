//
//  iosquitto.m
//
//  Created by Zeyue Chen on 4/9/13.
//  Copyright (c) 2013 obcerver.com. All rights reserved.
//

#define THREAD_LOOP_INTERNAL 1000

#import "iosquitto.h"
#import "mosquitto.h"
#import "mosquitto_internal.h"

@implementation Iosquitto
{
    struct mosquitto *mosq;
    BOOL loopLock;
}

static void on_connect(struct mosquitto *mosq, void *obj, int rc)
{
    Iosquitto* client = (__bridge Iosquitto*)obj;
    [[client delegate] didConnect:(NSUInteger)rc];
}

static void on_disconnect(struct mosquitto *mosq, void *obj, int rc)
{
    Iosquitto* client = (__bridge Iosquitto*)obj;
    [[client delegate] didDisconnect];
}

static void on_publish(struct mosquitto *mosq, void *obj, int message_id)
{
    Iosquitto* client = (__bridge Iosquitto*)obj;
    [[client delegate] didPublish:(NSUInteger)message_id];
}

static void on_message(struct mosquitto *mosq, void *obj, const struct mosquitto_message *message)
{
    Iosquitto* client = (__bridge Iosquitto*)obj;
    IosquittoMessage *iosquittoMessage = [[IosquittoMessage alloc] init];
    
    // copy data to nsdata
    NSData *data = [NSData dataWithBytes:message->payload length:message->payloadlen];
    NSString *topic = [NSString stringWithUTF8String: message->topic];
    
    [iosquittoMessage setPayloadLength:message->payloadlen];
    [iosquittoMessage setPayloadData:data];
    [iosquittoMessage setTopic:topic];
    
    // delegate
    [[client delegate] didReceiveIosquittoMessage:iosquittoMessage];
}

static void on_subscribe(struct mosquitto *mosq, void *obj, int message_id, int qos_count, const int *granted_qos)
{
    Iosquitto* client = (__bridge Iosquitto*)obj;
    [[client delegate] didSubscribe:message_id grantedQos:nil];
}

static void on_unsubscribe(struct mosquitto *mosq, void *obj, int message_id)
{
    Iosquitto* client = (__bridge Iosquitto*)obj;
    [[client delegate] didUnsubscribe:message_id];
}


- (void)setWill: (NSString *)payload toTopic:(NSString *)willTopic withQos:(NSUInteger)willQos retain:(BOOL)retain
{
    const char* cstrTopic = [willTopic cStringUsingEncoding:NSUTF8StringEncoding];
    const uint8_t* cstrPayload = (const uint8_t*)[payload cStringUsingEncoding:NSUTF8StringEncoding];
    size_t cstrlen = [payload lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    mosquitto_will_set(mosq, cstrTopic, cstrlen, cstrPayload, willQos, retain);
}

- (void)clearWill
{
    mosquitto_will_clear(mosq);
}

+ (void)initialize {
    mosquitto_lib_init();
}

+ (NSString*)version {
    int major, minor, revision;
    mosquitto_lib_version(&major, &minor, &revision);
    return [NSString stringWithFormat:@"%d.%d.%d", major, minor, revision];
}

- (id) initWithClientId: (NSString*) clientId {
    if ((self = [super init])) {
        const char* cstrClientId = [clientId cStringUsingEncoding:NSUTF8StringEncoding];
        self.host = @"localhost";
        self.port = 1883;
        self.keepAlive = 60;
        self.cleanSession = NO;
        
        mosq = mosquitto_new(cstrClientId, self.cleanSession, (__bridge void *)(self));
        mosquitto_connect_callback_set(mosq, on_connect);
        mosquitto_disconnect_callback_set(mosq, on_disconnect);
        mosquitto_publish_callback_set(mosq, on_publish);
        mosquitto_message_callback_set(mosq, on_message);
        mosquitto_subscribe_callback_set(mosq, on_subscribe);
        mosquitto_unsubscribe_callback_set(mosq, on_unsubscribe);
    }
    return self;
}


- (void) connect {
    const char *cstrHost = [self.host cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cstrUsername = NULL, *cstrPassword = NULL;
    
    if (self.username)
        cstrUsername = [self.username cStringUsingEncoding:NSUTF8StringEncoding];
    
    if (self.password)
        cstrPassword = [self.password cStringUsingEncoding:NSUTF8StringEncoding];
    
    if (cstrPassword && cstrUsername) {
        mosquitto_username_pw_set(mosq, cstrUsername, cstrPassword);
    }
    
    int ret = mosquitto_connect(mosq, cstrHost, self.port, self.keepAlive);
    if (ret > 0) {
        // connect failed
        [[self delegate] didConnectFailed:ret];
        
    } else {
        // connect suc
        [[self delegate] didConnect:ret];
        
        // use thread to run loop
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            loopLock = NO;
            while (!loopLock) {
                [self loop];
                usleep(THREAD_LOOP_INTERNAL);
            }
        });
    }
}

- (void) connectToHost: (NSString*)host port:(NSInteger)port {
    self.host = host;
    self.port = port;
    [self connect];
}

- (void) reconnect {
    mosquitto_reconnect(mosq);
}

- (void) stopLoop {
    loopLock = YES;
}

- (int) disconnect {
    loopLock = YES;
    int ret = mosquitto_disconnect(mosq);
    return ret;
}

- (void) destroy {
    loopLock = YES;
    mosquitto_destroy(mosq);
}

- (void) loop {
    if (mosq != nil) {
        mosquitto_loop(mosq, 1, 1);
    }
}

- (void) publishMessage: (NSString *)payload toTopic:(NSString *)topic withQos:(NSUInteger) qos retain:(BOOL) retain {
    const char* cstrTopic = [topic cStringUsingEncoding:NSUTF8StringEncoding];
    const uint8_t* cstrPayload = (const uint8_t*)[payload cStringUsingEncoding:NSUTF8StringEncoding];
    mosquitto_publish(mosq, NULL, cstrTopic, [payload length], cstrPayload, qos, retain);
}

- (int) publishCStringMessage:(const char*)payload andLength:(int)len toTopic:(NSString *)topic withQos:(NSUInteger)qos retain:(BOOL)retain
{
    const char* cstrTopic = [topic cStringUsingEncoding:NSUTF8StringEncoding];
    int ret = mosquitto_publish(mosq, NULL, cstrTopic, len, payload, qos, retain);
    return ret;
}

- (void) subscribe: (NSString *)topic {
    [self subscribe:topic withQos:0];
}

- (void) subscribe: (NSString *)topic withQos:(NSUInteger)qos {
    const char* cstrTopic = [topic cStringUsingEncoding:NSUTF8StringEncoding];
    mosquitto_subscribe(mosq, NULL, cstrTopic, qos);
}

- (void) unsubscribe: (NSString *)topic {
    const char* cstrTopic = [topic cStringUsingEncoding:NSUTF8StringEncoding];
    mosquitto_unsubscribe(mosq, NULL, cstrTopic);
}

- (void) setMessageRetry: (NSUInteger)seconds{
    mosquitto_message_retry_set(mosq, (unsigned int)seconds);
}

@end

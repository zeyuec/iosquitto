//
//  IosquittoMessage.h
//  KaCha
//
//  Created by Zeyue Chen on 9/17/13.
//  Copyright (c) 2013 MobileArt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IosquittoMessage : NSObject

@property (nonatomic) NSData *payloadData;
@property (nonatomic) int payloadLength;
@property (nonatomic) NSString *topic;

@end

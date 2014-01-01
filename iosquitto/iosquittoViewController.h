//
//  iosquittoViewController.h
//  iosquitto
//
//  Created by Zeyue Chen on 4/9/13.
//  Copyright (c) 2013 obcerver.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iosquitto.h"

@interface iosquittoViewController : UIViewController<IosquittoDelegate>
@property (weak, nonatomic) IBOutlet UITextField *host;
@property (weak, nonatomic) IBOutlet UITextField *port;

@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UILabel *connectStatus;

@property (weak, nonatomic) IBOutlet UITextView *msgBox;

- (IBAction)connect:(id)sender;

@end

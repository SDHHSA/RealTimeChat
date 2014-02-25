//
//  ViewController.m
//  SanDiegoHHSRealTimeCocoaTouch
//
//  Created by Rex Fatahi on 2/25/14.
//  Copyright (c) 2014 aug2uag. All rights reserved.
//

#import "ViewController.h"


@interface ViewController () <NSStreamDelegate, UITextFieldDelegate>
{
    NSInputStream* inputStream;
    NSOutputStream* outputStream;
    
    __weak IBOutlet UITextField *oTextField;
    __weak IBOutlet UITableView *oTableView;
    
    NSMutableData*  mutableData;
    NSString*       userName;
    
    NSMutableArray*        messages;
    UITextField*    enterNameTextField;
    UIView*         artficialView;
}

- (IBAction)submitText:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    messages = [NSMutableArray array];
    
    artficialView = [[UIView alloc] initWithFrame:self.view.bounds];
    artficialView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:artficialView];
    
    
    UILabel* chatApplicationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 44, 280, 33)];
    chatApplicationLabel.text = @"Welcome to Chat Application";
    [artficialView addSubview:chatApplicationLabel];
    
    
    enterNameTextField = [[UITextField alloc] initWithFrame:CGRectMake(80, 100, 120, 44)];
    enterNameTextField.delegate = self;
    enterNameTextField.placeholder = @"enter handle";
    [enterNameTextField canBecomeFirstResponder];
    [artficialView addSubview:enterNameTextField];
    
    
    [self initNetworkCommunication];
    
    
}

- (void) initNetworkCommunication
{
	CFReadStreamRef readStream = nil;
	CFWriteStreamRef writeStream = nil;
	CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (CFStringRef)@"192.168.0.13", 1230, &readStream, &writeStream);
    
	inputStream = (__bridge NSInputStream *)readStream;
	outputStream = (__bridge NSOutputStream *)writeStream;
	[inputStream setDelegate:self];
	[outputStream setDelegate:self];
	[inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]forMode:NSDefaultRunLoopMode];
	[outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]forMode:NSDefaultRunLoopMode];
	[inputStream open];
	[outputStream open];
    
}

#pragma mark-table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (messages.count == 0) return 1; else return messages.count;

}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"id"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"id"];
    }
    
    if (messages.count == 0) {
        cell.textLabel.text = @"array does not exist (yet)";
        return cell;
    }
    //declare string, assign to value at indexPath from array
    //array may be made from [dictionary allKeys];
    NSString* string = [messages objectAtIndex:indexPath.row];
    
    //set string to textLabel of cell
    [cell.textLabel setText:string];
    
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    
    return cell;
}

#pragma mark -textField delegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    if (newLength>30) {
    	[[[UIAlertView alloc] initWithTitle:@"Your Text" message:@"is too lengthy" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    	return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == enterNameTextField) {
        if (enterNameTextField.text.length == 0) {
            userName = @"no name";
        }
        userName = enterNameTextField.text;
        
        [UIView animateWithDuration:0.3f animations:^{
            artficialView.frame = CGRectMake(0, self.view.bounds.size.height, 80, 44);
        }];
        
    }
    
    if (textField == oTextField) {
        NSString* string = oTextField.text;
        
        NSLog(@"string = %@", string);
        
        NSDictionary* raw = @{userName:string};
        
        NSData *data = [NSJSONSerialization dataWithJSONObject:raw options:0 error:nil];
        [outputStream write:[data bytes] maxLength:[data length]];
    }
    
    
    [textField resignFirstResponder];
    return YES;
}

#pragma mark -action methods
- (IBAction)submitText:(id)sender
{
    [oTextField resignFirstResponder];
    
    NSString* string = oTextField.text;
    
    NSLog(@"string = %@", string);
    
    NSData *data = [[NSData alloc] initWithData:[string dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[data bytes] maxLength:[data length]];
    
    
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
	switch (streamEvent) {
            
		case NSStreamEventOpenCompleted:
			NSLog(@"Stream opened");
			break;
            
		case NSStreamEventHasBytesAvailable:
            
            if (theStream == inputStream) {
                
                uint8_t buffer[1024];
                int len;
                
                while ([inputStream hasBytesAvailable]) {
                    len = (int)[inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output) {
                            [self messageReceived:output];
                        }
                    }
                }
            }
            break;
            
		case NSStreamEventErrorOccurred:
			NSLog(@"Can not connect to the host!");
			break;
            
		case NSStreamEventEndEncountered:
			break;
            
		default:
			if (theStream == inputStream) {
                
                uint8_t buffer[1024];
                int len;
                
                while ([inputStream hasBytesAvailable]) {
                    len = (int)[inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output) {
                            [self messageReceived:output];
                        }
                    }
                }
            }
            break;
	}
    
}

- (void) messageReceived:(NSString *)message {
    NSLog(@"%s [Line %d]", __PRETTY_FUNCTION__, __LINE__);
	[messages addObject:message];
    dispatch_async(dispatch_get_main_queue(), ^{
        [oTableView reloadData];
    });
	
    // from http://www.raywenderlich.com/3932/networking-tutorial-for-ios-how-to-create-a-socket-based-iphone-app-and-server
}


@end

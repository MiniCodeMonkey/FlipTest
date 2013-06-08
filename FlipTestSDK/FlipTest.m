//
//  FlipTest.m
//  FlipTest
//
//  Created by Mathias Hansen on 6/8/13.
//  Copyright (c) 2013 AngelHack. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#define kApiUrl @"http://fliptest.local/api/v1/"

#import "FlipTest.h"

@implementation FlipTest

+ (id)currentFlipTest
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)goAhead:(NSString*)userToken {
    NSLog(@"FlipTest initialized with %@", userToken);
}

- (void)registerController:(UIViewController*)viewController {
    NSLog(@"New controller %@", [viewController description]);
    
    // Existing controllers    
    UIView *mainView = viewController.view;
    
    if (mainView) {
        NSDictionary *mainViewDict = [self findSubviews:mainView siblingNo:0 parentId:@""];
        
        NSDictionary *controllerDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [viewController.class description], @"className",
                                        mainViewDict, @"views",
                                        //(viewController.parentViewController ? [viewController.parentViewController.class description] : @""), @"parentController",
                                        nil];
        
        // View metadata
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error;
            
            NSString *url = [NSString stringWithFormat:@"%@controller", kApiUrl];
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            [request setHTTPMethod:@"POST"];
            [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:controllerDict options:0 error:&error]];
            
            NSURLResponse *response;
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            if (error) {
                // handle error
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"Return: %@", str);
            });
        });
    }
}

- (void)viewAppeared:(UIViewController*)viewController {
    NSLog(@"Controller shown %@", [viewController description]);
    
    /*UIView *mainView = viewController.view;
    
    if (mainView) {
        // View screenshot
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            CGRect rect = [mainView bounds];
            UIGraphicsBeginImageContextWithOptions(rect.size,YES,0.0f);
            CGContextRef context = UIGraphicsGetCurrentContext();
            [mainView.layer renderInContext:context];
            UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            [self uploadImage:capturedImage name:[viewController.class description]];
        });
    }*/
}

/*- (void)uploadImage:(UIImage*)image name:(NSString*)name {
    NSString *url = [NSString stringWithFormat:@"%@controller/screenshot", kApiUrl];
    
	NSData *imageData = UIImageJPEGRepresentation(image, 0.9);
	
	// setting up the request object now
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"POST"];
    
	NSString *boundary = @"---------------------------14737809831466499882746641449";
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
	[request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
	NSMutableData *body = [NSMutableData data];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"screenshot\"; filename=\"screenshot_1_%@.jpg\"\r\n", name] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[NSData dataWithData:imageData]];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody:body];
	
	NSError *error;
    
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error) {
        // handle error
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Return: %@", str);
    });
}*/

- (NSDictionary*)findSubviews:(UIView*)parentView siblingNo:(int)siblingNo parentId:(NSString*)parentId {
    
    NSMutableDictionary *viewDictionary = [[NSMutableDictionary alloc] init];
    
    NSString *viewIdentifier = [parentId stringByAppendingFormat:@".%d", siblingNo];

    // Record information about view
    [viewDictionary setObject:[parentView.class description] forKey:@"className"];
    [viewDictionary setObject:viewIdentifier forKey:@"id"];
    [viewDictionary setObject:[NSNumber numberWithFloat:parentView.frame.origin.x] forKey:@"x"];
    [viewDictionary setObject:[NSNumber numberWithFloat:parentView.frame.origin.y] forKey:@"y"];
    [viewDictionary setObject:[NSNumber numberWithFloat:parentView.frame.size.width] forKey:@"w"];
    [viewDictionary setObject:[NSNumber numberWithFloat:parentView.frame.size.height] forKey:@"h"];
    
    if (parentView.backgroundColor) {
        [viewDictionary setObject:[parentView.backgroundColor description] forKey:@"backgroundColor"];
    }
    
    if ([parentView isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton*)parentView;
        [viewDictionary setObject:([button titleForState:UIControlStateNormal] ? [button titleForState:UIControlStateNormal] : @"") forKey:@"text"];
    }
    
    if ([parentView isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel*)parentView;
        [viewDictionary setObject:(label.text ? label.text : @"") forKey:@"text"];
        [viewDictionary setObject:[label.textColor description] forKey:@"textColor"];
    }
    
    // Loop through subviews
    NSMutableArray *children = [[NSMutableArray alloc] init];
    
    int i = 0;
    for (UIView *subView in parentView.subviews) {
        [children addObject: [self findSubviews:subView siblingNo:i parentId:viewIdentifier]];
        i++;
    }
    
    // Store subviews
    [viewDictionary setObject:children forKey:@"children"];
    
    // Return full dictionary
    return viewDictionary;
}

@end

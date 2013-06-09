//
//  FlipTest.m
//  FlipTest
//
//  Created by Mathias Hansen on 6/8/13.
//  Copyright (c) 2013 AngelHack. All rights reserved.
//

#define kApiUrl @"http://fliptest.local/api/v1/"

#import <QuartzCore/QuartzCore.h>

#import "FlipTest.h"
#import "UIColor+Hex.h"
#import "UIButton+Block.h"

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

- (id)init {
    if (self = [super init]) {
        registeredControllers = [[NSMutableArray alloc] init];
        
        // Generate unique id if necessary
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"fliptest_identifier"]) {
            NSUUID  *UUID = [NSUUID UUID];
            
            [[NSUserDefaults standardUserDefaults] setObject:[UUID UUIDString] forKey:@"fliptest_identifier"];
        }
    }
    
    return self;
}

- (void)goAhead:(NSString*)userToken {
    NSLog(@"FlipTest initialized with %@", userToken);
    flipTestUserToken = userToken;
    
    [self updateTests];
}

- (void)updateTests {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        
        NSString *url = [NSString stringWithFormat:@"%@tests", kApiUrl];
        
        NSURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        
        NSURLResponse *response;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (error) {
            // handle error
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *jsonError;
            NSArray *response = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            
            [[NSUserDefaults standardUserDefaults] setObject:response forKey:@"fliptest_current_tests"];
            
            // Apply changes
            for (UIViewController *viewController in registeredControllers) {
                UIView *mainView = viewController.view;
                
                if (mainView) {
                    NSDictionary *tests = [[FlipTest currentFlipTest] testsForController:viewController];
                    
                    if ([tests count] > 0) {
                        [self runTests:tests onView:mainView siblingNo:0 parentId:@"0"];
                    }
                }
            }
        });
    });

}

- (NSDictionary*)testsForController:(UIViewController*)controller {
    NSMutableDictionary *resultTests = [[NSMutableDictionary alloc] init];
    
    // Load currently running tests
    NSArray *currentTests = [[NSUserDefaults standardUserDefaults] objectForKey:@"fliptest_current_tests"];
    
    // If no tests are registered, just return zero tests
    if (!currentTests) {
        return resultTests;
    }
    
    // Find the viewcontroller's class name
    NSString *className = [controller.class description];
    
    // Loop through running tests
    for (NSDictionary *test in currentTests) {
        if ([[test objectForKey:@"controller"] isEqualToString:className]) {
            [resultTests setObject:test forKey:[test objectForKey:@"view_id"]];
        }
    }
    
    return resultTests;
}

- (void)registerController:(UIViewController*)viewController {
    NSLog(@"New controller %@", [viewController description]);
    
    // Store controllers
    if (![registeredControllers containsObject:viewController]) {
        [registeredControllers addObject:viewController];
    }
    
    // Existing controllers    
    UIView *mainView = viewController.view;
    
    if (mainView) {
        NSDictionary *mainViewDict = [self findSubviews:mainView siblingNo:0 parentId:@"0"];
        
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
                NSLog(@"Return (%@): %@", url, str);
            });
        });
    }
}

- (void)trackView:(NSString*)testId {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        
        NSString *url = [NSString stringWithFormat:@"%@tests/%@/view?user=%@", kApiUrl, testId, [[[NSUserDefaults standardUserDefaults] objectForKey:@"fliptest_identifier"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        
        NSURLResponse *response;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (error) {
            // handle error
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"Return (%@): %@", url, str);
        });
    });
}

- (void)trackGoal:(NSString*)testId {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        
        NSString *url = [NSString stringWithFormat:@"%@tests/%@/goal?user=%@", kApiUrl, testId, [[[NSUserDefaults standardUserDefaults] objectForKey:@"fliptest_identifier"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        
        NSURLResponse *response;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (error) {
            // handle error
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"Return (%@): %@", url, str);
        });
    });
}

- (void)viewAppeared:(UIViewController*)viewController {
    NSLog(@"Controller shown %@", [viewController description]);
    
    UIView *mainView = viewController.view;
    
    if (mainView) {
        NSDictionary *tests = [[FlipTest currentFlipTest] testsForController:viewController];
        if ([tests count] > 0) {
            for (NSString *key in tests) {
                NSDictionary *test = [tests objectForKey:key];
                [self trackView:[test objectForKey:@"id"]];
            }
            
            [self runTests:tests onView:mainView siblingNo:0 parentId:@"0"];
        }
    }
    
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

- (void)runTests:(NSDictionary*)tests onView:(UIView*)parentView siblingNo:(int)siblingNo parentId:(NSString*)parentId {
    
    NSString *viewIdentifier = [parentId stringByAppendingFormat:@".%d", siblingNo];
    
    
    if ([parentView isKindOfClass:[UIButton class]]) {
        // Figure out if a test has this button as a conversion goal
        for (NSString *key in tests) {
            NSDictionary *test = [tests objectForKey:key];
            if ([test objectForKey:@"goal_view_id"] && [[test objectForKey:@"goal_view_id"] isEqualToString:viewIdentifier]) {
                UIButton *button = (UIButton*)parentView;
                [button setAction:kUIButtonBlockTouchUpInside withBlock:^{
                    [self trackGoal:[test objectForKey:@"id"]];
                }];
                
                break;
            }
        }
    }
    
    NSDictionary *test = [tests objectForKey:viewIdentifier];
    if (test) {
        // Apply button changes
        if ([parentView isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton*)parentView;
            
            if ([[test objectForKey:@"test_type"] isEqualToString:@"text"]) {
                [button setTitle:[test objectForKey:@"test_value"] forState:UIControlStateNormal];
            } else {
                button.titleLabel.textColor = [UIColor colorFromHexString: [test objectForKey:@"test_value"]];
            }
        }
        
        // Apply label changes
        if ([parentView isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel*)parentView;
            
            if ([[test objectForKey:@"test_type"] isEqualToString:@"text"]) {
                label.text = [test objectForKey:@"test_value"];
            } else {
                label.textColor = [UIColor colorFromHexString: [test objectForKey:@"test_value"]];
            }
        }
        
    }
    
    int i = 0;
    for (UIView *subView in parentView.subviews) {
        [self runTests:tests onView:subView siblingNo:i parentId:viewIdentifier];
        i++;
    }
}

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
        [viewDictionary setObject:((button.titleLabel && button.titleLabel.textColor) ? [button.titleLabel.textColor description] : @"") forKey:@"textColor"];
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

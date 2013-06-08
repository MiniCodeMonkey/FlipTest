//
//  FlipTest.m
//  FlipTest
//
//  Created by Mathias Hansen on 6/8/13.
//  Copyright (c) 2013 AngelHack. All rights reserved.
//

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

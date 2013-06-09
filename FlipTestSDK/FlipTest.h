//
//  FlipTest.h
//  FlipTest
//
//  Created by Mathias Hansen on 6/8/13.
//  Copyright (c) 2013 AngelHack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FlipTest : NSObject {
    NSString *flipTestUserToken;
    NSMutableArray *registeredControllers;
}

+ (id)currentFlipTest;
- (void)startFlipping:(NSString*)userToken;
- (void)registerController:(UIViewController*)viewController;
- (void)eventViewWillAppear:(UIViewController*)viewController;
- (NSDictionary*)testsForController:(UIViewController*)controller;

@end

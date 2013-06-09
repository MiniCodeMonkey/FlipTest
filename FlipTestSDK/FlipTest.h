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
}

+ (id)currentFlipTest;
- (void)goAhead:(NSString*)userToken;
- (void)registerController:(UIViewController*)viewController;
- (void)viewAppeared:(UIViewController*)viewController;
- (NSDictionary*)testsForController:(UIViewController*)controller;

@end

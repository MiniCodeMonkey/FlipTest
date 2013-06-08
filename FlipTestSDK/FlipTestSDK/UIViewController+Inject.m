//
//  UIViewController+Inject.m
//  FlipTestSDK
//
//  Created by Mathias Hansen on 6/8/13.
//  Copyright (c) 2013 AngelHack. All rights reserved.
//

#import "UIViewController+Inject.h"
#import <objc/runtime.h>
#import "FlipTest.h"

@implementation UIViewController (Inject)

void MethodSwizzle(Class c, SEL origSEL, SEL overrideSEL);

- (void)override_viewDidLoad {
    
    [self override_viewDidLoad];
    
    [[FlipTest currentFlipTest] registerController:self];
}

+ (void)load
{
    MethodSwizzle(self, @selector(viewDidLoad), @selector(override_viewDidLoad));
}


void MethodSwizzle(Class c, SEL origSEL, SEL overrideSEL)
{
    Method origMethod = class_getInstanceMethod(c, origSEL);
    Method overrideMethod = class_getInstanceMethod(c, overrideSEL);
    if(class_addMethod(c, origSEL, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod)))
    {
        class_replaceMethod(c, overrideSEL, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    }
    else
    {
        method_exchangeImplementations(origMethod, overrideMethod);
    }
}

@end

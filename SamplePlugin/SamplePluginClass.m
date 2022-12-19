//
//  SamplePluginClass.m
//  SamplePlugin
//
//  Created by robert engels on 1/8/19.
//  Copyright © 2019 robert engels. All rights reserved.
//

#import "SamplePluginClass.h"

@implementation SamplePluginClass

- (NSString *)groupName {
    return @"Sample";
}

- (id)initWithManager:(id<PluginData>)data {
    return self;
}

- (NSString *)name {
    return @"Sample Plugin";
}

- (void)execute {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"You are running the sample plugin!";
    [alert runModal];
}

- (int)points {
    return 0;
}

+ (BOOL)validatePlugin:(id<PluginData>)pluginData
{
    return YES;
}

@end

//
//  SamplePluginClass.m
//  SamplePlugin
//
//  Created by robert engels on 1/8/19.
//  Copyright © 2019 robert engels. All rights reserved.
//

#import "SamplePluginClass.h"

@implementation SamplePluginClass

- (BOOL)canReapply {
    return YES;
}

- (NSString *)groupName {
    return @"Sample";
}

- (id)initWithManager:(PluginData *)data {
    return self;
}

- (NSString *)name {
    return @"Sample Plugin";
}

- (void)reapply {
    [self run];
}

- (void)run {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"You are running the sample plugin!";
    [alert runModal];
}

- (int)type {
    return 0;
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
    return YES;
}

@end

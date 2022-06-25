//
//  Label.m
//  SeaComponents
//
//  Created by robert engels on 3/6/22.
//

#import "Label.h"

@implementation Label

- (Label*)init
{
    self = [super init];
    [self setBezeled:NO];
    [self setDrawsBackground:NO];
    [self setEditable:NO];
    [self setSelectable:NO];
    return self;
}

+(Label*)label
{
    return [[Label alloc] init];
}

@end

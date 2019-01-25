//
//  OptionHelpButton.m
//  Seashore
//
//  Created by robert engels on 1/22/19.
//

#import "OptionHelpButton.h"

@implementation OptionHelpButton

- (id)init
{
    [self setBezelStyle:NSHelpButtonBezelStyle];
    [self setBordered:NO];
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end

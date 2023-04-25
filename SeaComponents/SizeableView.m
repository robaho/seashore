//
//  SizeableView.m
//  SeaComponents
//
//  Created by robert engels on 3/7/22.
//

#import "SizeableView.h"

@implementation SizeableView

- (SizeableView*)init
{
    self = [super init];
    contentSize = NSMakeSize(-1,-1);
    return self;
}
- (void)setIntrinsicContentSize:(NSSize)size
{
    contentSize = size;
}
- (NSSize)intrinsicContentSize
{
    return contentSize;
}

+ (NSView*)withSize:(NSSize)size
{
    SizeableView *s = [[SizeableView alloc] init];
    s->contentSize = size;
    return s;
}

@end

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

@end

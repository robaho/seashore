//
//  SeaSeperator.m
//  SeaComponents
//
//  Created by robert engels on 7/4/22.
//

#import "SeaSeperator.h"

@implementation SeaSeperator

+(SeaSeperator*)withTitle:(NSString*)title
{
    SeaSeperator *s = [[SeaSeperator alloc] init];
    [s setTitle:title];
    [s setBoxType:NSBoxSeparator];
    return s;
}

//-(NSSize)intrinsicContentSize
//{
//    return NSMakeSize(NSViewNoIntrinsicMetric, 16);
//}

@end

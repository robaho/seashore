//
//  CIKeystoneCombinedClass.m
//  CIKeystoneCombined
//
//  Created by robert engels on 12/8/22.
//

#import "CIKeystoneHorizontalClass.h"

@implementation CIKeystoneHorizontalClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIKeystoneCorrectionHorizontal" points:4 bg:TRUE properties:kCI_FocalLength,nil];
}

- (void)execute
{
    CIFilter *filter = [super createFilter];
    [filter setValue:[self pointValue:0] forKey:@"inputTopLeft"];
    [filter setValue:[self pointValue:1] forKey:@"inputTopRight"];
    [filter setValue:[self pointValue:2] forKey:@"inputBottomRight"];
    [filter setValue:[self pointValue:3] forKey:@"inputBottomLeft"];

    [self applyFilter:filter];
}

- (void)detectRectangle{}

@end

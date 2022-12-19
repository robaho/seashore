//
//  CIKeystoneCombinedClass.m
//  CIKeystoneCombined
//
//  Created by robert engels on 12/8/22.
//

#import "CIKeystoneCombinedClass.h"

@implementation CIKeystoneCombinedClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CIKeystoneCorrectionCombined" points:4 bg:TRUE properties:kCI_FocalLength,nil];
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

@end

#import "CIPerspectiveTransformClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIPerspectiveTransformClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CIPerspectiveTransform" points:4 bg:TRUE properties:0];
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

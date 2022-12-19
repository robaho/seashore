#import "CIGloomClass.h"

@implementation CIGloomClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIGloom" points:0 properties:kCI_Radius,kCI_Intensity,0];
}

@end

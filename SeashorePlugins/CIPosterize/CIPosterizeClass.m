#import "CIPosterizeClass.h"

@implementation CIPosterizeClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIColorPosterize" points:0 properties:kCI_Levels,0];
}

@end

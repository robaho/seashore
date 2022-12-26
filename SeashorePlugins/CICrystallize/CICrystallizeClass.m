#import "CICrystallizeClass.h"

@implementation CICrystallizeClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CICrystallize" points:0 bg:TRUE properties:kCI_Radius,kCI_PointCenter,0];
}

@end

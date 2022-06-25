#import "CICheckerboardClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CICheckerboardClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CICheckerboardGenerator" points:2 properties:kCI_PointCenter,kCI_PointWidth,kCI_Color0,kCI_Color1,kCI_Sharpness,0];
}

@end

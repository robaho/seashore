#import "CIVertStripesClass.h"

@implementation CIVertStripesClass

- (id)initWithManager:(id<PluginData>) data
{
    return [super initWithManager:data filter:@"CIStripesGenerator" points:2 properties:kCI_PointCenter,kCI_Width,kCI_Color0,kCI_Color1,kCI_Sharpness,0];
}

@end

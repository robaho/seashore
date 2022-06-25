#import "CIZoomBlurClass.h"

@implementation CIZoomBlurClass

- (id)initWithManager:(PluginData *)data
{
    self = [super initWithManager:data filter:@"CIZoomBlur" points:2 bg:TRUE properties:kCI_PointCenter,kCI_PointRadius,0];
    [self setFilterProperty:kCI_PointRadius property:@"inputAmount"];
    return self;
}

@end

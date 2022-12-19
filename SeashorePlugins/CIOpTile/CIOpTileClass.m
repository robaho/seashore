#import "CIOpTileClass.h"

@implementation CIOpTileClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIOpTile" points:1 properties:kCI_PointCenter,kCI_Width1000,kCI_Angle,kCI_Scale,0];
}


- (void)applyFilter:(CIFilter*)filter
{
    bool opaque = ![pluginData hasAlpha];
    
    if (opaque){
        [self applyFilterBG:filter];
    } else {
        [self applyFilter:filter];
    }
}

+ (BOOL)validatePlugin:(id<PluginData>)pluginData
{
	if (pluginData != NULL) {

		if ([pluginData channel] == kAlphaChannel)
			return NO;

	}
	
	return YES;
}

@end

#import "CIOpTileClass.h"

@implementation CIOpTileClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CIOpTile" points:1 properties:kCI_PointCenter,kCI_Width1000,kCI_Angle,kCI_Scale,0];
}


- (void)applyFilter:(CIFilter*)filter
{
    bool opaque = ![pluginData hasAlpha];
    
    if (opaque){
        applyFilterBG(pluginData,filter);
    } else {
        applyFilter(pluginData,filter);
    }
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	if (pluginData != NULL) {

		if ([pluginData channel] == kAlphaChannel)
			return NO;
		
		if ([pluginData spp] == 2)
			return NO;
	
	}
	
	return YES;
}

@end

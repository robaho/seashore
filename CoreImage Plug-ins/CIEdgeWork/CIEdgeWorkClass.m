#import "CIEdgeWorkClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIEdgeWorkClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CIEdgeWork" points:0 properties:kCI_Radius,0];
}

- (void)applyFilter:(CIFilter*)filter
{
    bool opaque = ![pluginData hasAlpha];

    if (opaque){
        applyFilterFGBG(pluginData,filter);
    } else {
        applyFilterFG(pluginData,filter);
    }
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end

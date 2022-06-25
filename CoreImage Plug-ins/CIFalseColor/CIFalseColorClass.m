#import "CIFalseColorClass.h"

@implementation CIFalseColorClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CIFalseColor" points:0 properties:kCI_Color0,kCI_Color1,0];
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end

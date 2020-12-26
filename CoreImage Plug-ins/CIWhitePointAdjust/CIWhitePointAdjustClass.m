#import "CIWhitePointAdjustClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIWhitePointAdjustClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"White Point" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Color" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	[self execute];
	[pluginData apply];
	success = YES;
}

- (void)reapply
{
	[self run];
}

- (BOOL)canReapply
{
	return success;
}

- (void)execute
{
    CIColor *foreColor = createCIColor([pluginData foreColor]);
    
    CIFilter *filter = [CIFilter filterWithName:@"CIWhitePointAdjust"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIWhitePointAdjust"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:foreColor forKey:@"inputColor"];

    applyFilter(pluginData,filter);
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end

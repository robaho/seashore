#import "CIInvertClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIInvertClass

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
	return [gOurBundle localizedStringForKey:@"name" value:@"Invert" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Color Effect" table:NULL];
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
    CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIColorInvert"] userInfo:NULL];
    }
    [filter setDefaults];

    applyFilter(pluginData,filter);
}
+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end

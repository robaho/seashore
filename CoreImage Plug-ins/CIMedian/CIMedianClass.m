#import "CIMedianClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIMedianClass

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
	return [gOurBundle localizedStringForKey:@"name" value:@"Median" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Enhance" table:NULL];
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
    CIFilter *filter = [CIFilter filterWithName:@"CIMedianFilter"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIMedianFilter"] userInfo:NULL];
    }
    [filter setDefaults];
    
    applyFilter(pluginData,filter);
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end

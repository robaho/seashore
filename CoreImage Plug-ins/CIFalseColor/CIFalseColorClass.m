#import "CIFalseColorClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIFalseColorClass

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
	return [gOurBundle localizedStringForKey:@"name" value:@"Color Ramp" table:NULL];
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
    CIColor *foreColor = createCIColor([pluginData foreColor]);
    CIColor *backColor = createCIColor([pluginData backColor]);
    
    CIFilter *filter = [CIFilter filterWithName:@"CIFalseColor"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIFalseColor"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:foreColor forKey:@"inputColor0"];
    [filter setValue:backColor forKey:@"inputColor1"];

    applyFilter(pluginData,filter);
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end

#import "CIZoomBlurClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIZoomBlurClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	
	return self;
}

- (int)type
{
	return 1;
}

- (int)points
{
	return 2;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Zoom Blur" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Blur" table:NULL];
}

- (NSString *)instruction
{
	return [gOurBundle localizedStringForKey:@"instruction" value:@"Needs localization." table:NULL];
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
	return NO;
}

- (void)execute
{
    int height = [pluginData height];
    IntPoint point = [pluginData point:0];
    IntPoint apoint = [pluginData point:1];
    
    int radius = calculateRadius(point,apoint);
    radius = MIN(200, MAX(radius, 0));

    
    bool opaque = ![pluginData hasAlpha];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIZoomBlur"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIZoomBlur"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[CIVector vectorWithX:point.x Y:height - point.y] forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithFloat:radius] forKey:@"inputAmount"];
    
    if (opaque) {
        applyFilterBG(pluginData,filter);
    }
    else {
        applyFilter(pluginData,filter);
    }
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end

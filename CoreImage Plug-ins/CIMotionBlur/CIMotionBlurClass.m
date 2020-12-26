#import "CIMotionBlurClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIMotionBlurClass

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
	return [gOurBundle localizedStringForKey:@"name" value:@"Motion Blur" table:NULL];
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
    
    int radius;
    float angle = calculateAngle(point,apoint);
    
    radius = (apoint.x - point.x) * (apoint.x - point.x) + (apoint.y - point.y) * (apoint.y - point.y);
    radius = sqrt(radius);
    radius = MIN(100, MAX(radius, 0));
    
    CIFilter *filter = [CIFilter filterWithName:@"CIMotionBlur"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIMotionBlur"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:angle] forKey:@"inputAngle"];
    [filter setValue:[NSNumber numberWithInt:radius] forKey:@"inputRadius"];
    
    bool opaque = ![pluginData hasAlpha];
    
    if (opaque){
        applyFilterBG(pluginData,filter);
    } else {
        applyFilter(pluginData,filter);
    }
    
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end

#import "CIAutoEnhanceClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIAutoEnhanceClass

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
    CIImage *myImage = createCIImage(pluginData);
    
    NSArray *adjustments = [myImage autoAdjustmentFilters];
    for (CIFilter *filter in adjustments) {
        [filter setValue:myImage forKey:kCIInputImageKey];
        myImage = filter.outputImage;
    }
    
    renderCIImage(pluginData,myImage);
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end

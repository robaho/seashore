#import "CIAutoEnhanceClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIAutoEnhanceClass

- (id)initWithManager:(id<PluginData>)data
{
    self = [super initWithManager:data filter:NULL points:0 properties:NULL];

	return self;
}

- (void)execute
{
    CIImage *myImage = [self createCIImage];

    NSArray *adjustments = [myImage autoAdjustmentFilters];
    for (CIFilter *filter in adjustments) {
        [filter setValue:myImage forKey:kCIInputImageKey];
        myImage = [filter valueForKey: @"outputImage"];
    }
    
    [self renderCIImage:myImage];
}

@end

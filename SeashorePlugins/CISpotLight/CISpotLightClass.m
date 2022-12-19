#import "CISpotLightClass.h"

@implementation CISpotLightClass

- (id)initWithManager:(id<PluginData>)data
{
    self = [super initWithManager:data filter:@"CISpotLight" points:2 bg:TRUE properties:kCI_Brightness100,kCI_Concentration,kCI_Color,0];

    int maxHeight = MAX([data width],[data height]);

    srcHeight = [SeaSlider sliderWithTitle:@"Source Height" Min:0 Max:maxHeight Listener:self];
    [srcHeight setFloatValue:maxHeight*.10];
    dstHeight = [SeaSlider sliderWithTitle:@"Destination Height" Min:0 Max:maxHeight Listener:self];
    [panel addSubviews:srcHeight,dstHeight,NULL];

	return self;
}

- (void)execute
{
    int height = [pluginData height];
    IntPoint point = [pluginData point:0];
    IntPoint apoint = [pluginData point:1];

    CIFilter *filter = [super createFilter];
    [filter setValue:[CIVector vectorWithX:point.x Y:height - point.y Z:[srcHeight floatValue]] forKey:@"inputLightPosition"];
    [filter setValue:[CIVector vectorWithX:apoint.x Y:height - apoint.y Z:[dstHeight floatValue]] forKey:@"inputLightPointsAt"];

    [super applyFilter:filter];
}


@end

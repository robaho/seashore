#import <SeaComponents/SeaComponents.h>
#import "ColorLevelsClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation ColorLevelsClass

- (id)initWithManager:(PluginData *)data
{
    self = [super initWithManager:data filter:@"CIColorCurves" points:0 properties:NULL];

	pluginData = data;

    panel = [VerticalView view];

    redShadow = [SeaSlider compactSliderWithTitle:@"Shadow" Min:0 Max:1 Listener:self];
    redMid = [SeaSlider compactSliderWithTitle:@"Mid" Min:0 Max:1 Listener:self];
    redHighlight = [SeaSlider compactSliderWithTitle:@"Highlight" Min:0 Max:1 Listener:self];

    greenShadow = [SeaSlider compactSliderWithTitle:@"Shadow" Min:0 Max:1 Listener:self];
    greenMid = [SeaSlider compactSliderWithTitle:@"Mid" Min:0 Max:1 Listener:self];
    greenHighlight = [SeaSlider compactSliderWithTitle:@"Highlight" Min:0 Max:1 Listener:self];

    blueShadow = [SeaSlider compactSliderWithTitle:@"Shadow" Min:0 Max:1 Listener:self];
    blueMid = [SeaSlider compactSliderWithTitle:@"Mid" Min:0 Max:1 Listener:self];
    blueHighlight = [SeaSlider compactSliderWithTitle:@"Highlight" Min:0 Max:1 Listener:self];

    [panel addSubview:[SeaSeperator withTitle:@"Red"]];
    [panel addSubview:redShadow];
    [panel addSubview:redMid];
    [panel addSubview:redHighlight];

    [panel addSubview:[SeaSeperator withTitle:@"Green"]];
    [panel addSubview:greenShadow];
    [panel addSubview:greenMid];
    [panel addSubview:greenHighlight];

    [panel addSubview:[SeaSeperator withTitle:@"Blue"]];
    [panel addSubview:blueShadow];
    [panel addSubview:blueMid];
    [panel addSubview:blueHighlight];

    return self;
}

- (int)points
{
    return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Color Levels" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Color Adjust" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (NSView*)initialize
{
    [redShadow setFloatValue:0];
    [greenShadow setFloatValue:0];
    [blueShadow setFloatValue:0];

    [redMid setFloatValue:0.5];
    [greenMid setFloatValue:0.5];
    [blueMid setFloatValue:0.5];

    [redHighlight setFloatValue:1.0];
    [greenHighlight setFloatValue:1.0];
    [blueHighlight setFloatValue:1.0];

    return panel;
}

- (void)componentChanged:(id)slider
{
    [pluginData settingsChanged];
}

- (void)execute
{
    CIFilter *filter = [self getFilterInstance:filterName];

    Float32 data[9];

    data[0] = [redShadow floatValue];
    data[1] = [greenShadow floatValue];
    data[2] = [blueShadow floatValue];

    data[3] = [redMid floatValue];
    data[4] = [greenMid floatValue];
    data[5] = [blueMid floatValue];

    data[6] = [redHighlight floatValue];
    data[7] = [greenHighlight floatValue];
    data[8] = [blueHighlight floatValue];

    NSData *nsdata = [NSData dataWithBytes:data length:sizeof(Float32)*9];

    [filter setValue:nsdata forKey:@"inputCurvesData"];

    applyFilter(pluginData,filter);
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end

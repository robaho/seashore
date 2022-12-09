#import "BucketOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"

@implementation BucketOptions

- (id)init:(id)document
{
    self = [super init:document];

    [super clearModifierMenu];
    [super addModifierMenuItem:@"Flood entire selection (Option)" tag:1];
    [super addModifierMenuItem:@"Preview flood (Shift)" tag:2];

    [brushesButton setHidden:true];

    toleranceSlider = [SeaSlider compactSliderWithTitle:@"Tolerance" Min:0 Max:255 Listener:NULL];
    [self addSubview:toleranceSlider];

    int value;
	if ([gUserDefaults objectForKey:@"bucket tolerance"] == NULL) {
        value = 15;
	}
	else {
		value = [gUserDefaults integerForKey:@"bucket tolerance"];
	}
    [toleranceSlider setIntValue:value];

    [super loadOpacity:@"bucket opacity"];
    return self;
}

- (int)tolerance
{
	return [toleranceSlider intValue];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[toleranceSlider intValue] forKey:@"bucket tolerance"];
    [gUserDefaults setInteger:[opacitySlider intValue] forKey:@"bucket opacity"];
}

@end

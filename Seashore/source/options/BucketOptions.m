#import "BucketOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaPrefs.h"

@implementation BucketOptions

- (id)init:(id)document
{
    self = [super init:document];

    NSControlSize size = [[SeaController seaPrefs] controlSize];

    [brushesButton setHidden:true];

    toleranceSlider = [SeaSlider compactSliderWithTitle:@"Tolerance" Min:0 Max:255 Listener:NULL Size:size];
    [self addSubview:toleranceSlider];

    fillAllRegions = [SeaCheckbox checkboxWithTitle:@"Fill all regions" Listener:NULL Size:size];
    [self addSubview:fillAllRegions];


    int value;
	if ([gUserDefaults objectForKey:@"bucket tolerance"] == NULL) {
        value = 15;
	}
	else {
		value = [gUserDefaults integerForKey:@"bucket tolerance"];
	}
    [toleranceSlider setIntValue:value];

    [fillAllRegions setChecked:[gUserDefaults boolForKey:@"wand fillAllRegions"]];

    [super loadOpacity:@"bucket opacity"];
    return self;
}

- (int)tolerance
{
	return [toleranceSlider intValue];
}

- (bool)fillAllRegions
{
    return [fillAllRegions isChecked];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[toleranceSlider intValue] forKey:@"bucket tolerance"];
    [gUserDefaults setInteger:[opacitySlider intValue] forKey:@"bucket opacity"];
    [gUserDefaults setBool:[fillAllRegions isChecked] forKey:@"bucket fillAllRegions"];

}

@end

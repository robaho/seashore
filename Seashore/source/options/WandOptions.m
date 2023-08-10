#import "WandOptions.h"
#import "SeaSelection.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaPrefs.h"

@implementation WandOptions

- (id)init:(id)document
{
    self = [super init:document];

    NSControlSize size = [[SeaController seaPrefs] controlSize];

    toleranceSlider = [SeaSlider compactSliderWithTitle:@"Tolerance" Min:0 Max:255 Listener:NULL Size:size];
    [self addSubview:toleranceSlider];

    selectAllRegions = [SeaCheckbox checkboxWithTitle:@"Select all regions" Listener:NULL Size:size];
    [self addSubview:selectAllRegions];

	int value;
	if ([gUserDefaults objectForKey:@"wand tolerance"] == NULL) {
		[toleranceSlider setIntValue:15];
	}
	else {
		value = [gUserDefaults integerForKey:@"wand tolerance"];
		[toleranceSlider setIntValue:value];
	}
    if ([gUserDefaults objectForKey:@"wand selectAllRegions"] == NULL) {
    }
    else {
        bool b = [gUserDefaults boolForKey:@"wand selectAllRegions"];
        [selectAllRegions setChecked:b];
    }

    return self;
}

- (int)tolerance
{
	return [toleranceSlider intValue];
}

- (bool)selectAllRegions
{
    return [selectAllRegions isChecked];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[toleranceSlider intValue] forKey:@"wand tolerance"];
    [gUserDefaults setBool:[selectAllRegions isChecked] forKey:@"wand selectAllRegions"];
}

@end

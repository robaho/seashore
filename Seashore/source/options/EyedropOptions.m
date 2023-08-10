#import "EyedropOptions.h"
#import "ToolboxUtility.h"
#import "SeaHelp.h"
#import "SeaController.h"
#import "SeaTools.h"
#import "SeaPrefs.h"

@implementation EyedropOptions

- (id)init:document
{
    self = [super init:document];

    NSControlSize size = [[SeaController seaPrefs] controlSize];

    [super clearModifierMenu];
    [super addModifierMenuItem:@"Select background color" tag:1];

    sizeSlider = [SeaSlider compactSliderWithTitle:@"Sample size" Min:1 Max:11 Listener:NULL Size:size];
    [self addSubview:sizeSlider];
    mergedCheckbox = [SeaCheckbox checkboxWithTitle:@"Use sample from all layers" Listener:NULL Size:size];
    [self addSubview:mergedCheckbox];

	int value;
	
	if ([gUserDefaults objectForKey:@"eyedrop size"] == NULL) {
		value = 1;
	}
	else {
		value = [gUserDefaults integerForKey:@"eyedrop size"];
	}
	[sizeSlider setIntValue:value];
	[mergedCheckbox setChecked:[gUserDefaults boolForKey:@"eyedrop merged"]];

    return self;
}

- (int)sampleSize
{
	return [sizeSlider intValue];
}

- (BOOL)mergedSample
{
	return [mergedCheckbox isChecked];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[self sampleSize] forKey:@"eyedrop size"];
    [gUserDefaults setBool:[self mergedSample] forKey:@"eyedrop merged"];
}

@end

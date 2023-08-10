#import "PencilOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaDocument.h"
#import "SeaPrefs.h"

@implementation PencilOptions

- (id)init:(id)document
{
    self = [super init:document];

    [brushesButton setHidden:true];
    [fadeSlider setHidden:true];
    [pressurePopup setHidden:true];
    [scalingCheckbox setHidden:true];

    NSControlSize size = [[SeaController seaPrefs] controlSize];

    sizeSlider = [SeaSlider compactSliderWithTitle:@"Pencil size" Min:1 Max:100 Listener:NULL Size:size];
    [self addSubview:sizeSlider];

	int value;
	
	if ([gUserDefaults objectForKey:@"pencil size"] == NULL) {
		value = 1;
	}
	else {
		value = [gUserDefaults integerForKey:@"pencil size"];
	}
	[sizeSlider setIntValue:value];

    circularTipCheckbox = [SeaCheckbox checkboxWithTitle:@"Circular tip" Listener:NULL Size:size];
    [self addSubview:circularTipCheckbox];

    if ([gUserDefaults objectForKey:@"pencil circular tip"] == NULL) {
        [circularTipCheckbox setChecked:TRUE];
    }
    else {
        bool value = [gUserDefaults boolForKey:@"pencil circular tip"];
        [circularTipCheckbox setChecked:value];
    }

    [super loadOpacity:@"pencil opacity"];

	isErasing = NO;

    return self;
}

- (int)pencilSize
{
	return [sizeSlider intValue];
}

- (bool)circularTip
{
    return [circularTipCheckbox isChecked];
}

- (void)setPencilSize:(int)pencilSize
{
    [sizeSlider setIntValue:pencilSize];
    [self update:sizeSlider];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[sizeSlider intValue] forKey:@"pencil size"];
    [gUserDefaults setBool:[circularTipCheckbox isChecked] forKey:@"pencil circular tip"];
    [gUserDefaults setInteger:[opacitySlider intValue] forKey:@"pencil opacity"];
}

@end

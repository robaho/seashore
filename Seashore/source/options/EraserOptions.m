#import "EraserOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"

@implementation EraserOptions

- (id)init:(id)document
{
    self = [super init:document];

    [texturesButton setHidden:true];
    [fadeSlider setHidden:true];
    [pressurePopup setHidden:true];
    [scalingCheckbox setHidden:true];

	int value;

    mimicBrushCheckbox = [SeaCheckbox checkboxWithTitle:@"Mimic Brush Fading" Listener:NULL];
    [self addSubview:mimicBrushCheckbox];
	
	if ([gUserDefaults objectForKey:@"eraser opacity"] == NULL) {
		value = 100;
	}
	else {
		value = [gUserDefaults integerForKey:@"eraser opacity"];
	}
	[opacitySlider setIntValue:value];
	[mimicBrushCheckbox setChecked:[gUserDefaults boolForKey:@"eraser mimicBrush"]];

    return self;
}

- (BOOL)brushIsErasing
{
    return TRUE;
}

- (BOOL)mimicBrush
{
	return [mimicBrushCheckbox isChecked];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[opacitySlider intValue] forKey:@"eraser opacity"];
	[gUserDefaults setObject:[mimicBrushCheckbox isChecked] ? @"YES" : @"NO" forKey:@"eraser mimicBrush"];
}

@end

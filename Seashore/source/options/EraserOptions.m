#import "EraserOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "SeaHelp.h"
#import "SeaTools.h"

@implementation EraserOptions

- (void)awakeFromNib
{
	int value;
	
	if ([gUserDefaults objectForKey:@"eraser opacity"] == NULL) {
		value = 100;
	}
	else {
		value = [gUserDefaults integerForKey:@"eraser opacity"];
		if (value < [opacitySlider minValue] || value > [opacitySlider maxValue])
			value = 100;
	}
	[opacitySlider setIntValue:value];
	[opacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"opacity", @"Opacity: %d%%"), value]];
	[mimicBrushCheckbox setState:[gUserDefaults boolForKey:@"eraser mimicBrush"]];
}

- (IBAction)opacityChanged:(id)sender
{		
	[opacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"opacity", @"Opacity: %d%%"), [opacitySlider intValue]]];
}

- (int)opacity
{
	return [opacitySlider intValue] * 2.55;
}

- (BOOL)mimicBrush
{
	return [mimicBrushCheckbox state];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[opacitySlider intValue] forKey:@"eraser opacity"];
	[gUserDefaults setObject:[mimicBrushCheckbox state] ? @"YES" : @"NO" forKey:@"eraser mimicBrush"];
}

@end

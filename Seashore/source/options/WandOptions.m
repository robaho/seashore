#import "WandOptions.h"
#import "SeaSelection.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "SeaHelp.h"
#import "SeaTools.h"

@implementation WandOptions

- (void)awakeFromNib
{
	int value;
	
	if ([gUserDefaults objectForKey:@"wand tolerance"] == NULL) {
		[toleranceSlider setIntValue:15];
		[toleranceLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"tolerance", @"Tolerance: %d"), 15]];
	}
	else {
		value = [gUserDefaults integerForKey:@"wand tolerance"];
		if (value < 0 || value > 255)
			value = 0;
		[toleranceSlider setIntValue:value];
		[toleranceLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"tolerance", @"Tolerance: %d"), value]];
	}
	
	if([gUserDefaults objectForKey:@"wand intervals"] == NULL){
		[intervalsSlider setIntValue:15];
	}else{
		value = [gUserDefaults integerForKey:@"wand intervals"];
		[intervalsSlider setIntValue: value];
	}
}

- (IBAction)toleranceSliderChanged:(id)sender
{
	[toleranceLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"tolerance", @"Tolerance: %d"), [toleranceSlider intValue]]];
}

- (int)tolerance
{
	return [toleranceSlider intValue];
}

- (int)numIntervals
{
	return [intervalsSlider intValue];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[toleranceSlider intValue] forKey:@"wand tolerance"];
	[gUserDefaults setInteger:[intervalsSlider intValue] forKey:@"wand intervals"];
}

@end

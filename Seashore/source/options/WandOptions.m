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
    if ([gUserDefaults objectForKey:@"wand selectAllRegions"] == NULL) {
        [selectAllRegions setState:NSOffState];
    }
    else {
        bool b = [gUserDefaults boolForKey:@"wand selectAllRegions"];
        if(b) {
            [selectAllRegions setState:NSOnState];
        } else {
            [selectAllRegions setState:NSOffState];
        }
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

- (bool)selectAllRegions
{
    return [selectAllRegions state] == NSOnState;
}

- (void)shutdown
{
	[gUserDefaults setInteger:[toleranceSlider intValue] forKey:@"wand tolerance"];
    [gUserDefaults setBool:[selectAllRegions state]==NSOnState forKey:@"wand selectAllRegions"];
}

@end

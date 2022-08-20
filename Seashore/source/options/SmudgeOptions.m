#import "SmudgeOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"

@implementation SmudgeOptions

- (void)awakeFromNib
{
	int value;
	
	if ([gUserDefaults objectForKey:@"smudge rate"] == NULL) {
		value = 50;
	}
	else {
		value = [gUserDefaults integerForKey:@"smudge rate"];
		if (value < 0 || value > 100)
			value = 50;
	}
	[rateSlider setIntValue:value];
	[rateLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"rate", @"Rate: %d%%"), value]];

    if ([gUserDefaults objectForKey:@"brush pressure"] == NULL) {
        [pressureCheckbox setState:NSOffState];
        [pressurePopup selectItemAtIndex:kLinear];
        [pressurePopup setEnabled:NO];
    }
    else {
        int style = [gUserDefaults integerForKey:@"smudge pressure style"];
        if (style < kQuadratic || style > kSquareRoot)
            style = kLinear;
        BOOL pressureOn = [gUserDefaults boolForKey:@"smudge pressure"];
        [pressureCheckbox setState:pressureOn];
        [pressurePopup selectItemAtIndex:style];
        [pressurePopup setEnabled:pressureOn];
    }
}

- (IBAction)rateChanged:(id)sender
{		
	[rateLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"rate", @"Rate: %d%%"), [rateSlider intValue]]];
}

- (int)rate
{
	return [rateSlider intValue] * 2.55;
}

- (void)shutdown
{
	[gUserDefaults setInteger:[rateSlider intValue] forKey:@"smudge rate"];
    [gUserDefaults setObject:[pressureCheckbox state] ? @"YES" : @"NO" forKey:@"smudge pressure"];
    [gUserDefaults setInteger:[pressurePopup indexOfSelectedItem] forKey:@"smudge pressure style"];
}

@end

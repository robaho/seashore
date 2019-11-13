#import "BucketOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "SeaHelp.h"
#import "SeaTools.h"

@implementation BucketOptions

- (void)awakeFromNib
{
	int value;
	
	if ([gUserDefaults objectForKey:@"bucket tolerance"] == NULL) {
        [self setTolerance:15];
	}
	else {
		value = [gUserDefaults integerForKey:@"bucket tolerance"];
        [self setTolerance:value];
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

- (void)setTolerance:(int)value
{
    if (value < 0 || value > 255)
        value = 0;
    [toleranceSlider setIntValue:value];
    [self toleranceSliderChanged:toleranceSlider];
}

- (BOOL)useTextures
{
	return [[SeaController seaPrefs] useTextures];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[toleranceSlider intValue] forKey:@"bucket tolerance"];
}

@end

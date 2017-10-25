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
		[toleranceSlider setIntValue:15];
		[toleranceLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"tolerance", @"Tolerance: %d"), 15]];
	}
	else {
		value = [gUserDefaults integerForKey:@"bucket tolerance"];
		if (value < 0 || value > 255)
			value = 0;
		[toleranceSlider setIntValue:value];
		[toleranceLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"tolerance", @"Tolerance: %d"), value]];
	}
	
	if([gUserDefaults objectForKey:@"bucket intervals"] == NULL){
		[intervalsSlider setIntValue:15];
	}else{
		value = [gUserDefaults integerForKey:@"bucket intervals"];
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

- (BOOL)useTextures
{
	return [[SeaController seaPrefs] useTextures];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[toleranceSlider intValue] forKey:@"bucket tolerance"];
	[gUserDefaults setInteger:[intervalsSlider intValue] forKey:@"bucket intervals"];
}

@end

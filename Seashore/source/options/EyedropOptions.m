#import "EyedropOptions.h"
#import "ToolboxUtility.h"
#import "SeaHelp.h"
#import "SeaController.h"
#import "SeaTools.h"

@implementation EyedropOptions

- (void)awakeFromNib
{
	int value;
	
	if ([gUserDefaults objectForKey:@"eyedrop size"] == NULL) {
		value = 1;
	}
	else {
		value = [gUserDefaults integerForKey:@"eyedrop size"];
		if (value < [sizeSlider minValue] || value > [sizeSlider maxValue])
			value = 1;
	}
	[sizeSlider setIntValue:value];
	[mergedCheckbox setState:[gUserDefaults boolForKey:@"eyedrop merged"]];
}

- (int)sampleSize
{
	return [sizeSlider intValue];
}

- (BOOL)mergedSample
{
	return [mergedCheckbox state];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[self sampleSize] forKey:@"eyedrop size"];
	[gUserDefaults setObject:[self mergedSample] ? @"YES" : @"NO" forKey:@"eyedrop merged"];
}

@end

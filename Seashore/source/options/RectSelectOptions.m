#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaDocument.h"
#import "RectSelectOptions.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaContent.h"
#import "SeaSelection.h"
#import "SeaOperations.h"
#import "SeaMargins.h"
#import "Units.h"
#import "AspectRatio.h"

@implementation RectSelectOptions

- (void)awakeFromNib
{	
	int value;
	
	if ([gUserDefaults objectForKey:@"rect selection radius enabled"] == NULL)
		[radiusCheckbox setState:NSOffState];
	else
		[radiusCheckbox setState:[gUserDefaults boolForKey:@"rect selection radius enabled"]];
	[radiusSlider setEnabled:[radiusCheckbox state]];
	
	if ([gUserDefaults objectForKey:@"rect selection radius"] == NULL) {
		value = 8;
	}
	else {
		value = [gUserDefaults integerForKey:@"rect selection radius"];
		if (value < [radiusSlider minValue] || value > [radiusSlider maxValue])
			value = 8;
	}
	[radiusSlider setIntValue:value];
	[radiusCheckbox setTitle:[NSString stringWithFormat:LOCALSTR(@"corner radius", @"Corner radius: %d"), value]];
	[aspectRatio awakeWithMaster:self andString:@"rect"];
}

- (int)radius
{
	if ([radiusCheckbox state])
		return [radiusSlider intValue];
	else
		return 0;
}

- (NSSize)ratio
{
	return [aspectRatio ratio];
}

- (int)aspectType
{
	return [aspectRatio aspectType];
}

- (IBAction)update:(id)sender;
{
	[radiusCheckbox setTitle:[NSString stringWithFormat:LOCALSTR(@"corner radius", @"Corner radius: %d"), [radiusSlider intValue]]];
	[radiusSlider setEnabled:[radiusCheckbox state]];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[radiusSlider intValue] forKey:@"rect selection radius"];
	[gUserDefaults setObject:[radiusCheckbox state] ? @"YES" : @"NO" forKey:@"rect selection radius enabled"];
	[aspectRatio shutdown];
}

@end

#import "PencilOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaDocument.h"

@implementation PencilOptions

- (void)awakeFromNib
{
	int value;
	
	if ([gUserDefaults objectForKey:@"pencil size"] == NULL) {
		value = 1;
	}
	else {
		value = [gUserDefaults integerForKey:@"pencil size"];
		if (value < [sizeSlider minValue] || value > [sizeSlider maxValue])
			value = 1;
	}
	[sizeSlider setIntValue:value];

    if ([gUserDefaults objectForKey:@"pencil circular tip"] == NULL) {
        [circularTip setState:NSOnState];
    }
    else {
        bool value = [gUserDefaults boolForKey:@"pencil circular tip"];
        [circularTip setState:(value ? NSOnState : NSOffState)];
    }

	isErasing = NO;
}

- (int)pencilSize
{
	return [sizeSlider intValue];
}

- (bool) circularTip
{
    return [circularTip state] == NSOnState;
}

- (void)setPencilSize:(int)pencilSize
{
    [sizeSlider setIntValue:pencilSize];
    [self update:sizeSlider];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[sizeSlider intValue] forKey:@"pencil size"];
    [gUserDefaults setBool:[self circularTip] forKey:@"pencil circular tip"];
}

@end

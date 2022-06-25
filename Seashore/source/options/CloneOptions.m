#import "CloneOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "CloneTool.h"
#import "SeaDocument.h"
#import "SeaTools.h"

@implementation CloneOptions

- (void)awakeFromNib
{
	[mergedCheckbox setState:[gUserDefaults boolForKey:@"clone merged"]];

    int value;
    if ([gUserDefaults objectForKey:@"clone opacity"] == NULL) {
        value = 100;
    }
    else {
        value = [gUserDefaults integerForKey:@"clone opacity"];
        if (value < [opacitySlider minValue] || value > [opacitySlider maxValue])
            value = 100;
    }
    [opacitySlider setIntValue:value];
    [opacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"opacity", @"Opacity: %d%%"), value]];

}

- (BOOL)mergedSample
{
	return [mergedCheckbox state];
}

- (IBAction)opacityChanged:(id)sender {
    [opacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"opacity", @"Opacity: %d%%"), [opacitySlider intValue]]];
}

- (int)opacity
{
    return [opacitySlider intValue] * 2.55;
}

- (IBAction)mergedChanged:(id)sender
{
	id cloneTool = [[document tools] getTool:kCloneTool];

	[cloneTool endLineDrawing];
}

- (IBAction)update:(id)sender
{
	id cloneTool = [[document tools] getTool:kCloneTool];
	IntPoint sourcePoint;
	
	if ([cloneTool sourceSet]) {
		sourcePoint = [cloneTool sourcePoint:YES];
		if ([cloneTool sourceName] != NULL)
			[sourceLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"source set", @"Source: (%d, %d) from \"%@\""), sourcePoint.x, sourcePoint.y, [cloneTool sourceName]]];
		else
			[sourceLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"source set document", @"Source: (%d, %d) from whole document"), sourcePoint.x, sourcePoint.y]];
	}
	else {
		[sourceLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"source unset", @"Source: Unset")]];
	}
}

- (void)shutdown
{
	[gUserDefaults setObject:[self mergedSample] ? @"YES" : @"NO" forKey:@"clone merged"];
    [gUserDefaults setInteger:[opacitySlider intValue] forKey:@"clone opacity"];
}

@end

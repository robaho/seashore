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
    [super loadOpacity:@"clone opacity"];
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

- (BOOL)useTextures
{
    return FALSE;
}

- (BOOL)brushIsErasing
{
    return FALSE;
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

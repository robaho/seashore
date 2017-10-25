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
}

- (BOOL)mergedSample
{
	return [mergedCheckbox state];
}

- (IBAction)mergedChanged:(id)sender
{
	id cloneTool = [[document tools] getTool:kCloneTool];

	[cloneTool unset];
}

- (void)update
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
}

@end

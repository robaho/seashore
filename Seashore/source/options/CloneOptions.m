#import "CloneOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "CloneTool.h"
#import "SeaDocument.h"
#import "SeaTools.h"

@implementation CloneOptions

- (id)init:(id)document
{
    self = [super init:document];

    [super clearModifierMenu];
    [self addModifierMenuItem:@"Mark source (Option)" tag:1];

    [texturesButton setHidden:true];
    [fadeSlider setHidden:true];
    [pressurePopup setHidden:true];
    [scalingCheckbox setHidden:true];

    sourceLabel = [Label compactLabel];
    [self addSubview:sourceLabel];

    mergedCheckbox = [SeaCheckbox checkboxWithTitle:@"Use sample from all layers" Listener:self];
    [self addSubview:mergedCheckbox];

    [mergedCheckbox setChecked:[gUserDefaults boolForKey:@"clone merged"]];

    [super loadOpacity:@"clone opacity"];

    [self componentChanged:self];

    return self;
}

- (BOOL)mergedSample
{
	return [mergedCheckbox isChecked];
}

- (BOOL)useTextures
{
    return FALSE;
}

- (BOOL)brushIsErasing
{
    return FALSE;
}

- (void)update:(id)sender
{
    [self componentChanged:sender];
}

- (void)componentChanged:(id)sender
{
	id cloneTool = [[document tools] getTool:kCloneTool];
	IntPoint sourcePoint;

	if ([cloneTool sourceSet]) {
		sourcePoint = [cloneTool sourcePoint:YES];
		if ([cloneTool sourceName] != NULL)
			[sourceLabel setTitle:[NSString stringWithFormat:LOCALSTR(@"source set", @"Source: (%d, %d) from \"%@\""), sourcePoint.x, sourcePoint.y, [cloneTool sourceName]]];
		else
			[sourceLabel setTitle:[NSString stringWithFormat:LOCALSTR(@"source set document", @"Source: (%d, %d) from whole document"), sourcePoint.x, sourcePoint.y]];
	}
	else {
		[sourceLabel setTitle:[NSString stringWithFormat:LOCALSTR(@"source unset", @"Source: Unset")]];
	}
}

- (void)shutdown
{
	[gUserDefaults setBool:[mergedCheckbox isChecked] forKey:@"clone merged"];
    [gUserDefaults setInteger:[opacitySlider intValue] forKey:@"clone opacity"];
}

@end

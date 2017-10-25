#import "AbstractPaintOptions.h"

#import "SeaController.h"
#import "UtilitiesManager.h"
#import "BrushUtility.h"
#import "TextureUtility.h"

@implementation AbstractPaintOptions
- (IBAction)toggleTextures:(id)sender
{
	NSWindow *w = [gCurrentDocument window];
	NSPoint p = [w convertBaseToScreen:[w mouseLocationOutsideOfEventStream]];
	[(BrushUtility *)[[SeaController utilitiesManager] textureUtilityFor:gCurrentDocument] showPanelFrom: p onWindow: w];
}

- (IBAction)toggleBrushes:(id)sender
{
	NSWindow *w = [gCurrentDocument window];
	NSPoint p = [w convertBaseToScreen:[w mouseLocationOutsideOfEventStream]];
	[(TextureUtility *)[[SeaController utilitiesManager] brushUtilityFor:gCurrentDocument] showPanelFrom: p onWindow: w];
}

@end

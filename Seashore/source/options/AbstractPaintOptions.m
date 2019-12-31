#import "AbstractPaintOptions.h"

#import "SeaController.h"
#import "BrushUtility.h"
#import "TextureUtility.h"
#import "SeaDocument.h"

@implementation AbstractPaintOptions
- (IBAction)toggleTextures:(id)sender
{
	NSWindow *w = [gCurrentDocument window];
	NSPoint p = [w convertBaseToScreen:[w mouseLocationOutsideOfEventStream]];
	[[gCurrentDocument textureUtility] showPanelFrom: p onWindow: w];
}

- (IBAction)toggleBrushes:(id)sender
{
	NSWindow *w = [gCurrentDocument window];
	NSPoint p = [w convertBaseToScreen:[w mouseLocationOutsideOfEventStream]];
    [[gCurrentDocument brushUtility] showPanelFrom: p onWindow: w];
}

@end

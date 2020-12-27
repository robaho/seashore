#import "AbstractPaintOptions.h"

#import "SeaController.h"
#import "BrushUtility.h"
#import "TextureUtility.h"
#import "SeaDocument.h"

@implementation AbstractPaintOptions
- (IBAction)toggleTextures:(id)sender
{
	NSWindow *w = [document window];
	NSPoint p = [w convertBaseToScreen:[w mouseLocationOutsideOfEventStream]];
	[[document textureUtility] showPanelFrom: p onWindow: w];
}

- (IBAction)toggleBrushes:(id)sender
{
	NSWindow *w = [document window];
	NSPoint p = [w convertBaseToScreen:[w mouseLocationOutsideOfEventStream]];
    [[document brushUtility] showPanelFrom: p onWindow: w];
}

@end

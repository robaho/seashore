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

- (IBAction)opacityChanged:(id)sender
{
    [opacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"opacity", @"Opacity: %d%%"), [opacitySlider intValue]]];
}

- (int)opacity
{
    return roundf([opacitySlider intValue] * 2.55);
}

- (void)loadOpacity:(NSString*)tag
{
    if ([gUserDefaults objectForKey:tag]==NULL) {
        [opacitySlider setIntegerValue:100];
    } else {
        [opacitySlider setIntegerValue:[gUserDefaults integerForKey:tag]];
    }
    [opacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"opacity", @"Opacity: %d%%"), [opacitySlider integerValue]]];


}

@end

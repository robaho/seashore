#import "AbstractPaintOptions.h"

#import "SeaController.h"
#import "BrushUtility.h"
#import "TextureUtility.h"
#import "SeaDocument.h"
#import "SeaPrefs.h"

@implementation AbstractPaintOptions

- (id)init:(id)document {
    self = [super init:document];

    NSControlSize size = [[SeaController seaPrefs] controlSize];

    opacitySlider = [SeaSlider compactSliderWithTitle:@"Opacity" Min:0 Max:100 Listener:NULL Size:size];
    [self addSubview:opacitySlider];

    brushesButton = [SeaButton compactButton:@"Brushes" target:self action:@selector(toggleBrushes:) size:size];
    [self addSubview:brushesButton];

    texturesButton = [SeaButton compactButton:@"Textures" target:self action:@selector(toggleTextures:) size:size];
    [self addSubview:texturesButton];

    return self;
}
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

- (int)opacity
{
    return roundf([opacitySlider floatValue] * 2.55);
}
- (float)opacityFloat
{
    return [opacitySlider intValue]/100.0;
}
- (void)setOpacityFloat:(float)opacity
{
    [opacitySlider setIntValue:opacity*100];
}

- (void)loadOpacity:(NSString*)tag
{
    if ([gUserDefaults objectForKey:tag]==NULL) {
        [opacitySlider setIntValue:100];
    } else {
        [opacitySlider setIntValue:[gUserDefaults integerForKey:tag]];
    }
}

- (BOOL)useTextures
{
    return [[document toolboxUtility] foregroundIsTexture];
}

@end

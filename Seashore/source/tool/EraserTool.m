#import "EraserTool.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaController.h"
#import "SeaLayer.h"
#import "StandardMerge.h"
#import "SeaWhiteboard.h"
#import "SeaLayerUndo.h"
#import "SeaView.h"
#import "SeaBrush.h"
#import "BrushUtility.h"
#import "SeaHelpers.h"
#import "SeaTools.h"
#import "SeaTexture.h"
#import "BrushOptions.h"
#import "TextureUtility.h"
#import "EraserOptions.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "OptionsUtility.h"

@implementation EraserTool

- (void)awakeFromNib {
    options = [[EraserOptions alloc] init:document];
}

- (int)toolId
{
	return kEraserTool;
}

- (BOOL)acceptsLineDraws
{
	return YES;
}

- (BOOL)useMouseCoalescing
{
	return NO;
}

- (bool)applyTextures
{
    return FALSE;
}

- (void)setOverlayOptions:(BrushOptions*)options
{
    SeaLayer *layer = [[document contents] activeLayer];

    if([layer hasAlpha])
        [[document whiteboard] setOverlayBehaviour:kErasingBehaviour];
    [[document whiteboard] setOverlayOpacity:[options opacity]];
}

- (AbstractOptions*)getOptions
{
    return options;
}

- (BrushOptions*)getBrushOptions
{
    return options;
}

- (bool)isFadeEnabled
{
    if([options mimicBrush]) {
        BrushOptions *opts = [[document optionsUtility] getOptions:kBrushTool];
        return [opts fade];
    }
    return false;
}

- (int)getFadeValue
{
    if([options mimicBrush]) {
        BrushOptions *opts = [[document optionsUtility] getOptions:kBrushTool];
        return [opts fadeValue];
    }
    return 0;
}

- (NSCursor*)toolCursor:(SeaCursors *)cursors
{
    if([cursors usePreciseCursor]) {
        return [cursors crosspointCursor];
    }
    return [cursors eraserCursor];
}


@end

#import "BrushTool.h"
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
#import "Bucket.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "RecentsUtility.h"

@implementation BrushTool

- (void)awakeFromNib {
    options = [[BrushOptions alloc] init:document];
}

- (int)toolId
{
    return kBrushTool;
}

- (BOOL)acceptsLineDraws
{
    return YES;
}

- (BOOL)useMouseCoalescing
{
    return NO;
}

- (AbstractOptions*)getOptions
{
    return options;
}

- (BrushOptions*)getBrushOptions
{
    return options;
}

- (NSCursor*)toolCursor:(SeaCursors *)cursors
{
    if([cursors usePreciseCursor]) {
        return [cursors crosspointCursor];
    }
    if([options brushIsErasing]) {
        return [cursors eraserCursor];
    }
    return [cursors brushCursor];
}

@end

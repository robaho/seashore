//
//  ZoomTool.m
//  Seashore
//
//  Created by robert engels on 1/24/19.
//

#import "SeaTools.h"
#import "ZoomTool.h"
#import "SeaDocument.h"
#import "SeaView.h"
#import "SeaLayer.h"
#import "SeaHelpers.h"

@implementation ZoomTool

- (int)toolId
{
    return kZoomTool;
}

- (AbstractOptions*)getOptions
{
    return options;
}

- (void)setOptions:(AbstractOptions*)newoptions
{
    options = (ZoomOptions*)newoptions;
}

// this is a local rect
- (IntRect)selectionRect
{
    SeaLayer *layer = [[document contents] activeLayer];
    return IntOffsetRect([super postScaledRect],-[layer xoff],-[layer yoff]);
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [super mouseDownAt: where
              forRect: IntZeroRect
         withMaskRect: IntZeroRect
              andMask: NULL];

//    [super downHandler:where withEvent:event];
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    intermediate = YES;

    IntRect old = [self postScaledRect];

    [super dragHandler:where withEvent:event];

    if (intermediate) {
        [[document helpers] selectionChanged:IntSumRects(old,[self postScaledRect])];
    }
}


- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    SeaLayer *layer = [[document contents] activeLayer];
    SeaView *view = [document docView];

    IntRect r = [super postScaledRect];

    float scale = [[document docView] zoom];

    if(r.size.width<8/scale || r.size.height<8/scale) {
        NSPoint p = IntPointMakeNSPoint(IntOffsetPoint(where,[layer xoff],[layer yoff]));
        if ([options modifier] == kAltModifier) {
            if([view canZoomOut])
                [view zoomOutFromPoint:p];
            else
                NSBeep();
        }
        else {
            if([view canZoomIn])
                [view zoomInToPoint:p];
            else
                NSBeep();
        }
    } else {
        [view zoomToFitRect:[super postScaledRect]];
    }

    intermediate = FALSE;
}

- (void)updateCursor:(IntPoint)p cursors:(SeaCursors *)cursors
{
    [[cursors zoomCursor] set];
}

@end



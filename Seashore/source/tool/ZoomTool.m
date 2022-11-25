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

- (void)awakeFromNib {
    options = [[ZoomOptions alloc] init:document];
}

- (int)toolId
{
    return kZoomTool;
}

- (AbstractOptions*)getOptions
{
    return options;
}

- (IntRect)zoomRect
{
    if(!intermediate)
        return IntZeroRect;

    return [super postScaledRect];
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [super mouseDownAt: where
              forRect: IntZeroRect
         withMaskRect: IntZeroRect
              andMask: NULL];
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    IntRect old = [self zoomRect];

    [super mouseDraggedTo:where forRect:old andMask:NULL];

    if (intermediate) {
        [[document helpers] selectionChanged:IntSumRects(old,[self zoomRect])];
    }
}


- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    SeaLayer *layer = [[document contents] activeLayer];
    SeaView *view = [document docView];

    IntRect r = [super postScaledRect];

    [super mouseUpAt:where forRect:r andMask:NULL];

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
    [options update:self];
}

- (void)updateCursor:(IntPoint)p cursors:(SeaCursors *)cursors
{
    [[cursors zoomCursor] set];
}

@end



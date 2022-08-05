//
//  AbstractBrushTool.h
//  Seashore
//
//  Created by robert engels on 12/26/21.
//

#import "SeaBrush.h"
#import "BrushOptions.h"
#import "AbstractTool.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 @struct        BTPointRecord
 @discussion    Specifies a point to be drawn.
 @param        point
 The point to be drawn.
 @param        pressure
 The presure of the point to be drawn
 @param        special
 0 = normal, 2 = terminate
 */
typedef struct {
    IntPoint point;
    unsigned char pressure;
    unsigned char special;
} BTPointRecord;

/*!
 @defined    kMaxBTPoints
 @discussion    Specifies the maximum number of points.
 */
#define kMaxBTPoints 16384

@interface AbstractBrushTool : AbstractTool {
    // The last point we've been and the last point a brush was plotted (there is a difference)
    NSPoint lastPoint, lastPlotPoint;

    double distance;
    int lastPressure;
    bool pressureDisabled;

    NSColor *color;
    CGImageRef brushImage;
    unsigned char basePixel[4];
}

- (void)plotBrush:(SeaBrush*)curBrush at:(NSPoint)temp pressure:(int)pressure;
- (void)textureFill:(CGContextRef)context rect:(CGRect)rect;

- (BrushOptions*)getBrushOptions;

/*!
 @method        mouseDownAt:withEvent:
 @discussion    Handles mouse down events.
 @param        where
 Where in the document the mouse down event occurred (in terms of
 the document's pixels).
 @param        event
 The mouse down event.
 */
- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
 @method        mouseDraggedTo:withEvent:
 @discussion    Handles mouse dragging events.
 @param        where
 Where in the document the mouse down event occurred (in terms of
 the document's pixels).
 @param        event
 The mouse dragged event.
 */
- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event;

/*!
 @method        endLineDrawing
 @discussion    Ends line drawing.
 */
- (void)endLineDrawing;

/*!
 @method        mouseUpAt:withEvent:
 @discussion    Handles mouse up events.
 @param        where
 Where in the document the mouse up event occurred (in terms of
 the document's pixels).
 @param        event
 The mouse up event.
 */
- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event;

@end

NS_ASSUME_NONNULL_END

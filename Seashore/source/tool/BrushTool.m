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

#define EPSILON 0.0001

@implementation BrushTool

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

- (void)plotBrush:(id)brush at:(NSPoint)point pressure:(int)pressure
{
    id layer = [[document contents] activeLayer];
    unsigned char *overlay = [[document whiteboard] overlay], *brushData;
    int brushWidth = [(SeaBrush *)brush fakeWidth], brushHeight = [(SeaBrush *)brush fakeHeight];
    int width = [(SeaLayer *)layer width], height = [(SeaLayer *)layer height];
    int i, j, spp = [[document contents] spp], overlayPos;
    IntPoint ipoint = NSPointMakeIntPoint(point);
    
    if ([brush usePixmap]) {
    
        // We can't handle this for anything but 4 samples per pixel
        if (spp != 4)
            return;
        
        // Get the approrpiate brush data for the point
        brushData = [brush pixmapForPoint:point];
        
        // Go through all valid points
        for (j = 0; j < brushHeight; j++) {
            for (i = 0; i < brushWidth; i++) {
                if (ipoint.x + i >= 0 && ipoint.y + j >= 0 && ipoint.x + i < width && ipoint.y + j < height) {
                    
                    // Change the pixel colour appropriately
                    overlayPos = (width * (ipoint.y + j) + ipoint.x + i) * 4;
                    specialMerge(4, overlay, overlayPos, brushData, (j * brushWidth + i) * 4, pressure);
                    
                }
            }
        }
    }
    else {
        
        // Get the approrpiate brush data for the point
        if ([options scale])
            brushData = [brush maskForPoint:point pressure:pressure];
        else
            brushData = [brush maskForPoint:point pressure:255];
    
        // Go through all valid points
        for (j = 0; j < brushHeight; j++) {
            for (i = 0; i < brushWidth; i++) {
                if (ipoint.x + i >= 0 && ipoint.y + j >= 0 && ipoint.x + i < width && ipoint.y + j < height) {
                    
                    // Change the pixel colour appropriately
                    overlayPos = (width * (ipoint.y + j) + ipoint.x + i) * spp;
                    basePixel[spp - 1] = brushData[j * brushWidth + i];
                    specialMerge(spp, overlay, overlayPos, basePixel, 0, pressure);
                    
                }
            }
        }
        
    }
    
    // Set the last plot point appropriately
    lastPlotPoint = point;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    id layer = [[document contents] activeLayer];
    BOOL hasAlpha = [layer hasAlpha];
    id curBrush = [[document brushUtility] activeBrush];
    id activeTexture = [[document textureUtility] activeTexture];
    NSPoint curPoint = IntPointMakeNSPoint(where), temp;
    IntRect rect;
    NSColor *color = NULL;
    int spp = [[document contents] spp], k;
    int pressure = [options pressureValue:event];
    BOOL ignoreFirstTouch;
    int modifier = [(BrushOptions*)options modifier];
    
    // Determine whether operation should continue
    lastWhere.x = where.x;
    lastWhere.y = where.y;
    ignoreFirstTouch = [[SeaController seaPrefs] ignoreFirstTouch];
    if (ignoreFirstTouch && ([event type] == NSLeftMouseDown || [event type] == NSRightMouseDown) && [options pressureSensitive] && (modifier != kShiftModifier && modifier != kShiftControlModifier)) { 
        firstTouchDone = NO;
        return;
    }
    else {
        firstTouchDone = YES;
    }
    
    // Determine base pixels and hence brush colour
    if (modifier == kAltModifier) {
        color = [[document contents] background];
        if (spp == 4) {
            basePixel[0] = (unsigned char)([color redComponent] * 255.0);
            basePixel[1] = (unsigned char)([color greenComponent] * 255.0);
            basePixel[2] = (unsigned char)([color blueComponent] * 255.0);
            basePixel[3] = 255;
        }
        else {
            basePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
            basePixel[1] = 255;
        }
    }
    else if ([options useTextures]) {
        for (k = 0; k < spp - 1; k++)
            basePixel[k] = 0;
        basePixel[spp - 1] = [[document textureUtility] opacity];
    }
    else if (spp == 4) {
        color = [[document contents] foreground];
        basePixel[0] = (unsigned char)([color redComponent] * 255.0);
        basePixel[1] = (unsigned char)([color greenComponent] * 255.0);
        basePixel[2] = (unsigned char)([color blueComponent] * 255.0);
        basePixel[3] = (unsigned char)([color alphaComponent] * 255.0);
    }
    else {
        color = [[document contents] foreground];
        basePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
        basePixel[1] = (unsigned char)([color alphaComponent] * 255.0);
    }
    
    // Set the appropriate overlay opacity
    if ([options brushIsErasing]) {
        if (hasAlpha)
            [[document whiteboard] setOverlayBehaviour:kErasingBehaviour];
        [[document whiteboard] setOverlayOpacity:255];
    }
    else {
        if ([options useTextures])
            [[document whiteboard] setOverlayOpacity:[[document textureUtility] opacity]];
        else
            [[document whiteboard] setOverlayOpacity:[color alphaComponent] * 255.0];
    }
    
    // Plot the initial point
    rect.size.width = [(SeaBrush *)curBrush fakeWidth] + 1;
    rect.size.height = [(SeaBrush *)curBrush fakeHeight] + 1;
    temp = NSMakePoint(curPoint.x - (float)([(SeaBrush *)curBrush width] / 2) - 1.0, curPoint.y - (float)([(SeaBrush *)curBrush height] / 2) - 1.0);
    rect.origin = NSPointMakeIntPoint(temp);
    rect.origin.x--; rect.origin.y--;
    rect = IntConstrainRect(rect, IntMakeRect(0, 0, [(SeaLayer *)layer width], [(SeaLayer *)layer height]));
    if (rect.size.width > 0 && rect.size.height > 0) {
        [self plotBrush:curBrush at:temp pressure:pressure];
        if ([options useTextures] && ![options brushIsErasing] && ![curBrush usePixmap])
            textureFill(spp, rect, [[document whiteboard] overlay], [(SeaLayer *)layer width], [(SeaLayer *)layer height], [activeTexture texture:(spp == 4)], [(SeaTexture *)activeTexture width], [(SeaTexture *)activeTexture height]);
        [[document helpers] overlayChanged:rect];
    }
    
    // Record the position as the last point
    lastPoint = lastPlotPoint = curPoint;
    distance = 0;
    
    // Create the points list
    points = malloc(kMaxBTPoints * sizeof(BTPointRecord));
    pos = drawingPos = 0;
    lastPressure = -1;
    
}

- (void)drawThread:(id)object
{    
    NSPoint curPoint;
    id layer;
    int layerWidth, layerHeight;
    id curBrush, activeTexture;
    int brushWidth, brushHeight;
    double brushSpacing;
    double deltaX, deltaY, mag, xd, yd, dist;
    double stFactor, stOffset;
    double t0, dt, tn, t, dtx;
    double total, initial;
    double fadeValue;
    BOOL fade;
    int n, num_points, spp;
    IntRect rect, trect, bigRect;
    NSPoint temp;
    int pressure, origPressure;
    int tim;
    NSDate *lastDate;
   
   // Set-up variables
   layer = [[document contents] activeLayer];
   curBrush = [[document brushUtility] activeBrush];
   layerWidth = [(SeaLayer *)layer width];
   layerHeight = [(SeaLayer *)layer height];
   brushWidth = [(SeaBrush *)curBrush fakeWidth];
   brushHeight = [(SeaBrush *)curBrush fakeHeight];
   activeTexture = [[document textureUtility] activeTexture];
   brushSpacing = (double)[[document brushUtility] spacing] / 100.0;
   fade = [options fade];
   fadeValue = [options fadeValue];
   spp = [[document contents] spp];
   bigRect = IntMakeRect(0, 0, 0, 0);
   lastDate = [NSDate date];
   
    // While we are not done...
    do {

next:
        if (drawingPos < pos) {
            
            // Get the next record and carry on
            curPoint = IntPointMakeNSPoint(points[drawingPos].point);
            origPressure = points[drawingPos].pressure;
            if (points[drawingPos].special == 2) {
                if (bigRect.size.width != 0) [[document helpers] overlayChanged:bigRect];
                drawingDone = YES;
                return;
            }
            drawingPos++;
        
            // Determine the change in the x and y directions
            deltaX = curPoint.x - lastPoint.x;
            deltaY = curPoint.y - lastPoint.y;
            if (deltaX == 0.0 && deltaY == 0.0) {
                return;
            }
            
            // Determine the number of brush strokes in the x and y directions
            mag = (float)(brushWidth / 2);
            xd = (mag * deltaX) / sqr(mag);
            mag = (float)(brushHeight / 2);
            yd = (mag * deltaY) / sqr(mag);
            
            // Determine the brush stroke distance and hence determine the initial and total distance
            dist = 0.5 * sqrt(sqr(xd) + sqr(yd));        // Why is this halved?
            total = dist + distance;
            initial = distance;
            
            // Determine the stripe factor and offset
            if (sqr(deltaX) > sqr(deltaY)) {
                stFactor = deltaX;
                stOffset = lastPoint.x - 0.5;
            }
            else {
                stFactor = deltaY;
                stOffset = lastPoint.y - 0.5;
            }
            
            if (fabs(stFactor) > dist / brushSpacing) {

                // We want to draw the maximum number of points
                dt = brushSpacing / dist;
                n = (int)(initial / brushSpacing + 1.0 + EPSILON);
                t0 = (n * brushSpacing - initial) / dist;
                num_points = 1 + (int)floor((1 + EPSILON - t0) / dt);
                
            }
            else if (fabs(stFactor) < EPSILON) {
            
                // We can't draw any points - this does actually get called albeit once in a blue moon
                lastPoint = curPoint;
                return;
                
            }
            else {
            
                // We want to draw a number of points
                int direction = stFactor > 0 ? 1 : -1;
                int x, y;
                int s0, sn;
                
                s0 = (int)floor(stOffset + 0.5);
                sn = (int)floor(stOffset + stFactor + 0.5);
                
                t0 = (s0 - stOffset) / stFactor;
                tn = (sn - stOffset) / stFactor;
                
                x = (int)floor(lastPoint.x + t0 * deltaX);
                y = (int)floor(lastPoint.y + t0 * deltaY);
                if (t0 < 0.0 && !(x == (int)floor(lastPoint.x) && y == (int)floor(lastPoint.y))) {
                    s0 += direction;
                }
                if (x == (int)floor(lastPlotPoint.x) && y == (int)floor(lastPlotPoint.y)) {
                    s0 += direction;
                }
                x = (int)floor(lastPoint.x + tn * deltaX);
                y = (int)floor(lastPoint.y + tn * deltaY);
                if (tn > 1.0 && !(x == (int)floor(lastPoint.x) && y == (int)floor(lastPoint.y))) {
                    sn -= direction;
                }
                t0 = (s0 - stOffset) / stFactor;
                tn = (sn - stOffset) / stFactor;
                dt = direction * 1.0 / stFactor;
                num_points = 1 + direction * (sn - s0);
                
                if (num_points >= 1) {
                    if (tn < 1)
                        total = initial + tn * dist;
                    total = brushSpacing * (int) (total / brushSpacing + 0.5);
                    total += (1.0 - tn) * dist;
                }
                
            }

            // Draw all the points
            for (n = 0; n < num_points; n++) {
                t = t0 + n * dt;
                rect.size.width = brushWidth + 1;
                rect.size.height = brushHeight + 1;
                temp = NSMakePoint(lastPoint.x + deltaX * t - (float)(brushWidth / 2), lastPoint.y + deltaY * t - (float)(brushHeight / 2));
                rect.origin = NSPointMakeIntPoint(temp);
                rect.origin.x--; rect.origin.y--;
                rect = IntConstrainRect(rect, IntMakeRect(0, 0, layerWidth, layerHeight));
                if (fade) {
                    dtx = (double)(initial + t * dist) / fadeValue;
                    pressure = (int)(exp (- dtx * dtx * 5.541) * 255.0);
                    pressure = int_mult(pressure, origPressure, tim);
                }
                else {
                    pressure = origPressure;
                }
                if (lastPressure > -1 && abs(pressure - lastPressure) > 5) {
                    pressure = lastPressure + 5 * sgn(pressure - lastPressure);
                }
                lastPressure = pressure;
                if (rect.size.width > 0 && rect.size.height > 0 && pressure > 0) {
                    [self plotBrush:curBrush at:temp pressure:pressure];
                    if ([options useTextures] && ![options brushIsErasing] && ![curBrush usePixmap])
                        textureFill(spp, rect, [[document whiteboard] overlay], layerWidth, layerHeight, [activeTexture texture:(spp == 4)], [(SeaTexture *)activeTexture width], [(SeaTexture *)activeTexture height]);
                    if (bigRect.size.width == 0) {
                        bigRect = rect;
                    }
                    else {
                        trect.origin.x = MIN(rect.origin.x, bigRect.origin.x);
                        trect.origin.y = MIN(rect.origin.y, bigRect.origin.y);
                        trect.size.width = MAX(rect.origin.x + rect.size.width - trect.origin.x, bigRect.origin.x + bigRect.size.width - trect.origin.x);
                        trect.size.height = MAX(rect.origin.y + rect.size.height - trect.origin.y, bigRect.origin.y + bigRect.size.height - trect.origin.y);
                        bigRect = trect;
                    }
                }
            }
            
            // Update the distance and plot points
            distance = total;
            lastPoint.x = lastPoint.x + deltaX;
            lastPoint.y = lastPoint.y + deltaY; 
        
        }
        
        [[document helpers] overlayChanged:bigRect];
        
    } while (false /* multithreaded */);
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    // Have we registerd the first touch
    if (!firstTouchDone) {
        [self mouseDownAt:where withEvent:event];
        firstTouchDone = YES;
    }
    
    // Check this is a new point
    if (where.x == lastWhere.x && where.y == lastWhere.y) {
        return;
    }
    else {
        lastWhere = where;
    }

    // Add to the list
    if (pos < kMaxBTPoints - 1) {
        points[pos].point = where;
        points[pos].pressure = [options pressureValue:event];
        pos++;
    }
    else if (pos == kMaxBTPoints - 1) {
        points[pos].special = 2;
        pos++;
    }
    
    [self drawThread:NULL];
}

- (void)endLineDrawing
{
    // Tell the other thread to terminate
    if (pos < kMaxBTPoints) {
        points[pos].special = 2;
        pos++;
    }
    
    [[document recentsUtility] rememberBrush:options];
    
    [self drawThread:NULL];
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [self endLineDrawing];
    [[document helpers] applyOverlay];
}

- (void)startStroke:(IntPoint)where;
{
    [self mouseDownAt:where withEvent:NULL];
}

- (void)intermediateStroke:(IntPoint)where
{
    [self mouseDraggedTo:where withEvent:NULL];
}

- (void)endStroke:(IntPoint)where
{
    [self mouseUpAt:where withEvent:NULL];
}

- (AbstractOptions*)getOptions
{
    return options;
}
- (void)setOptions:(AbstractOptions*)newoptions
{
    options = (BrushOptions*)newoptions;
}


@end

#import "SeaDocument.h"
#import "SeaLayer.h"
#import "SeaHelpers.h"
#import "AbstractBrushTool.h"
#import "Bucket.h"
#import "SeaSelection.h"

#define EPSILON 0.0001

@implementation AbstractBrushTool

- (void)plotBrush:(SeaBrush*)brush at:(NSPoint)where pressure:(int)pressure
{
    SeaLayer *layer = [[document contents] activeLayer];
    float brushWidth = [brush width];
    float brushHeight = [brush height];

    int lh = [layer height];
    int lw = [layer width];
    int spp = [[document contents] spp];

    BrushOptions *options = [self getBrushOptions];

    if([options scale]) {
        double factor = (0.30 * ((float)pressure / 255.0) + 0.70);
        brushWidth = factor * brushWidth;
        brushHeight = factor * brushHeight;
    }

    CGRect cgRect = CGRectMake(where.x-brushWidth/2,where.y-brushHeight/2,brushWidth,brushHeight);

    IntRect rect = NSRectMakeIntRect(cgRect);

    CGContextRef overlayCtx = [[document whiteboard] overlayCtx];

    CGContextSetBlendMode(overlayCtx, kCGBlendModeNormal);
    CGContextSetAlpha(overlayCtx, pressureDisabled ? 255 : pressure/255.0);
    CGContextDrawImage(overlayCtx,cgRect, brushImage);

    if ([options useTextures] && ![options brushIsErasing]) {
        SeaTexture *activeTexture = [[document textureUtility] activeTexture];
        textureFill(spp, rect, [[document whiteboard] overlay], lw, lh, [activeTexture texture:(spp == 4)], [activeTexture width], [activeTexture height]);
    }

    [[document helpers] overlayChanged:rect];
}

- (void)dealloc
{
    CGImageRelease(brushImage);
}

- (NSColor*)brushColor
{
    BrushOptions *options = [self getBrushOptions];
    
    // Determine base pixels and hence brush colour
    if ([options brushIsErasing]) {
        return [[document contents] background];
    }
    else if ([options useTextures]) {
        return [NSColor colorWithRed:0 green:0 blue:0 alpha:[[document textureUtility] opacity_float]];
    }
    else {
        return [[document contents] foreground];
    }
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    SeaBrush *curBrush = [[document brushUtility] activeBrush];

    BrushOptions *options = [self getBrushOptions];

    pressureDisabled = [event pressure]==0.0;

    int pressure = [options pressureValue:event];

    color = [self brushColor];

    CGImageRelease(brushImage);
    brushImage=NULL;

    if(curBrush != NULL)
        brushImage = getTintedCG([curBrush bitmap],color);

    [self setOverlayOptions:options];

    [self plotBrush:curBrush at:IntPointMakeNSPoint(where) pressure:pressure];

    lastPoint = lastPlotPoint = IntPointMakeNSPoint(where);
    distance = 0;
    lastPressure = -1;
    intermediate = YES;
}

- (void)setOverlayOptions:(BrushOptions*)options
{
    if ([options useTextures])
        [[document whiteboard] setOverlayOpacity:[[document textureUtility] opacity]];
    else {
        [[document whiteboard] setOverlayOpacity:[color alphaComponent] * 255.0];
    }
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    if(!intermediate)
        return;

    BrushOptions *options = [self getBrushOptions];

    // Check this is a new point
    if (where.x == lastPoint.x && where.y == lastPoint.y) {
        return;
    }

    [self plotPoints:where pressure:[options pressureValue:event]];
}

- (void)endLineDrawing
{
    if(!intermediate)
        return;
    
    [[document helpers] applyOverlay];
    intermediate=NO;

    [[document recentsUtility] rememberBrush:[self getBrushOptions]];
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [self endLineDrawing];
}

- (int)getBrushSpacing
{
    return [[document brushUtility] spacing];
}

- (void)plotPoints:(IntPoint)to pressure:(int)origPressure
{
    NSPoint curPoint = IntPointMakeNSPoint(to);

    SeaBrush *curBrush = [[document brushUtility] activeBrush];
    float brushWidth = [curBrush width];
    float brushHeight = [curBrush height];

    double brushSpacing = [self getBrushSpacing] / 100.0;

    bool fade = [self isFadeEnabled];
    int fadeValue = [self getFadeValue];

    // Determine the change in the x and y directions
    double deltaX = curPoint.x - lastPoint.x;
    double deltaY = curPoint.y - lastPoint.y;

    if (deltaX == 0.0 && deltaY == 0.0) {
        return;
    }

    double mag;
    // Determine the number of brush strokes in the x and y directions
    mag = (float)(brushWidth / 2);
    double xd = (mag * deltaX) / sqr(mag);
    mag = (float)(brushHeight / 2);
    double yd = (mag * deltaY) / sqr(mag);

    // Determine the brush stroke distance and hence determine the initial and total distance
    double dist = 0.5 * sqrt(sqr(xd) + sqr(yd));        // Why is this halved?
    double total = dist + distance;
    double initial = distance;

    double stFactor,stOffset;

    // Determine the stripe factor and offset
    if (sqr(deltaX) > sqr(deltaY)) {
        stFactor = deltaX;
        stOffset = lastPoint.x - 0.5;
    }
    else {
        stFactor = deltaY;
        stOffset = lastPoint.y - 0.5;
    }

    int num_points;

    double dt,t0;

    if (fabs(stFactor) > dist / brushSpacing) {
        // We want to draw the maximum number of points
        dt = brushSpacing / dist;
        int n = (int)(initial / brushSpacing + 1.0 + EPSILON);
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

        int s0 = (int)floor(stOffset + 0.5);
        int sn = (int)floor(stOffset + stFactor + 0.5);

        double t0 = (s0 - stOffset) / stFactor;
        double tn = (sn - stOffset) / stFactor;

        int x = (int)floor(lastPoint.x + t0 * deltaX);
        int y = (int)floor(lastPoint.y + t0 * deltaY);
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

    int pressure;

    // Draw all the points
    for (int n = 0; n < num_points; n++) {
        double t = t0 + n * dt;
        NSPoint temp = NSMakePoint(lastPoint.x + deltaX * t , lastPoint.y + deltaY * t);
        if (fade) {
            int temp0;
            double dtx = (double)(initial + t * dist) / fadeValue;
            pressure = (int)(exp (- dtx * dtx * 5.541) * 255.0);
            pressure = int_mult(pressure, origPressure, temp0);
        }
        else {
            pressure = origPressure;
        }
        if (lastPressure > -1 && abs(pressure - lastPressure) > 5) {
            pressure = lastPressure + 5 * sgn(pressure - lastPressure);
        }
        lastPressure = pressure;
        [self plotBrush:curBrush at:temp pressure:pressure];
        lastPlotPoint = temp;
    }

    if(num_points>0){
        distance = total;
        lastPoint.x = lastPoint.x + deltaX;
        lastPoint.y = lastPoint.y + deltaY;
    }
}

- (bool)isFadeEnabled
{
    return [[self getBrushOptions] fade];
}

- (int)getFadeValue
{
    return [[self getBrushOptions] fadeValue];
}


@end

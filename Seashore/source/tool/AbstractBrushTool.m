#import "SeaDocument.h"
#import "SeaLayer.h"
#import "SeaHelpers.h"
#import "AbstractBrushTool.h"
#import "Bucket.h"
#import "SeaSelection.h"

#define EPSILON 0.0001

@interface BrushCache : NSObject
{
    CGImageRef images[256];
    CGImageRef brush;
    int brushWidth;
    int brushHeight;
}
- (id)initWithBrush:(CGImageRef)brush;
- (CGImageRef)getBrush:(int)pressure;
- (CGImageRef)brush;
@end

@implementation BrushCache
- (id)initWithBrush:(CGImageRef)brush {
    self->brush = brush;
    brushWidth = CGImageGetWidth(brush);
    brushHeight = CGImageGetHeight(brush);
    return self;
}
- (CGImageRef)brush {
    return brush;
}
- (void)dealloc
{
    for(int i=0;i<256;i++) {
        CGImageRelease(images[i]);
    }
}
- (CGImageRef)getBrush:(int)pressure {
    CGImageRef scaled = images[pressure];
    if(!scaled) {
        double factor = (0.30 * ((float)pressure / 255.0) + 0.70);
        int bw = (int)(factor * brushWidth);
        int bh = (int)(factor * brushHeight);
        images[pressure] = CGImageScale(brush,bw,bh);
    }
    return images[pressure];
}
@end

@implementation AbstractBrushTool

- (IntRect)plotBrushAt:(NSPoint)where pressure:(int)pressure
{
    CGImageRef _brush = brushImage;

    BrushOptions *options = [self getBrushOptions];

    if([options scale]) {
        _brush = [brushCache getBrush:pressure];
    }

    int brushWidth = CGImageGetWidth(_brush);
    int brushHeight = CGImageGetHeight(_brush);

    if(_brush!=lastBufferImage) {
        if(lastBufferImage) {
            free(buffer.data);
        }
        vImage_CGImageFormat iFormat = {};
        vImageBuffer_InitWithCGImage(&buffer, &iFormat, NULL, _brush, 0);
        lastBufferImage=_brush;
    }

    IntRect rect = IntMakeRect(where.x-brushWidth/2,where.y-brushHeight/2,brushWidth,brushHeight);

    CGContextRef overlayCtx = [[document whiteboard] overlayCtx];

    blitImage(overlayCtx,&buffer,rect,pressureDisabled ? 255 : pressure);

    if ([options useTextures] && ![options brushIsErasing] && ![brush isPixMap]) {
        textureFill(overlayCtx,textureCtx,rect);
    }

    return rect;
}

- (void)dealloc
{
    CGImageRelease(brushImage);
    CGContextRelease(textureCtx);
}

- (NSColor*)brushColor
{
    BrushOptions *options = [self getBrushOptions];
    NSColor *color;
    
    // Determine base pixels and hence brush colour
    if ([options brushIsErasing]) {
        color = [[document contents] background];
    }
    else if ([options useTextures]) {
        color = [NSColor blackColor];
    }
    else {
        color = [[document contents] foreground];
    }
    return [color colorWithAlphaComponent:[options opacity]/255.0];
}

- (CGImageRef)getBrushImage
{
    if(brush != NULL) {
        if([brush isPixMap]) {
            return CGImageDeepCopy([brush bitmap]);
        } else {
            return getTintedCG([brush bitmap],color);
        }
    }
    return nil;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    brush = [[document brushUtility] activeBrush];

    BrushOptions *options = [self getBrushOptions];

    pressureDisabled = [event pressure]==0.0;

    int pressure = [options pressureValue:event];

    color = [self brushColor];

    CGImageRelease(brushImage);

    brushImage = [self getBrushImage];
    if([[document contents] isGrayscale]) {
        CGImageRef gray = convertToGrayA(brushImage);
        CGImageRelease(brushImage);
        brushImage = gray;
    }
    brushCache = [[BrushCache alloc] initWithBrush:brushImage];

    if([options useTextures]) {
        CGContextRelease(textureCtx);

        NSImage *pattern = [[[document toolboxUtility] foreground] patternImage];
        int w = pattern.size.width;
        int h = pattern.size.height;

        textureCtx = CGBitmapContextCreate(NULL, w,h, 8, w*SPP, rgbCS, kCGImageAlphaPremultipliedFirst);
        CGImageRef img = [pattern CGImageForProposedRect:NULL context:NULL hints:NULL];
        CGContextDrawImage(textureCtx,CGRectMake(0,0,w,h), img);
    }

    [self setOverlayOptions:options];

    IntRect r = [self plotBrushAt:IntPointMakeNSPoint(where) pressure:pressure];
    [[document helpers] overlayChanged:r];

    lastPoint = lastPlotPoint = IntPointMakeNSPoint(where);
    distance = 0;
    lastPressure = -1;
    intermediate = YES;
}

- (void)setOverlayOptions:(BrushOptions*)options
{
    if([options brushIsErasing]) {
        SeaLayer *layer = [[document contents] activeLayer];
        if([layer hasAlpha])
            [[document whiteboard] setOverlayBehaviour:kErasingBehaviour];
    }
    [[document whiteboard] setOverlayOpacity:[options opacity]];
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

- (void)plotPoints:(IntPoint)to pressure:(int)startingPressure
{
    NSPoint curPoint = IntPointMakeNSPoint(to);

    float brushWidth = [brush width];
    float brushHeight = [brush height];

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


    IntRect dirty = IntZeroRect;

    // Draw all the points
    for (int n = 0; n < num_points; n++) {
        double t = t0 + n * dt;
        NSPoint temp = NSMakePoint(lastPoint.x + deltaX * t , lastPoint.y + deltaY * t);
        if (fade) {
            int temp0;
            double dtx = (double)(initial + t * dist) / fadeValue;
            pressure = (int)(exp (- dtx * dtx * 5.541) * 255.0);
            pressure = int_mult(pressure, startingPressure, temp0);
        }
        else {
            pressure = startingPressure;
        }
        if (lastPressure > -1 && abs(pressure - lastPressure) > 5) {
            pressure = lastPressure + 5 * sgn(pressure - lastPressure);
        }
        lastPressure = pressure;
        IntRect r = [self plotBrushAt:temp pressure:pressure];
        dirty = n==0 ? r : IntSumRects(dirty,r);
        lastPlotPoint = temp;
    }

    if(!IntRectIsEmpty(dirty)) {
        [[document helpers] overlayChanged:dirty];
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

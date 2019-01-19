#import "LassoTool.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import "LassoOptions.h"
#import "SeaContent.h"
#import "SeaTools.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "SeaView.h"
#import "SeaLayer.h"
#import "SeaWhiteboard.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"

@implementation LassoTool

- (int)toolId
{
	return kLassoTool;
}

- (void)initializePoints:(NSPoint)where
{
    if(points) {
        free(points);
    }
    // Create the points list
    points = malloc(kMaxLTPoints * sizeof(IntPoint));
    pos = 0;
    points[0] =  NSPointMakeIntPoint(where);
    [[document docView] setNeedsDisplay:YES];
    intermediate = YES;
}

- (void)addPoint:(NSPoint)where
{
    int width,height;
    
    if (points[pos].x != where.x || points[pos].y != where.y) {
        // Add the point to the list
        pos++;
        points[pos] = NSPointMakeIntPoint(where);
        
        // Make sure we fall inside the layer
        width = [(SeaLayer *)[[document contents] activeLayer] width];
        height = [(SeaLayer *)[[document contents] activeLayer] height];
        
        if (points[pos].x < 0) points[pos].x = 0;
        if (points[pos].y < 0) points[pos].y = 0;
        if (points[pos].x > width) points[pos].x = width;
        if (points[pos].y > height) points[pos].y = height;
        [[document docView] setNeedsDisplay:YES];
    }
}

- (void)fineMouseDownAt:(NSPoint)where withEvent:(NSEvent *)event
{
	SeaLayer *layer = [[document contents] activeLayer];
    
    where.x -= [layer xoff];
    where.y -= [layer yoff];
    
	[super mouseDownAt:IntMakePoint(where.x, where.y) withEvent:event];
		
	if(![super isMovingOrScaling]){
        
        [self initializePoints:where];
	}
}

- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event
{
	SeaLayer *layer = [[document contents] activeLayer];
    where.x -= [layer xoff];
    where.y -= [layer yoff];
    
	[super mouseDraggedTo:IntMakePoint(where.x, where.y) withEvent:event];
	
	if(intermediate && ![super isMovingOrScaling]){

		// Check we have a valid start point
		// Check this point is different to the last
		if (pos < kMaxLTPoints - 1) {
            [self addPoint:where];
		}
	}
}

- (void)fineMouseUpAt:(NSPoint)where withEvent:(NSEvent *)event
{
    SeaLayer *layer = [[document contents] activeLayer];
    where.x -= [layer xoff];
    where.y -= [layer yoff];
    
	[super mouseUpAt:IntMakePoint(where.x, where.y) withEvent:event];
	
	// Check we have a valid start point
	if (intermediate && ![super isMovingOrScaling]) {
        [self createOverlayFromPoints];
	}

	translating = NO;
	scalingDir = kNoDir;
}

- (void)createOverlayFromPoints
{
    SeaLayer *layer = [[document contents] activeLayer];
    unsigned char *overlay = [[document whiteboard] overlay];
    int width = [(SeaLayer *)layer width], height = [(SeaLayer *)layer height];
    float xScale, yScale;
    NSImageInterpolation interpolation;
    int spp = [[document contents] spp];
    int tpos;
    IntRect rect;

    // Redraw canvas
    [[document docView] setNeedsDisplay:YES];
    
    // Clear last selection
    if([options selectionMode] == kDefaultMode || [options selectionMode] == kForceNewMode)
        [[document selection] clearSelection];
    
    // No single-pixel loops
    if (pos <= 1) return;
    
    // Fill out the variables
    if([[document docView] zoom] <= 1){
        interpolation = NSImageInterpolationNone;
    }else{
        interpolation = NSImageInterpolationHigh;
    }
    
    // Create an overlay that's the size of what the user sees
    xScale = [[document contents] xscale];
    yScale = [[document contents] yscale];
    
    NSColorSpaceName csname = MyRGBSpace;
    if (spp==2) {
        csname = MyGraySpace;
    }

    
    NSBitmapImageRep *overlayImage = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&overlay pixelsWide:width pixelsHigh:height
                                                                                    bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO
                                                                                   colorSpaceName:csname bytesPerRow:width*spp
                                                                                     bitsPerPixel:8*spp];
    
    
    // Reconnect the loop
    pos++;
    points[pos] = points[0];
    
    NSBezierPath *path = [[NSBezierPath alloc] init];
    
    for (tpos = 0; tpos <= pos; tpos++) {
        if(tpos==0) {
            [path moveToPoint:NSMakePoint(points[tpos].x,points[tpos].y)];
        } else {
            [path lineToPoint:NSMakePoint(points[tpos].x,points[tpos].y)];
        }
    }
    
    NSRect bounds = [path bounds];
    
    // Ensure an IntRect (as opposed to NSRect)
    rect.origin.x = (int)floor(bounds.origin.x);
    rect.origin.y = (int)floor(bounds.origin.y);
    rect.size.width = (int)ceil(bounds.size.width);
    rect.size.height = (int)ceil(bounds.size.height);
    
    memset(overlay,0,width*height*spp);
    
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:overlayImage];
    [NSGraphicsContext setCurrentContext:ctx];
    [ctx setImageInterpolation:interpolation];

    NSAffineTransform *at = [NSAffineTransform transform];
    [at scaleXBy:1 yBy:-1];
    [at translateXBy:0 yBy:-height];
    [at concat];
    [[NSColor whiteColor] set];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    
    // Then select it
    [[document selection] selectOverlay:YES inRect:rect mode:[options selectionMode]];
    
    // Release the fake (scaled) overlay
    intermediate = NO;
}

- (BOOL)isFineTool
{
	return YES;
}

- (LassoPoints)currentPoints
{
	LassoPoints result;
	result.points = points;
	result.pos = pos;
	return result;
}

- (AbstractOptions*)getOptions
{
    return options;
}
- (void)setOptions:(AbstractOptions*)newoptions
{
    options = (LassoOptions*)newoptions;
}


@end

#import "GradientTool.h"
#import "SeaTools.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaSelection.h"
#import "SeaWhiteboard.h"
#import "SeaLayer.h"
#import "GradientOptions.h"
#import "SeaHelpers.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import <GIMPCore/GIMPCore.h>

@implementation GradientTool

- (void)awakeFromNib {
    options = [[GradientOptions alloc] init:document];
}

- (int)toolId
{
	return kGradientTool;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	startPoint = where;
	intermediate = YES;
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	GimpGradientInfo info;
	id contents = [document contents];
	IntRect rect;
	NSColor *color;
	double angle;
	int deltaX, deltaY;
	
	// Get ready
	[[document whiteboard] setOverlayOpacity:255];
	
	// Determine gradient information
	info.repeat = [options repeat];
	info.gradient_type = [(GradientOptions *)options type];
	info.supersample = [options supersample];
	if (info.gradient_type == GIMP_GRADIENT_CONICAL_ASYMMETRIC || info.gradient_type == GIMP_GRADIENT_SPIRAL_CLOCKWISE || info.gradient_type == GIMP_GRADIENT_SPIRAL_ANTICLOCKWISE) {
		info.supersample = YES;
	}
	else {
		if (info.repeat == GIMP_REPEAT_SAWTOOTH && info.gradient_type <= GIMP_GRADIENT_SQUARE)
			info.supersample = YES;
	}
	info.max_depth = [options maximumDepth];
	info.threshold = [options threshold];
	info.start = startPoint;
	deltaX = where.x - startPoint.x;
	deltaY = where.y - startPoint.y;
	if ([(GradientOptions*)options modifier] == kControlModifier) {
		angle = atan((double)deltaY / (double)abs(deltaX));
		if (angle > -0.3927 && angle < 0.3927)
			where.y = startPoint.y;
		else if (angle > 1.1781 || angle < -1.1781)
			where.x = startPoint.x;
		else if (angle > 0.0)
			where.y = startPoint.y + abs(deltaX);
		else 
			where.y = startPoint.y - abs(deltaX);
	}

    if([[document contents] isRGB]) {
        color = [contents foreground];
        info.start_color[CR] = [color redComponent] * 255;
        info.start_color[CB] = [color greenComponent] * 255;
        info.start_color[CG] = [color blueComponent] * 255;
        info.start_color[alphaPos] = [options startOpacity] * 255;
        info.end = where;

        color = [contents background];
        info.end_color[CR] = [color redComponent] * 255;
        info.end_color[CB] = [color greenComponent] * 255;
        info.end_color[CG] = [color blueComponent] * 255;
        info.end_color[alphaPos] = [options endOpacity] * 255;
    } else {
        color = [contents foreground];
        info.start_color[CR] = [color whiteComponent] * 255;
        info.start_color[CB] = [color whiteComponent] * 255;
        info.start_color[CG] = [color whiteComponent] * 255;
        info.start_color[alphaPos] = [options startOpacity] * 255;
        info.end = where;

        color = [contents background];
        info.end_color[CR] = [color whiteComponent] * 255;
        info.end_color[CB] = [color whiteComponent] * 255;
        info.end_color[CG] = [color whiteComponent] * 255;
        info.end_color[alphaPos] = [options endOpacity] * 255;
    }

	// Work out the rectangle for the gradient
	if ([[document selection] active])
		rect = [[document selection] localRect];
	else
		rect = IntMakeRect(0, 0, [[contents activeLayer] width], [[contents activeLayer] height]);
	
	GCFillGradient([[document whiteboard] overlay], [[contents activeLayer] width], [[contents activeLayer] height], rect, SPP, info, NULL);

    [[document helpers] overlayChanged:rect];
	[[document helpers] applyOverlay];
	
	intermediate = NO;
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    IntRect old = IntMakeRect(startPoint.x, startPoint.y,  tempPoint.x - startPoint.x, tempPoint.y - startPoint.y);

    tempPoint = where;

    IntRect dirty = IntMakeRect(startPoint.x, startPoint.y,  where.x - startPoint.x, where.y - startPoint.y);

    [[document docView] setNeedsDisplayInLayerRect:IntSumRects(old,dirty):8];
}

- (void)endLineDrawing
{
    if(!intermediate)
        return;

    [[document helpers] applyOverlay];
    intermediate=NO;
}

- (AbstractOptions*)getOptions
{
    return options;
}

- (IntPoint)start
{
    return startPoint;
}
- (IntPoint)current
{
    return tempPoint;
}


@end

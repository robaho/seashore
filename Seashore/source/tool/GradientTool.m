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

@implementation GradientTool

- (int)toolId
{
	return kGradientTool;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	startPoint = where;
	intermediate = YES;
	startNSPoint = [[document docView] convertPoint:[event locationInWindow] fromView:NULL];

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
	if ([contents spp] == 4) {
		color = [contents foreground];
		info.start_color[0] = [color redComponent] * 255;
		info.start_color[1] = [color greenComponent] * 255;
		info.start_color[2] = [color blueComponent] * 255;
		info.start_color[3] = [color alphaComponent] * 255;
		info.end = where;
		color = [contents background];
		info.end_color[0] = [color redComponent] * 255;
		info.end_color[1] = [color greenComponent] * 255;
		info.end_color[2] = [color blueComponent] * 255;
		info.end_color[3] = [color alphaComponent] * 255;
	}
	else {
		color = [contents foreground];
		info.start_color[0] = info.start_color[1] = info.start_color[2] = [color whiteComponent] * 255;
		info.start_color[3] = [color alphaComponent] * 255;
		info.end = where;
		color = [contents background];
		info.end_color[0] = info.end_color[1] = info.end_color[2] = [color whiteComponent] * 255;
		info.end_color[3] = [color alphaComponent] * 255;
	}
	
	// Work out the rectangle for the gradient
	if ([[document selection] active])
		rect = [[document selection] localRect];
	else
		rect = IntMakeRect(0, 0, [(SeaLayer *)[contents activeLayer] width], [(SeaLayer *)[contents activeLayer] height]);
	
	// Draw the gradient
	GCFillGradient([[document whiteboard] overlay], [(SeaLayer *)[contents activeLayer] width], [(SeaLayer *)[contents activeLayer] height], rect, [contents spp], info, NULL);
	
	// Apply the changes
	[(SeaHelpers *)[document helpers] applyOverlay];
	
	intermediate = NO;
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	tempNSPoint = [[document docView] convertPoint:[event locationInWindow] fromView:NULL];
	[[document docView] setNeedsDisplay: YES];
}


- (NSPoint)start
{
	return startNSPoint;
}

- (NSPoint)current
{
	return tempNSPoint;
}

- (AbstractOptions*)getOptions
{
    return options;
}
- (void)setOptions:(AbstractOptions*)newoptions
{
    options = (GradientOptions*)newoptions;
}


@end

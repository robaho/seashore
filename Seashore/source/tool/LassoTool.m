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


- (void)fineMouseDownAt:(NSPoint)where withEvent:(NSEvent *)event
{
	id layer = [[document contents] activeLayer];
	[super mouseDownAt:IntMakePoint(where.x - [layer xoff], where.y - [layer yoff]) withEvent:event];
		
	if(![super isMovingOrScaling]){
		where.x -= [layer xoff];
		where.y -= [layer yoff];

		// Create the points list
		points = malloc(kMaxLTPoints * sizeof(IntPoint));
		pos = 0;
		points[0] =  NSPointMakeIntPoint(where);
		lastPoint = [[document docView] convertPoint:[event locationInWindow] fromView:NULL];
		[[document docView] setNeedsDisplay:YES];
		intermediate = YES;
	}
}

- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event
{
	id layer = [[document contents] activeLayer];
	[super mouseDraggedTo:IntMakePoint(where.x - [layer xoff], where.y - [layer yoff]) withEvent:event];
	
	if(intermediate && ![super isMovingOrScaling]){
		int width, height;
		where.x -= [layer xoff];
		where.y -= [layer yoff];

		// Check we have a valid start point
		// Check this point is different to the last
		if (pos < kMaxLTPoints - 1) {

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
			}
		}
		[[document docView] setNeedsDisplay:YES];
	}
}

- (void)fineMouseUpAt:(NSPoint)where withEvent:(NSEvent *)event
{
	id layer = [[document contents] activeLayer];
	[super mouseUpAt:IntMakePoint(where.x - [layer xoff], where.y - [layer yoff]) withEvent:event];
	
	// Check we have a valid start point
	if (intermediate && ![super isMovingOrScaling]) {
		unsigned char *overlay = [[document whiteboard] overlay];
		unsigned char *fakeOverlay;
		int width = [(SeaLayer *)layer width], height = [(SeaLayer *)layer height];
		float xScale, yScale;
		int fakeHeight, fakeWidth;
		int interpolation;
		int spp = [[document contents] spp];
		int tpos;
		IntRect rect;
		GimpVector2 *gimpPoints;

		// Redraw canvas
		[[document docView] setNeedsDisplay:YES];

		// Clear last selection
		if([options selectionMode] == kDefaultMode || [options selectionMode] == kForceNewMode)
			[[document selection] clearSelection];
		
		// No single-pixel loops
		if (pos <= 1) return;

		// Fill out the variables
		if([[document docView] zoom] <= 1){
			interpolation = GIMP_INTERPOLATION_NONE;
		}else{
			interpolation = GIMP_INTERPOLATION_CUBIC;
		}
					
		// Create an overlay that's the size of what the user sees
		xScale = [[document contents] xscale];
		yScale = [[document contents] yscale];
		fakeHeight = height * yScale;
		fakeWidth  = width * xScale;
		fakeOverlay = malloc(make_128(fakeWidth * fakeHeight * spp));
		memset(fakeOverlay, 0, fakeWidth * fakeHeight * spp);

		// Reconnect the loop
		pos++;
		points[pos] = points[0];
		gimpPoints = malloc((pos) * sizeof(GimpVector2));

		// Find the rectangle of the selection
		rect.origin = points[0];
		rect.size.width = rect.size.height = 1;
		for (tpos = 1; tpos <= pos; tpos++) {
			// Scale the points depending on the zoom
			points[tpos].x *= xScale;
			points[tpos].y *= yScale;
			
			if (points[tpos].x < rect.origin.x) {
				rect.size.width += rect.origin.x - points[tpos].x;
				rect.origin.x = points[tpos].x; 
			}
			
			if (points[tpos].y < rect.origin.y) {
				rect.size.height += rect.origin.y - points[tpos].y;
				rect.origin.y = points[tpos].y;
			}

			if (points[tpos].x >= rect.origin.x + rect.size.width)
				rect.size.width = points[tpos].x - rect.origin.x;
				
			if (points[tpos].y >= rect.origin.y + rect.size.height)
				rect.size.height = points[tpos].y - rect.origin.y;
				
			gimpPoints[tpos - 1].x = (double)points[tpos].x;
			gimpPoints[tpos - 1].y = (double)points[tpos].y;			

		}
		
		// Ensure an IntRect (as opposed to NSRect)
		rect.origin.x = (int)floor(rect.origin.x / xScale);
		rect.origin.y = (int)floor(rect.origin.y / yScale);
		rect.size.width = (int)ceil(rect.size.width / xScale);
		rect.size.height = (int)ceil(rect.size.height / yScale);			
		
		
		// Fill in region
		GCDrawPolygon(fakeOverlay, fakeWidth, fakeHeight, gimpPoints, pos, spp);
		// Scale region to the actual size of the overlay
		GCScalePixels(overlay, width, height, fakeOverlay, fakeWidth, fakeHeight, interpolation, spp);
	
		// Then select it
		[[document selection] selectOverlay:YES inRect:rect mode:[options selectionMode]];	
			
		// Release the fake (scaled) overlay
		free(fakeOverlay);
		intermediate = NO;
		[[document docView] setNeedsDisplay:YES];
	}

	translating = NO;
	scalingDir = kNoDir;
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

@end

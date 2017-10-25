#import "SmudgeTool.h"
#import "SeaTools.h"
#import "SeaBrush.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "BrushUtility.h"
#import "SeaLayer.h"
#import "StandardMerge.h"
#import "SeaHelpers.h"
#import "SeaWhiteboard.h"
#import "SmudgeOptions.h"

#define EPSILON 0.0001

@implementation SmudgeTool

- (int)toolId
{
	return kSmudgeTool;
}


- (void)dealloc
{
	[super dealloc];
}

- (BOOL)useMouseCoalescing
{
	return NO;
}

- (void)smudgeWithBrush:(id)brush at:(NSPoint)point
{
	id contents = [document contents];
	id layer = [contents activeLayer];
	unsigned char *overlay = [[document whiteboard] overlay], *data = [(SeaLayer *)layer data], *replace = [(SeaWhiteboard *)[document whiteboard] replace];
	unsigned char *brushData, basePixel[4];
	int brushWidth = [(SeaBrush *)brush fakeWidth], brushHeight = [(SeaBrush *)brush fakeHeight];
	int width = [(SeaLayer *)layer width], height = [(SeaLayer *)layer height];
	int i, j, k, tx, ty, t1, t2, pos, spp = [[document contents] spp];
	int rate = [(SmudgeOptions *)options rate];
	IntPoint ipoint = NSPointMakeIntPoint(point);
	int selectedChannel = [[document contents] selectedChannel];
	
	// Get the approrpiate brush data for the point
	brushData = [brush maskForPoint:point pressure:255];

	// Go through all valid points
	for (j = 0; j < brushHeight; j++) {
		for (i = 0; i < brushWidth; i++) {
			tx = ipoint.x + i;
			ty = ipoint.y + j;
			if (tx >= 0 && ty >= 0 && tx < width && ty < height) {
				
				// Change the pixel colour appropriately
				pos = ty * width + tx;
				if (replace[pos] == 255) {
					if (selectedChannel == kAlphaChannel)
						basePixel[spp - 1] = overlay[pos * spp];
					else
						memcpy(basePixel, &(overlay[pos * spp]), spp);
				}
				else if (replace[pos] == 0) {
					memcpy(basePixel, &(data[pos * spp]), spp);
				}
				else {
					if (selectedChannel == kAlphaChannel) {
						basePixel[spp - 1] = int_mult(overlay[pos * spp], replace[pos], t1) + int_mult(data[(pos + 1) * spp - 1], 255 - replace[pos], t2);
					}
					else {
						for (k = 0; k < spp; k++)
							basePixel[k] = int_mult(overlay[pos * spp + k], replace[pos], t1) + int_mult(data[pos * spp + k], 255 - replace[pos], t2);
					}
				}
				if (selectedChannel == kPrimaryChannels) {
					basePixel[spp - 1] = 255;
				}
				else if (selectedChannel == kAlphaChannel) {
					for (k = 0; k < spp - 1; k++)
						basePixel[k] = basePixel[spp - 1];
					basePixel[spp - 1] = 255;
				}
				blendPixel(spp, accumData, (j * brushWidth + i) * spp, basePixel, 0, rate);
				replace[pos] = brushData[j * brushWidth + i] + int_mult((255 - brushData[j * brushWidth + i]), replace[pos], t1);
				memcpy(&(overlay[pos * spp]), &(accumData[(j * brushWidth + i) * spp]), spp);
				
			}
		}
	}
	
	// Set the last plot point appropriately
	lastPlotPoint = point;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	id layer = [[document contents] activeLayer];
	int layerWidth = [(SeaLayer *)layer width], layerHeight = [(SeaLayer *)layer height];
	unsigned char *data = [(SeaLayer *)layer data];
	id curBrush = [[[SeaController utilitiesManager] brushUtilityFor:document] activeBrush];
	int brushWidth = [(SeaBrush *)curBrush fakeWidth], brushHeight = [(SeaBrush *)curBrush fakeHeight];
	int i, j, k, tx, ty, spp = [[document contents] spp];
	NSPoint curPoint = IntPointMakeNSPoint(where), temp;
	int selectedChannel = [[document contents] selectedChannel];
	unsigned char basePixel[4];
	NSColor *color = NULL;
	IntRect rect;
	
	// Prepare for the accumulating data
	lastWhere.x = where.x;
	lastWhere.y = where.y;
	if (accumData) { free(accumData); accumData = NULL; }
	accumData = malloc(brushWidth * brushHeight * spp);
	memset(accumData, 0, brushWidth * brushHeight * spp);
	if (![layer hasAlpha]) {
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
		for (i = 0; i < brushWidth * brushHeight; i++)
			memcpy(&(accumData[i * spp]), basePixel, spp);
	}
	
	// Fill the accumulator with what's beneath the brush to start with
	for (j = 0; j < brushHeight; j++) {
		for (i = 0; i < brushWidth; i++) {
			tx = where.x - brushWidth / 2 + i;
			ty = where.y - brushHeight / 2 + j;
			if (tx >= 0 && tx < layerWidth && ty >= 0 && ty < layerHeight) {
				memcpy(&(accumData[(j * brushWidth + i) * spp]), &(data[(ty * layerWidth + tx) * spp]), spp);
				if (selectedChannel == kPrimaryChannels) {
					accumData[(j * brushWidth + i + 1) * spp - 1] = 255;
				}
				else if (selectedChannel == kAlphaChannel) {
					for (k = 0; k < spp - 1; k++)
						accumData[(j * brushWidth + i) * spp + k] = accumData[(j * brushWidth + i + 1) * spp - 1];
					accumData[(j * brushWidth + i + 1) * spp - 1] = 255;
				}
			}
		}
	}
		
	// Make the overlay opaque
	[[document whiteboard] setOverlayOpacity:255];
	[[document whiteboard] setOverlayBehaviour:kReplacingBehaviour];
	
	// Plot the intial point
	rect.size.width = [(SeaBrush *)curBrush fakeWidth] + 1;
	rect.size.height = [(SeaBrush *)curBrush fakeHeight] + 1;
	temp = NSMakePoint((int)curPoint.x - [(SeaBrush *)curBrush width] / 2, (int)curPoint.y - [(SeaBrush *)curBrush height] / 2);
	rect.origin = NSPointMakeIntPoint(temp);
	rect = IntConstrainRect(rect, IntMakeRect(0, 0, [(SeaLayer *)layer width], [(SeaLayer *)layer height]));
	if (rect.size.width > 0 && rect.size.height > 0) {
		[self smudgeWithBrush:curBrush at:temp];
		[[document helpers] overlayChanged:rect inThread:NO];
	}
	
	// Record the position as the last point
	lastPoint = lastPlotPoint = IntPointMakeNSPoint(where);
	distance = 0;
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	id layer = [[document contents] activeLayer];
	int layerWidth = [(SeaLayer *)layer width], layerHeight = [(SeaLayer *)layer height];
	id curBrush = [[[SeaController utilitiesManager] brushUtilityFor:document] activeBrush];
	int brushWidth = [(SeaBrush *)curBrush fakeWidth], brushHeight = [(SeaBrush *)curBrush fakeHeight];
	NSPoint curPoint = IntPointMakeNSPoint(where);
	double brushSpacing = 1.0 / 100.0;
	double deltaX, deltaY, mag, xd, yd, dist;
	double stFactor, stOffset;
	double t0, dt, tn, t;
	double total, initial;
	int n, num_points;
	IntRect rect;
	NSPoint temp;
	
	// Check this is a new point
	if (where.x == lastWhere.x && where.y == lastWhere.y) {
		return;
	}
	else {
		lastWhere = where;
	}
	
	// Determine the change in the x and y directions
	deltaX = curPoint.x - lastPoint.x;
	deltaY = curPoint.y - lastPoint.y;
	if (deltaX == 0.0 && deltaY == 0.0)
		return;
	
	// Determine the number of brush strokes in the x and y directions
	mag = (float)(brushWidth / 2);
	xd = (mag * deltaX) / sqr(mag);
	mag = (float)(brushHeight / 2);
	yd = (mag * deltaY) / sqr(mag);
	
	// Determine the brush stroke distance and hence determine the initial and total distance
	dist = 0.5 * sqrt(sqr(xd) + sqr(yd));		// Why is this halved?
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
		if ((t0 < 0.0 && !(x == (int)floor(lastPoint.x) && y == (int)floor(lastPoint.y))) || (x == (int)floor(lastPlotPoint.x) && y == (int)floor(lastPlotPoint.y))) s0 += direction;
		x = (int)floor(lastPoint.x + tn * deltaX);
		y = (int)floor(lastPoint.y + tn * deltaY);
		if (tn > 1.0 && !(x == (int)floor(lastPoint.x) && y == (int)floor(lastPoint.y))) sn -= direction;
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
		temp = NSMakePoint(lastPoint.x + deltaX * t - (double)(brushWidth / 2) + 1.0, lastPoint.y + deltaY * t - (float)(brushHeight / 2) + 1.0);
		rect.origin = NSPointMakeIntPoint(temp);
		rect = IntConstrainRect(rect, IntMakeRect(0, 0, layerWidth, layerHeight));
		if (rect.size.width > 0 && rect.size.height > 0) {
			[self smudgeWithBrush:curBrush at:temp];
			[[document helpers] overlayChanged:rect inThread:NO];
		}
	}
	
	// Update the distance and plot points
	distance = total;
	lastPoint.x = lastPoint.x + deltaX;
	lastPoint.y = lastPoint.y + deltaY; 
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	// Apply the changes
	[(SeaHelpers *)[document helpers] applyOverlay];

	// Free the accumulating data
	if (accumData) { free(accumData); accumData = NULL; }
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

@end

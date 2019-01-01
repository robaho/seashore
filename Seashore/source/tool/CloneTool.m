#import "CloneTool.h"
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
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "Bucket.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "CloneOptions.h"

#define EPSILON 0.0001

@implementation CloneTool

- (int)toolId
{
	return kCloneTool;
}

- (id)init
{
	if(![super init])
		return NULL;
	sourceSet = NO;
	mergedData = NULL;
	return self;
}

- (BOOL)acceptsLineDraws
{
	return NO;
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

- (BOOL)sourceSet
{
	return sourceSet;
}

- (int)sourceSetting
{
	return sourceSetting;
}

- (IntPoint)sourcePoint:(BOOL)local
{
	IntPoint outPoint;
	
	if (local) {
		outPoint.x = sourcePoint.x;
		outPoint.y = sourcePoint.y;
	}
	else {
		outPoint.x = sourcePoint.x + layerOff.x;
		outPoint.y = sourcePoint.y + layerOff.y;
	}
	
	return outPoint;
}

- (NSString *)sourceName
{
	if (sourceMerged == NO)
		return [(SeaLayer *)sourceLayer name];
	else
		return NULL;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	id layer = [[document contents] activeLayer];
	id curBrush = [[[SeaController utilitiesManager] brushUtilityFor:document] activeBrush];
	NSPoint curPoint = IntPointMakeNSPoint(where), temp;
	IntRect rect;
	int spp = [[document contents] spp];
	int pressure = 255; // [options pressureValue:event];
	BOOL ignoreFirstTouch;
	unsigned char *sourceData;
	int sourceWidth, sourceHeight;
	IntPoint spt;
	float xScale, yScale;
	int modifier = [(CloneOptions*)options modifier];
	
	if (modifier == kAltModifier) {
		xScale = [[document contents] xscale];
		yScale = [[document contents] yscale];
		if (sourceSetting > 0) {
			sourceSetting = 0;
			[[document docView] setNeedsDisplayInRect:NSMakeRect((sourcePoint.x + layerOff.x) * xScale - 12, (sourcePoint.y + layerOff.y) * yScale - 10, 25, 26)];
		}
		sourceMerged = [options mergedSample];
		if (sourceMerged) {
			layerOff.x = [[[document contents] activeLayer] xoff];
			layerOff.y = [[[document contents] activeLayer] yoff];
			sourcePoint = where;
			sourceSet = NO;
			sourceWidth = [(SeaContent *)[document contents] width];
			sourceHeight = [(SeaContent *)[document contents] height];
			sourceSetting = 100;
		}
		else {
			layerOff.x = [[[document contents] activeLayer] xoff];
			layerOff.y = [[[document contents] activeLayer] yoff];
			sourcePoint = where;
			sourceSet = NO;
			sourceLayer = [[document contents] activeLayer];
			sourceSetting = 100;
		}
		[[document docView] setNeedsDisplayInRect:NSMakeRect((sourcePoint.x + layerOff.x) * xScale - 12, (sourcePoint.y + layerOff.y) * yScale - 10, 25, 26)];
	}
	else if (sourceSet) {
		
		// Find the source
		if (sourceMerged) {
			sourceWidth = [(SeaContent *)[document contents] width];
			sourceHeight = [(SeaContent *)[document contents] height];
			if (mergedData) {
				free(mergedData);
				mergedData = NULL;
			}
			mergedData = malloc(make_128(sourceWidth * sourceHeight * spp));
			memcpy(mergedData, [(SeaWhiteboard *)[document whiteboard] data], sourceWidth * sourceHeight * spp);
			sourceData = mergedData;
		}
		else {
			sourceData = [(SeaLayer *)sourceLayer data];
			sourceWidth = [(SeaLayer *)sourceLayer width];
			sourceHeight = [(SeaLayer *)sourceLayer height];
		}
		
		// Determine whether operation should continue
		startPoint.x = where.x;
		startPoint.y = where.y;
		lastWhere.x = where.x;
		lastWhere.y = where.y;
		ignoreFirstTouch = [[SeaController seaPrefs] ignoreFirstTouch];
		if (ignoreFirstTouch && ([event type] == NSLeftMouseDown || [event type] == NSRightMouseDown) /* && [options pressureSensitive] */ && !(modifier == kAltModifier)) { 
			firstTouchDone = NO;
			return;
		}
		else {
			firstTouchDone = YES;
		}
		
		// Set the appropriate overlay opacity
		isErasing = NO;
		[[document whiteboard] setOverlayOpacity:255];
		[[document whiteboard] setOverlayBehaviour:kMaskingBehaviour];
		
		// Plot the initial point
		rect.size.width = [(SeaBrush *)curBrush fakeWidth] + 1;
		rect.size.height = [(SeaBrush *)curBrush fakeHeight] + 1;
		temp = NSMakePoint(curPoint.x - (float)([(SeaBrush *)curBrush width] / 2) - 1.0, curPoint.y - (float)([(SeaBrush *)curBrush height] / 2) - 1.0);
		rect.origin = NSPointMakeIntPoint(temp);
		rect.origin.x--; rect.origin.y--;
		rect = IntConstrainRect(rect, IntMakeRect(0, 0, [(SeaLayer *)layer width], [(SeaLayer *)layer height]));
		if (rect.size.width > 0 && rect.size.height > 0) {
			[self plotBrush:curBrush at:temp pressure:pressure];
			if (!isErasing) {
				spt.x = sourcePoint.x + (rect.origin.x - startPoint.x) - 1;
				spt.y = sourcePoint.y + (rect.origin.y - startPoint.y) - 1;
				cloneFill(spp, rect, [[document whiteboard] overlay], [[document whiteboard] replace], [(SeaLayer *)layer width], [(SeaLayer *)layer height], sourceData, sourceWidth, sourceHeight, spt);
			}
			[[document helpers] overlayChanged:rect inThread:YES];
		}
		
		// Record the position as the last point
		lastPoint = lastPlotPoint = curPoint;
		distance = 0;
		
		// Create the points list
		points = malloc(kMaxBTPoints * sizeof(CTPointRecord));
		pos = drawingPos = 0;
		lastPressure = -1;
	}
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
	double t0, dt, tn, t;
	double total, initial;
	int n, num_points, spp;
	IntRect rect, trect, bigRect;
	NSPoint temp;
	int pressure, origPressure;
	NSDate *lastDate;
	unsigned char *sourceData;
	int sourceWidth, sourceHeight;
	IntPoint spt;

	// Set-up variables
	layer = [[document contents] activeLayer];
	curBrush = [[[SeaController utilitiesManager] brushUtilityFor:document] activeBrush];
	layerWidth = [(SeaLayer *)layer width];
	layerHeight = [(SeaLayer *)layer height];
	brushWidth = [(SeaBrush *)curBrush fakeWidth];
	brushHeight = [(SeaBrush *)curBrush fakeHeight];
	activeTexture = [[[SeaController utilitiesManager] textureUtilityFor:document] activeTexture];
	brushSpacing = (double)[(BrushUtility*)[[SeaController utilitiesManager] brushUtilityFor:document] spacing] / 100.0;
	spp = [[document contents] spp];
	bigRect = IntMakeRect(0, 0, 0, 0);
	lastDate = [NSDate date];
	if (sourceMerged) {
		sourceData = mergedData;
		sourceWidth = [(SeaContent *)[document contents] width];
		sourceHeight = [(SeaContent *)[document contents] height];
	}
	else {
		sourceData = [(SeaLayer *)sourceLayer data];
		sourceWidth = [(SeaLayer *)sourceLayer width];
		sourceHeight = [(SeaLayer *)sourceLayer height];
	}
	
	// While we are not done...
	do {

next:
		if (drawingPos < pos) {
			
			// Get the next record and carry on
			curPoint = IntPointMakeNSPoint(points[drawingPos].point);
			origPressure = points[drawingPos].pressure;
			if (points[drawingPos].special == 2) {
				if (bigRect.size.width != 0) [[document helpers] overlayChanged:bigRect inThread:YES];
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
				pressure = origPressure;
				if (lastPressure > -1 && abs(pressure - lastPressure) > 5) {
					pressure = lastPressure + 5 * sgn(pressure - lastPressure);
				}
				lastPressure = pressure;
				if (rect.size.width > 0 && rect.size.height > 0 && pressure > 0) {
					[self plotBrush:curBrush at:temp pressure:pressure];
					if (!isErasing) {
						spt.x = sourcePoint.x + (rect.origin.x - startPoint.x) - 1;
						spt.y = sourcePoint.y + (rect.origin.y - startPoint.y) - 1;
						cloneFill(spp, rect, [[document whiteboard] overlay], [[document whiteboard] replace], [(SeaLayer *)layer width], [(SeaLayer *)layer height], sourceData, sourceWidth, sourceHeight, spt);
					}
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
		
        [[document helpers] overlayChanged:bigRect inThread:YES];
	} while (false /*multithreaded*/);
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	if (sourceSet) {

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
			points[pos].pressure = 255; // [options pressureValue:event];
			pos++;
		}
		else if (pos == kMaxBTPoints - 1) {
			points[pos].special = 2;
			pos++;
		}
		
        [self drawThread:NULL];
	}
}

- (void)endLineDrawing
{
	// Tell the other thread to terminate
	if (pos < kMaxBTPoints) {
		points[pos].special = 2;
		pos++;
	}

    [self drawThread:NULL];
}

- (IBAction)fade:(id)sender
{
	float xScale, yScale;
	
	if (sourceSetting > 0) {
		sourceSetting -= 20;
		fadingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(fade:) userInfo:NULL repeats:NO];
		xScale = yScale = 1.0;
		xScale = [[document contents] xscale];
		yScale = [[document contents] yscale];
		[[document docView] setNeedsDisplayInRect:NSMakeRect((sourcePoint.x + layerOff.x) * xScale - 12, (sourcePoint.y + layerOff.y) * yScale - 10, 25, 26)];
	}
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	float xScale, yScale;
	
	if (sourceSetting) {
		
		// Start the source setting
		fadingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(fade:) userInfo:NULL repeats:NO];
		sourceSet = YES;
		xScale = [[document contents] xscale];
		yScale = [[document contents] yscale];
		[[document docView] setNeedsDisplayInRect:NSMakeRect((sourcePoint.x + layerOff.x) * xScale - 12, (sourcePoint.y + layerOff.y) * yScale - 10, 25, 26)];
		[options update];
	
	}
	else if (sourceSet) {
		
		// Apply the changes
		[self endLineDrawing];
		[(SeaHelpers *)[document helpers] applyOverlay];
		
	}
	
	// Free merged data
	if (mergedData) {
		free(mergedData);
		mergedData = NULL;
	}
}

- (void)unset
{
	sourceSet = NO;
	[options update];
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
    options = (CloneOptions*)newoptions;
}


@end

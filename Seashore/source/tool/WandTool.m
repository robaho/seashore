#import "WandTool.h"
#import "SeaTools.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "Bucket.h"
#import "SeaWhiteboard.h"
#import "WandOptions.h"
#import "SeaSelection.h"

@implementation WandTool

- (int)toolId
{
	return kWandTool;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	[super mouseDownAt:where withEvent:event];
	
	if(![super isMovingOrScaling]){
		startPoint = where;
		startNSPoint = [[document docView] convertPoint:[event locationInWindow] fromView:NULL];
		currentNSPoint = [[document docView] convertPoint:[event locationInWindow] fromView:NULL];
		intermediate = YES;
	}
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	[super mouseDraggedTo:where withEvent:event];
	
	if(![super isMovingOrScaling]){
		currentNSPoint = [[document docView] convertPoint:[event locationInWindow] fromView:NULL];
		[[document docView] setNeedsDisplay: YES];
	}
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	[super mouseUpAt:where withEvent:event];

	if(![super isMovingOrScaling]){
		id layer = [[document contents] activeLayer];
		int tolerance, width = [(SeaLayer *)layer width], height = [(SeaLayer *)layer height], spp = [[document contents] spp], k;
		unsigned char *overlay = [[document whiteboard] overlay], *data = [(SeaLayer *)layer data];
		unsigned char basePixel[4];
		IntRect rect;
			
		// Check for a valid click
		if (where.x >= 0 && where.y >= 0 && where.x < width && where.y < height) {
			
			// Clear last selection
			if([options selectionMode] == kDefaultMode || [options selectionMode] == kForceNewMode)
				[[document selection] clearSelection];
				
			// Fill the region to be selected
			for (k = 0; k < spp - 1; k++)
				basePixel[k] = 0;
			basePixel[spp - 1] = 255;
			tolerance = [(WandOptions*)options tolerance];
			int mode = [options selectionMode];
			int intervals = [options numIntervals];
			
			IntPoint* seeds = malloc(sizeof(IntPoint) * (intervals + 1));
			
			int seedIndex;
			int xDelta = where.x - startPoint.x;
			int yDelta = where.y - startPoint.y;
			for(seedIndex = 0; seedIndex <= intervals; seedIndex++){
				int x = startPoint.x + (int)ceil(xDelta * ((float)seedIndex / intervals));
				int y = startPoint.y + (int)ceil(yDelta * ((float)seedIndex / intervals));
				seeds[seedIndex] = IntMakePoint(x, y);				
			}
				
			rect = bucketFill(spp, IntMakeRect(0, 0, width, height), overlay, data, width, height, seeds, intervals + 1, basePixel, tolerance, [[document contents] selectedChannel]);
			free(seeds);
			
			// Then select it
			[[document selection] selectOverlay:YES inRect:rect mode: mode];			
		}
		intermediate = NO;

	}

	translating = NO;
	scalingDir = kNoDir;
}

- (NSPoint)start
{
	return startNSPoint;
}

-(NSPoint)current
{
	return currentNSPoint;
}

@end

#import "PencilTool.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "StandardMerge.h"
#import "SeaWhiteboard.h"
#import "SeaLayerUndo.h"
#import "SeaView.h"
#import "PencilOptions.h"
#import "SeaController.h"
#import "OptionsUtility.h"
#import "SeaHelpers.h"
#import "SeaTools.h"
#import "SeaLayer.h"
#import "SeaTexture.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "Bucket.h"

@implementation PencilTool

- (int)toolId
{
	return kPencilTool;
}

- (void)dealloc
{
	[super dealloc];
}

- (BOOL)acceptsLineDraws
{
	return YES;
}

- (BOOL)useMouseCoalescing
{
	return NO;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	id activeTexture = [[[SeaController utilitiesManager] textureUtilityFor:document] activeTexture];
	id layer = [[document contents] activeLayer];
	BOOL hasAlpha = [layer hasAlpha];
	unsigned char *overlay = [[document whiteboard] overlay];
	int width = [(SeaLayer *)layer width], height = [(SeaLayer *)layer height];
	int i, j, k, spp = [[document contents] spp];
	int halfSize;
	IntPoint curPoint;
	NSColor *color = NULL;
	IntRect rect;
	int modifier = [options modifier];
	
	// Determine base pixels and hence pencil colour
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
		basePixel[spp - 1] = 255;
	}
	else if (spp == 4) {
		color = [[document contents] foreground];
		basePixel[0] = (unsigned char)([color redComponent] * 255.0);
		basePixel[1] = (unsigned char)([color greenComponent] * 255.0);
		basePixel[2] = (unsigned char)([color blueComponent] * 255.0);
		basePixel[3] = 255;
	}
	else {
		color = [[document contents] foreground];
		basePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
		basePixel[1] = 255;
	}
	
	// Set the appropriate overlay opacity
	if ([options pencilIsErasing]) {
		if (hasAlpha)
			[[document whiteboard] setOverlayBehaviour:kErasingBehaviour];
		[[document whiteboard] setOverlayOpacity:255];
	}
	else {
		if ([options useTextures])
			[[document whiteboard] setOverlayOpacity:[[[SeaController utilitiesManager] textureUtilityFor:document] opacity]];
		else
			[[document whiteboard] setOverlayOpacity:[color alphaComponent] * 255.0];
	}
	
	// Determine the pencil size
	size = [options pencilSize];
	halfSize = (size % 2 == 0) ? size / 2 - 1 : size / 2;
	
	// Work out the update rectangle
	rect = IntMakeRect(where.x - halfSize, where.y - halfSize, size, size);
	rect = IntConstrainRect(rect, IntMakeRect(0, 0, [(SeaLayer *)layer width], [(SeaLayer *)layer height]));
	if (rect.size.width > 0 && rect.size.height > 0) {
		
		// Draw the initial dot
		for (j = 0; j < size; j++) {
			for (i = 0; i < size; i++) {
				curPoint.x = where.x - halfSize + i;
				curPoint.y = where.y - halfSize + j;
				if (curPoint.x >= 0 && curPoint.x < width && curPoint.y >= 0 && curPoint.y < height) {
					for (k = 0; k < spp; k++)
						overlay[(curPoint.y * width + curPoint.x) * spp + k] = basePixel[k];
				}
			}
		}
		
		// Do the update
		if ([options useTextures] && ![options pencilIsErasing])
			textureFill(spp, rect, [[document whiteboard] overlay], [(SeaLayer *)layer width], [(SeaLayer *)layer height], [activeTexture texture:(spp == 4)], [(SeaTexture *)activeTexture width], [(SeaTexture *)activeTexture height]);
		[[document helpers] overlayChanged:rect inThread:NO];
	
	}
	
	// Record the position as the last point
	lastPoint = where;
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	id activeTexture = [[[SeaController utilitiesManager] textureUtilityFor:document] activeTexture];
	id layer = [[document contents] activeLayer];
	unsigned char *overlay = [[document whiteboard] overlay];
	int width = [(SeaLayer *)layer width], height = [(SeaLayer *)layer height];
	int xMod = (lastPoint.x > where.x) ? -1 : 1, yMod = (lastPoint.y > where.y) ? -1 : 1;
	int xDist = abs(lastPoint.x - where.x), yDist = abs(lastPoint.y - where.y);
	int i, i2, j2, k, spp = [[document contents] spp];
	IntPoint curPoint, revisedCurPoint, newLastPoint;
	int halfSize = (size % 2 == 0) ? size / 2 - 1 : size / 2;
	IntRect rect;
	
	// Only continue if the current point is different from the last point
	if (lastPoint.x == where.x && lastPoint.y == where.y)
		return;
	
	// If nothing changes we want the new last point to be the same as the old one
	newLastPoint = lastPoint;
	
	// Draw a line between the last point and this point
	for (i = 1; i <= MAX(xDist, yDist); i++) {
		if (xDist > yDist) {
			curPoint.x = lastPoint.x + i * xMod;
			curPoint.y = lastPoint.y + (i * yDist) / xDist * yMod;
		}
		else {
			curPoint.x = lastPoint.x + (i * xDist) / yDist * xMod;
			curPoint.y = lastPoint.y + i * yMod;
		}
		
		rect = IntMakeRect(curPoint.x - halfSize, curPoint.y - halfSize, size, size);
		rect = IntConstrainRect(rect, IntMakeRect(0, 0, [(SeaLayer *)layer width], [(SeaLayer *)layer height]));
		if (rect.size.width > 0 && rect.size.height > 0) {

			for (i2 = 0; i2 < size; i2++) {
				for (j2 = 0; j2 < size; j2++) {
					revisedCurPoint.x = curPoint.x - halfSize + i2;
					revisedCurPoint.y = curPoint.y - halfSize + j2;
					if (revisedCurPoint.x >= 0 && revisedCurPoint.x < width && revisedCurPoint.y >= 0 && revisedCurPoint.y < height) {
						for (k = 0; k < spp; k++)
							overlay[(revisedCurPoint.y * width + revisedCurPoint.x) * spp + k] = basePixel[k];
					}
				}
			}
		
			if ([options useTextures] && ![options pencilIsErasing])
				textureFill(spp, rect, [[document whiteboard] overlay], [(SeaLayer *)layer width], [(SeaLayer *)layer height], [activeTexture texture:(spp == 4)], [(SeaTexture *)activeTexture width], [(SeaTexture *)activeTexture height]);
			[[document helpers] overlayChanged:rect inThread:NO];
		}
		newLastPoint = curPoint;
	}
	
	lastPoint = newLastPoint;
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	// Apply the changes
	[(SeaHelpers *)[document helpers] applyOverlay];
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

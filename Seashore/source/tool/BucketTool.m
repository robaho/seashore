#import "BucketTool.h"
#import "SeaWhiteboard.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "Bucket.h"
#import "OptionsUtility.h"
#import "BucketOptions.h"
#import "StandardMerge.h"
#import "SeaTexture.h"
#import "SeaTools.h"
#import "SeaHelpers.h"
#import "SeaSelection.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "RecentsUtility.h"

@implementation BucketTool

- (int)toolId
{
	return kBucketTool;
}

- (id)init
{
	self = [super init];
	if(self){
		isPreviewing = NO;
	}
	return self;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	startPoint = where;
	
	startNSPoint = [[document docView] convertPoint:[event locationInWindow] fromView:NULL];
	currentNSPoint = [[document docView] convertPoint:[event locationInWindow] fromView:NULL];
	if([(BucketOptions*)options modifier] == kShiftModifier){
		isPreviewing = YES;
	}
	
	intermediate = YES;
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	currentNSPoint = [[document docView] convertPoint:[event locationInWindow] fromView:NULL];
	
	BOOL optionDown = [(BucketOptions*)options modifier] == kAltModifier;

	id layer = [[document contents] activeLayer];
	int width = [(SeaLayer *)layer width], height = [(SeaLayer *)layer height];
	
	[[document whiteboard] clearOverlay];
	[[document helpers] overlayChanged:rect];

	if (where.x < 0 || where.y < 0 || where.x >= width || where.y >= height) {
		rect.size.width = rect.size.height = 0;
	}else if(isPreviewing){
		[self fillAtPoint:where useTolerance:!optionDown delay:YES];
	}
	
	[[document docView] setNeedsDisplay: YES];
}


- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	id layer = [[document contents] activeLayer];
	int width = [(SeaLayer *)layer width], height = [(SeaLayer *)layer height];
	BOOL optionDown = [(BucketOptions*)options modifier] == kAltModifier;
	
	[[document whiteboard] clearOverlay];
	[[document helpers] overlayChanged:rect];

	if (where.x < 0 || where.y < 0 || where.x >= width || where.y >= height) {
		rect.size.width = rect.size.height = 0;
	} else if(!isPreviewing || [(BucketOptions*)options modifier] != kShiftModifier){
		[self fillAtPoint:where useTolerance:!optionDown delay:NO];
	}
	isPreviewing = NO;
	intermediate = NO;
    
    [[[SeaController utilitiesManager] recentsUtilityFor:document] rememberBucket:(BucketOptions*)options];
}

- (void)fillAtPoint:(IntPoint)point useTolerance:(BOOL)useTolerance delay:(BOOL)delay
{
	id layer = [[document contents] activeLayer], activeTexture = [[[SeaController utilitiesManager] textureUtilityFor:document] activeTexture];
	int tolerance, width = [(SeaLayer *)layer width], height = [(SeaLayer *)layer height], spp = [[document contents] spp];
	int textureWidth = [(SeaTexture *)activeTexture width], textureHeight = [(SeaTexture *)activeTexture height];
	unsigned char *overlay = [[document whiteboard] overlay], *data = [(SeaLayer *)layer data];
	unsigned char *texture = [activeTexture texture:(spp == 4)];
	unsigned char basePixel[4];
	NSColor *color = [[document contents] foreground];
	int k, channel;
	
	// Set the overlay to fully opaque
	[[document whiteboard] setOverlayOpacity:255];
	
	// Determine the bucket's colour
	if ([options useTextures]) {
		for (k = 0; k < spp - 1; k++)
			basePixel[k] = 0;
		basePixel[spp - 1] = [(TextureUtility*)[[SeaController utilitiesManager] textureUtilityFor:document] opacity];
	}
	else {
		if (spp == 4) {
			basePixel[0] = (unsigned char)([color redComponent] * 255.0);
			basePixel[1] = (unsigned char)([color greenComponent] * 255.0);
			basePixel[2] = (unsigned char)([color blueComponent] * 255.0);
			basePixel[3] = (unsigned char)([color alphaComponent] * 255.0);
		}
		else {
			basePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
			basePixel[1] = (unsigned char)([color alphaComponent] * 255.0);
		}
	}
	
    int seedIndex;
    int xDelta = point.x - startPoint.x;
    int yDelta = point.y - startPoint.y;
    
    int distance = (int)ceil(sqrt(xDelta*xDelta+yDelta*yDelta));
    int intervals = MAX(MIN(distance,64),1);

    IntPoint* seeds = malloc(sizeof(IntPoint) * (intervals));
    
    for(seedIndex = 0; seedIndex < intervals; seedIndex++){
        int x = startPoint.x + (int)ceil(xDelta * ((float)seedIndex / intervals));
        int y = startPoint.y + (int)ceil(yDelta * ((float)seedIndex / intervals));
        seeds[seedIndex] = IntMakePoint(x, y);
    }
	
	// Fill everything
	if (useTolerance)
		tolerance = [(BucketOptions*)options tolerance];
	else
		tolerance = 255;
	if ([layer floating])
		channel = kPrimaryChannels;
	else
		channel = [[document contents] selectedChannel];
	if ([[document selection] active])
		rect = bucketFill(spp, [[document selection] localRect], overlay, data, width, height, seeds, intervals, basePixel, tolerance, channel);
	else
		rect = bucketFill(spp, IntMakeRect(0, 0, width, height), overlay, data, width, height, seeds, intervals, basePixel, tolerance, channel);
	if ([options useTextures] && IntContainsRect(IntMakeRect(0, 0, width, height), rect)) {
		if ([[document selection] active])
			textureFill(spp, rect, overlay, width, height, texture, textureWidth, textureHeight);
		else
			textureFill(spp, rect, overlay, width, height, texture, textureWidth, textureHeight);
	}
	
	// Do the update
	if (delay)
		[[document helpers] overlayChanged:rect];
	else
		[(SeaHelpers *)[document helpers] applyOverlay];
}

- (NSPoint)start
{
	return startNSPoint;
}

-(NSPoint)current
{
	return currentNSPoint;
}

- (AbstractOptions*)getOptions
{
    return options;
}
- (void)setOptions:(AbstractOptions*)newoptions
{
    options = (BucketOptions*)newoptions;
}


@end

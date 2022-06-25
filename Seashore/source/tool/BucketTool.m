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

	if([options modifier] == kShiftModifier){
		isPreviewing = YES;
	}
	
	intermediate = YES;
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    if(!intermediate)
        return;
    
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:startNSPoint];
    [path lineToPoint:currentNSPoint];

	currentNSPoint = [[document docView] convertPoint:[event locationInWindow] fromView:NULL];
    [path lineToPoint:currentNSPoint];
    NSRect rect = [path bounds];

	BOOL optionDown = [options modifier] == kAltModifier;

	SeaLayer *layer = [[document contents] activeLayer];
	int width = [layer width], height = [layer height];
	
	[[document whiteboard] clearOverlay];

	if (where.x < 0 || where.y < 0 || where.x >= width || where.y >= height) {
		rect.size.width = rect.size.height = 0;
	}else if(isPreviewing){
		[self fillAtPoint:where useTolerance:!optionDown];
	}

    [[document docView] setNeedsDisplayInDocumentRect:NSRectMakeIntRect(rect):8];
}


- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	SeaLayer *layer = [[document contents] activeLayer];
    int width = [layer width], height = [layer height];

	BOOL optionDown = [options modifier] == kAltModifier;
	
	[[document whiteboard] clearOverlay];

	if (where.x < 0 || where.y < 0 || where.x >= width || where.y >= height) {
		rect.size.width = rect.size.height = 0;
	} else if(!isPreviewing || [options modifier] != kShiftModifier){
		[self fillAtPoint:where useTolerance:!optionDown];
        [[document helpers] applyOverlay];
	}

	isPreviewing = NO;
	intermediate = NO;
    
    [[document recentsUtility] rememberBucket:options];
}

- (void)fillAtPoint:(IntPoint)point useTolerance:(BOOL)useTolerance
{
    SeaLayer *layer = [[document contents] activeLayer];
    SeaTexture *activeTexture = [[document textureUtility] activeTexture];
	int tolerance, width = [layer width], height = [layer height], spp = [[document contents] spp];
	int textureWidth = [activeTexture width], textureHeight = [activeTexture height];
	unsigned char *overlay = [[document whiteboard] overlay], *data = [layer data];
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
		basePixel[spp - 1] = [[document textureUtility] opacity];
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
    
    int inrect=0;
    for(seedIndex = 0; seedIndex < intervals; seedIndex++){
        int x = startPoint.x + (int)ceil(xDelta * ((float)seedIndex / intervals));
        int y = startPoint.y + (int)ceil(yDelta * ((float)seedIndex / intervals));
        if(x<0 || x>=width || y <0 || y>=height)
            continue;
        // check if color already exists in seeds
        for(int i=0;i<inrect;i++) {
            if(isSameColor(data,width,spp,x,y,seeds[i].x,seeds[i].y))
                goto next_seed;
        }
        seeds[inrect] = IntMakePoint(x, y);
        inrect++;
    next_seed:
        continue;
    }
    intervals=inrect;
	
	// Fill everything
	if (useTolerance)
		tolerance = [options tolerance];
	else
		tolerance = 255;
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
	
    [[document helpers] overlayChanged:rect];
}

- (NSPoint)start
{
	return startNSPoint;
}

-(NSPoint)current
{
	return currentNSPoint;
}

- (void)endLineDrawing
{
    if(!intermediate)
        return;

    [[document helpers] applyOverlay];
    intermediate=NO;

    [[document recentsUtility] rememberBucket:[self getOptions]];
}

- (AbstractOptions*)getOptions
{
    return options;
}

- (void)setOptions:(AbstractOptions*)newoptions
{
    options = (BucketOptions*)newoptions;
}

- (NSCursor*)toolCursor:(SeaCursors *)cursors
{
    return [cursors usePreciseCursor] ? [cursors crosspointCursor] : [cursors bucketCursor];
}

@end

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

- (void)awakeFromNib {
    options = [[BucketOptions alloc] init:document];
}

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

	if([options modifier] == kShiftModifier){
		isPreviewing = YES;
	}
	
	intermediate = YES;

    if([options useTextures]) {
        CGContextRelease(textureCtx);

        NSImage *pattern = [[[document toolboxUtility] foreground] patternImage];
        int w = pattern.size.width;
        int h = pattern.size.height;

        textureCtx = CGBitmapContextCreate(NULL, w,h, 8, w*SPP, rgbCS, kCGImageAlphaPremultipliedFirst);
        CGImageRef img = [pattern CGImageForProposedRect:NULL context:NULL hints:NULL];
        CGContextDrawImage(textureCtx,CGRectMake(0,0,w,h), img);
        if([[document contents] isGrayscale]) {
            mapARGBtoAGGG(CGBitmapContextGetData(textureCtx),w*h*SPP);
        }
    }
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    if(!intermediate)
        return;

    IntRect dirty = IntMakeRect(startPoint.x,startPoint.y,currentPoint.x-startPoint.x,currentPoint.y-startPoint.y);

    currentPoint = where;
    
    IntRect rect = IntMakeRect(startPoint.x,startPoint.y,currentPoint.x-startPoint.x,currentPoint.y-startPoint.y);

	BOOL optionDown = [options modifier] == kAltModifier;

	[[document whiteboard] clearOverlay];

	if(isPreviewing){
		[self fillAtPoint:where useTolerance:!optionDown opacity:[options opacity]];
	}

    [[document docView] setNeedsDisplayInLayerRect:IntSumRects(dirty, rect):8];
}


- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	BOOL optionDown = [options modifier] == kAltModifier;
	
	[[document whiteboard] clearOverlay];

	if(!isPreviewing || [options modifier] != kShiftModifier){
        [self fillAtPoint:where useTolerance:!optionDown opacity:[options opacity]];
        [[document helpers] applyOverlay];
	}

	isPreviewing = NO;
	intermediate = NO;
    
    [[document recentsUtility] rememberBucket:options];
}

- (void)fillAtPoint:(IntPoint)point useTolerance:(BOOL)useTolerance opacity:(int)opacity
{
    SeaLayer *layer = [[document contents] activeLayer];
	int tolerance, width = [layer width], height = [layer height];
	unsigned char *overlay = [[document whiteboard] overlay], *data = [layer data];
	unsigned char basePixel[4];

	NSColor *color = [[document contents] foreground];
	int channel;
	
	// Set the overlay to fully opaque
	[[document whiteboard] setOverlayOpacity:opacity];
	
	if ([options useTextures]) {
        color = [[NSColor blackColor] colorUsingColorSpace:MyRGBCS];
	}

    if([[document contents] isRGB] || [options useTextures]) {
        basePixel[0] = 255;
        basePixel[1] = (unsigned char)(round([color redComponent] * 255.0));
        basePixel[2] = (unsigned char)round(([color greenComponent] * 255.0));
        basePixel[3] = (unsigned char)(round([color blueComponent] * 255.0));
    } else {
        basePixel[0] = 255;
        basePixel[1] = (unsigned char)(round([color whiteComponent] * 255.0));
        basePixel[2] = (unsigned char)(round([color whiteComponent] * 255.0));
        basePixel[3] = (unsigned char)(round([color whiteComponent] * 255.0));
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
            if(isSameColor(data,width,x,y,seeds[i].x,seeds[i].y))
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

    fillContext ctx;
    ctx.overlay = overlay;
    ctx.data = data;
    ctx.width = width;
    ctx.height = height;
    ctx.tolerance = tolerance;
    ctx.channel = channel;
    ctx.seeds = seeds;
    ctx.numSeeds = intervals;

    memcpy(ctx.fillColor,basePixel,4);

	if ([[document selection] active])
        rect = bucketFill(&ctx,[[document selection] localRect]);
	else
        rect = bucketFill(&ctx,IntMakeRect(0, 0, width, height));

	if ([options useTextures] && IntContainsRect(IntMakeRect(0, 0, width, height), rect)) {
        CGContextRef overlayCtx = [[document whiteboard] overlayCtx];
        textureFill(overlayCtx,textureCtx,rect);
	}
	
    [[document helpers] overlayChanged:rect];
}

- (IntPoint)start
{
	return startPoint;
}

-(IntPoint)current
{
	return currentPoint;
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

- (NSCursor*)toolCursor:(SeaCursors *)cursors
{
    return [cursors usePreciseCursor] ? [cursors crosspointCursor] : [cursors bucketCursor];
}

@end

#import "WandTool.h"
#import "SeaTools.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "Bucket.h"
#import "SeaWhiteboard.h"
#import "WandOptions.h"
#import "SeaSelection.h"
#import <SeaLibrary/Bitmap.h>

@implementation WandTool

- (void)awakeFromNib {
    options = [[WandOptions alloc] init:document];
}

- (int)toolId
{
	return kWandTool;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	[super downHandler:where withEvent:event];
	
	if(![super isMovingOrScaling]){
		currentPoint = startPoint = where;
	}
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	[super dragHandler:where withEvent:event];
	
	if(![super isMovingOrScaling]){
        IntRect dirty = IntMakeRect(startPoint.x,startPoint.y,currentPoint.x-startPoint.x,currentPoint.y-startPoint.y);

        currentPoint = where;

        IntRect rect = IntMakeRect(startPoint.x,startPoint.y,currentPoint.x-startPoint.x,currentPoint.y-startPoint.y);

        [[document docView] setNeedsDisplayInLayerRect:IntSumRects(dirty,rect):8];
	}
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    int old = intermediate;
    bool wasMovingOrScaling = [super isMovingOrScaling];

	[super upHandler:where withEvent:event];

    SeaLayer *layer = [[document contents] activeLayer];
    
    int width = [layer width], height = [layer height];
    unsigned char *overlay = [[document whiteboard] overlay], *data = [layer data];
    unsigned char basePixel[4];
    
    IntRect rect;
    
    if(!old || wasMovingOrScaling)
        goto done;
    
    if (!IntPointInRect(where,IntMakeRect(0,0,width,height)))
        goto done;

    // Clear last selection
    if([options selectionMode] == kDefaultMode || [options selectionMode] == kForceNewMode)
        [[document selection] clearSelection];
    
    // Fill the region to be selected
    memset(basePixel,0,SPP);
    basePixel[alphaPos] = 255;
    
    int tolerance = [options tolerance];
    int mode = [options selectionMode];
    bool selectAllRegions = [options selectAllRegions];
    int channel = [[document contents] selectedChannel];
    
    int seedIndex;
    int xDelta = where.x - startPoint.x;
    int yDelta = where.y - startPoint.y;
    
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

    fillContext ctx;
    ctx.overlay = overlay;
    ctx.data = data;
    ctx.width = width;
    ctx.height = height;
    ctx.seeds = seeds;
    ctx.numSeeds = intervals;
    ctx.tolerance = tolerance;
    ctx.channel = channel;

    if(selectAllRegions) {
        memset(overlay,0,width*height*SPP);
        rect = IntMakeRect(0,0,width,height);
        for(int row=0;row<height;row++){
            for(int col=0;col<width;col++){
                IntPoint p = IntMakePoint(col,row);
                if(shouldFill(&ctx,p)) {
                    memcpy(&(overlay[(row * width + col) * SPP]), basePixel, SPP);
                }
            }
        }
    } else {
        rect = bucketFill(&ctx, IntMakeRect(0, 0, width, height), basePixel);
    }
    
    free(seeds);

    // Then select it
    [[document selection] selectOverlay:rect mode: mode];

    // Also, we universally float the selection if alt is down
    if([[self getOptions] modifier] == kAltModifier) {
        [[document contents] layerFromSelection:NO];
    }

done:
    return;
}

- (IntPoint)start
{
	return startPoint;
}

-(IntPoint)current
{
	return currentPoint;
}

- (AbstractOptions*)getOptions
{
    return options;
}

@end

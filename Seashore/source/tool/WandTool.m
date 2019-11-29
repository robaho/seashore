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

    SeaLayer *layer = [[document contents] activeLayer];
    
    int width = [layer width], height = [layer height], spp = [[document contents] spp];
    unsigned char *overlay = [[document whiteboard] overlay], *data = [layer data];
    unsigned char basePixel[4];
    
    IntRect rect;
    
    if(!intermediate)
        goto done;
    
    if (!IntPointInRect(where,IntMakeRect(0,0,width,height)))
        goto done;

    // Clear last selection
    if([options selectionMode] == kDefaultMode || [options selectionMode] == kForceNewMode)
        [[document selection] clearSelection];
    
    // Fill the region to be selected
    for (int k = 0; k < spp - 1; k++)
        basePixel[k] = 0;
    basePixel[spp - 1] = 255;
    
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
        seeds[inrect] = IntMakePoint(x, y);
        inrect++;
    }
    intervals=inrect;

    if(selectAllRegions) {
        memset(overlay,width*height*spp,0);
        rect = IntMakeRect(0,0,width,height);
        for(int row=0;row<height;row++){
            for(int col=0;col<width;col++){
                IntPoint p = IntMakePoint(col,row);
                if(shouldFill(overlay,data,seeds,intervals,p,width,spp,tolerance,channel)) {
                    memcpy(&(overlay[(row * width + col) * spp]), basePixel, spp);
                }
            }
        }
    } else {
        rect = bucketFill(spp, IntMakeRect(0, 0, width, height), overlay, data, width, height, seeds, intervals, basePixel, tolerance, channel);
    }
    
    free(seeds);

    // Then select it
    [[document selection] selectOverlay:YES inRect:rect mode: mode];

done:
    intermediate = NO;
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

- (AbstractOptions*)getOptions
{
    return options;
}
- (void)setOptions:(AbstractOptions*)newoptions
{
    options = (WandOptions*)newoptions;
}


@end

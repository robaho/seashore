#import "WandTool.h"
#import "SeaTools.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "Bucket.h"
#import "SeaWhiteboard.h"
#import "WandOptions.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import "SeaPrefs.h"
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

int signum(int n) { return (n < 0) ? -1 : (n > 0) ? +1 : 0; }

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	[super dragHandler:where withEvent:event];
	
	if(![super isMovingOrScaling]){
        if([options dragAdjustsTolerance]) {
            currentPoint = where;
            int range = currentPoint.x >= startPoint.x ? [[document contents] width]-startPoint.x : startPoint.x;

            double adj = ((currentPoint.x-startPoint.x)/(double)range)*255;
            double tolerance = MIN(MAX([options tolerance] + adj,0),255);
            [self preview:tolerance];
        } else {
            IntRect dirty = IntMakeRect(startPoint.x,startPoint.y,currentPoint.x-startPoint.x,currentPoint.y-startPoint.y);

            currentPoint = where;

            IntRect rect = IntMakeRect(startPoint.x,startPoint.y,currentPoint.x-startPoint.x,currentPoint.y-startPoint.y);

            [[document docView] setNeedsDisplayInLayerRect:IntSumRects(dirty,rect):8];
        }
	}
}

-(IntRect)fillOverlay:(IntPoint*)seeds nSeeds:(int)nseeds color:(unsigned char*)color tolerance:(int)tolerance
{
    SeaLayer *layer = [[document contents] activeLayer];
    int width = [layer width], height = [layer height];
    unsigned char *overlay = [[document whiteboard] overlay], *data = [layer data];

    bool selectAllRegions = [options selectAllRegions];
    int channel = [[document contents] selectedChannel];

    fillContext ctx;
    ctx.overlay = overlay;
    ctx.data = data;
    ctx.width = width;
    ctx.height = height;
    ctx.seeds = seeds;
    ctx.numSeeds = nseeds;
    ctx.tolerance = tolerance;
    ctx.channel = channel;

    memcpy(ctx.fillColor,color,4);

    IntRect rect;

    if(selectAllRegions) {
        memset(overlay,0,width*height*SPP);
        rect = IntMakeRect(0,0,width,height);
        for(int row=0;row<height;row++){
            for(int col=0;col<width;col++){
                if(shouldFill(&ctx,col,row)) {
                    memcpy(&(overlay[(row * width + col) * SPP]), color, SPP);
                }
            }
        }
    } else {
        rect = bucketFill(&ctx, IntMakeRect(0, 0, width, height));
    }
    return rect;
}

-(void)preview:(double)tolerance
{
    [[document whiteboard] clearOverlay];
    [[document whiteboard] setOverlayOpacity:200];

    IntPoint seeds[] = { startPoint };

    NSColor *selcolor = [[SeaController seaPrefs] selectionColor:.75];

    unsigned char color[4];
    color[CR]= [selcolor redComponent]*255;
    color[CG]= [selcolor greenComponent]*255;
    color[CB]= [selcolor blueComponent]*255;
    color[alphaPos] = 255;

    previewRect = [self fillOverlay:seeds nSeeds:1 color:color tolerance:tolerance];

    [[document helpers] overlayChanged:previewRect];
}

-(IntRect)bucketFill
{
    SeaLayer *layer = [[document contents] activeLayer];
    int width = [layer width], height = [layer height];
    unsigned char *data = [layer data];

    int seedIndex;

    int xDelta = currentPoint.x - startPoint.x;
    int yDelta = currentPoint.y - startPoint.y;

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

    int tolerance = [options tolerance];

    unsigned char color[4];
    memset(color,0,SPP);
    color[alphaPos] = 255;

    IntRect rect = [self fillOverlay:seeds nSeeds:inrect color:color tolerance:tolerance];

    [[document helpers] overlayChanged:rect];

    return rect;
}


- (bool)isPreviewing
{
    return [options dragAdjustsTolerance];
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    int old = intermediate;
    bool wasMovingOrScaling = [super isMovingOrScaling];

	[super upHandler:where withEvent:event];

    if(!old || wasMovingOrScaling)
        goto done;
    
    if([options selectionMode] == kDefaultMode || [options selectionMode] == kForceNewMode)
        [[document selection] clearSelection];

    int mode = [options selectionMode];

    IntRect rect;

    if([options dragAdjustsTolerance]) {
        rect = previewRect;
    } else {
        rect = [self bucketFill];
    }

    [[document selection] selectOverlay:rect mode:mode];

    if([[self getOptions] modifier] == kAltModifier) {
        [[document contents] layerFromSelection:NO];
    }

done:
    [[document whiteboard] clearOverlay];

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

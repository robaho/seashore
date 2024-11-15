//
//  AbstractTool+FillExtensions.m
//  Seashore
//
//  Created by robert engels on 5/25/23.
//

#import "AbstractTool+FillExtensions.h"
#import "SeaDocument.h"
#import "SeaLayer.h"

@implementation AbstractTool (FillExtensions)

- (void)calculateSeeds:(fillContext*)ctx at:(IntPoint)at
{
    double zoom = [[document docView] zoom];
    if(zoom>=1) {
        ctx->seeds[0] = at;
        ctx->numSeeds = 1;
        return;
    }

    // gather seeds around the point - at most 8x8
    int size = 1 / zoom;
    size = MIN(size,8);

    ctx->seeds[0]=at;
    int nseeds=1;

    SeaLayer *layer = [[document contents] activeLayer];
    int width = [layer width], height = [layer height];
    unsigned char* data = [layer data];

    for(int row = 0;row<size;row++) {
        int y = at.y+row-size/2;
        if(y<0 || y>=height)
            continue;
        for(int col=0;col<size;col++) {
            int x = at.x + col-size/2;
            if(x<0 || x>=width)
                continue;
            for(int i=0;i<nseeds;i++) {
                if(isSameColor(data,width,ctx->seeds[i].x,ctx->seeds[i].y,x,y)) {
                    goto same;
                }
            }
            ctx->seeds[nseeds]=IntMakePoint(x,y);
            nseeds++;
            if(nseeds==64) {
                goto done;
            }
        same:
            continue;
        }
    }
done:
    ctx->numSeeds = nseeds;
}

-(IntRect)fillOverlay:(IntPoint)start color:(unsigned char*)color tolerance:(int)tolerance allRegions:(bool)allRegions op:(NSOperation*)op
{
    SeaLayer *layer = [[document contents] activeLayer];
    int width = [layer width], height = [layer height];
    unsigned char *overlay = [[document whiteboard] overlay], *data = [layer data];

    int channel = [[document contents] selectedChannel];

    fillContext ctx;
    ctx.overlay = overlay;
    ctx.data = data;
    ctx.width = width;
    ctx.height = height;
    ctx.tolerance = tolerance;
    ctx.channel = channel;

    [self calculateSeeds:&ctx at:start];

    memcpy(ctx.fillColor,color,4);

    IntRect rect;

    if(allRegions) {
        rect = bucketFillAll(&ctx,IntMakeRect(0,0,width,height),op);
    } else {
        rect = bucketFill(&ctx, IntMakeRect(0, 0, width, height),op);
    }

    return rect;
}

@end

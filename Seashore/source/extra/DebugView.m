//
//  DebugView.m
//  Seashore
//
//  Allows for visualizing intermediate structures easily.
//

#import "DebugView.h"
#import "Seashore.h"

@implementation DebugView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    [_rep drawAtPoint:NSMakePoint(0,0)];
}

-(void)update
{
    [_rep bitmapData];
    [self setNeedsDisplay:TRUE];
}

- (BOOL)isFlipped
{
    return FALSE;
}

+ (DebugView *)createWithRep:(NSBitmapImageRep *)rep
{
    DebugView *dv = [[DebugView alloc] init];
    dv.rep = rep;

    [dv setFrame:NSMakeRect(0,0,[rep pixelsWide],[rep pixelsHigh])];

    NSWindow *win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,320,200) styleMask:NSWindowStyleMaskResizable|NSWindowStyleMaskTitled backing:0 defer:FALSE];

    NSScrollView *sv = [[NSScrollView alloc] init];
    [sv setScrollerStyle:NSScrollerStyleLegacy];
    [sv setDocumentView:dv];

    [sv setHasHorizontalScroller:TRUE];
    [sv setHasVerticalScroller:TRUE];
    [sv setAutohidesScrollers:TRUE];

    [win setContentView:sv];
    [win setContentSize:NSMakeSize(320,200)];
    [win setTitle:@"DebugWindow"];
    [win orderFront:NULL];

    return dv;
}

+ (DebugView *)createWithData:(unsigned char *)data width:(int)width height:(int)height spp:(int)spp snapshot:(BOOL)snapshot
{
    if(snapshot){
        unsigned char *tmp = malloc(width*height*spp);
        memcpy(tmp,data,width*height*spp);
        data = tmp;
    }
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:TRUE isPlanar:FALSE colorSpaceName:(spp == 4) ? MyRGBSpace : MyGraySpace bytesPerRow:width*spp bitsPerPixel:spp*8];

    return [DebugView createWithRep:rep];
}


@end

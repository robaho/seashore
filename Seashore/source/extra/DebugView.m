//
//  DebugView.m
//  Seashore
//
//  Allows for visualizing intermediate structures easily.
//

#import "DebugView.h"
#import "Seashore.h"

@implementation DebugView

- (BOOL)isFlipped
{
    return FALSE;
}

+ (DebugView *)createWithRep:(NSBitmapImageRep *)rep
{
    DebugView *dv = [[DebugView alloc] init];
    dv.rep = rep;
    dv.imageScaling = NSImageScaleProportionallyDown;

    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(400,400)];
    [image addRepresentation:rep];

    dv.image = image;

    NSWindow *win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,400,400) styleMask:NSWindowStyleMaskResizable|NSWindowStyleMaskTitled|NSWindowStyleMaskClosable backing:0 defer:FALSE];

    [win setContentView:dv];
    [win setContentSize:NSMakeSize(400,400)];
    [win setTitle:@"DebugWindow"];
    [win orderFront:NULL];
    [win setReleasedWhenClosed:FALSE];

    return dv;
}

+ (DebugView *)createWithData:(unsigned char *)data width:(int)width height:(int)height snapshot:(BOOL)snapshot
{
    if(snapshot){
        unsigned char *tmp = malloc(width*height*SPP);
        memcpy(tmp,data,width*height*SPP);
        data = tmp;
    }
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:SPP hasAlpha:TRUE isPlanar:FALSE colorSpaceName:MyRGBSpace bitmapFormat:NSBitmapFormatAlphaFirst bytesPerRow:width*SPP bitsPerPixel:SPP*8];

    return [DebugView createWithRep:rep];
}

+ (DebugView *)createWithContext:(CGContextRef)ctx
{
    CGImageRef img = CGBitmapContextCreateImage(ctx);

    NSBitmapImageRep * rep = [[NSBitmapImageRep alloc] initWithCGImage:img];

    CGImageRelease(img);

    return [DebugView createWithRep:rep];
}


@end

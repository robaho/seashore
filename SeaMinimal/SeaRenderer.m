#import "SeaRenderer.h"
#import "SeaLibrary/SeaLibrary.h"

@implementation SeaRenderer

- (CGImageRef) render:(SeaContent*)content
{
    int width = [content width];
    int height = [content height];

    CGContextRef ctx = CGBitmapContextCreate(NULL,width,height,8,0,COLOR_SPACE,kCGImageAlphaPremultipliedFirst);

    CGContextTranslateCTM(ctx,0,height);
    CGContextScaleCTM(ctx,1,-1);

    for(int i=[content layerCount]-1;i>=0;i--) {
        SeaLayer *layer = [content layer:i];
        [layer drawLayer:ctx];
    }

    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);

    return cgimg;
}

@end

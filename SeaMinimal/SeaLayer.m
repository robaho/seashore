#import "SeaLayer.h"
#import <SeaLibrary/Constants.h>

@implementation SeaLayer

- (int)mode
{
    return mode;
}
- (SeaLayer*)initWithDocument:(SeaDocument*)doc
{
    return self;
}
- (NSString*)name
{
    return name;
}
- (bool)hasAlpha
{
    return hasAlpha;
}
- (void)drawLayer:(CGContextRef)context
{
    CGContextRef bm = CGBitmapContextCreate([nsdata bytes],width,height,8,width*spp,COLOR_SPACE,kCGImageAlphaPremultipliedLast);
    CGImageRef image = CGBitmapContextCreateImage(bm);

    CGContextSaveGState(context);
    CGContextSetBlendMode(context, mode);
    CGContextTranslateCTM(context,xoff,yoff+height);
    CGContextScaleCTM(context,1,-1);
    CGContextSetAlpha(context,opacity/255.0);
    CGContextDrawImage(context,CGRectMake(0,0,width,height),image);
    CGImageRelease(image);
    CGContextRelease(bm);
    CGContextRestoreGState(context);
}

@end

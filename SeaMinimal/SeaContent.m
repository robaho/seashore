#import "SeaContent.h"

@implementation SeaContent

- (int) width {
    return width;
}
- (int) height
{
    return height;
}
- (int) xres
{
    return xres;
}
- (int) yres
{
    return yres;
}
- (int) type
{
    return type;
}
- (bool) hasAlpha
{
    return hasAlpha;
}
- (int) layerCount
{
    return (int)[layers count];
}

- (SeaContent*)initWithDocument:(SeaDocument*)document
{
    return self;
}

- (SeaLayer*)layer:(int)index
{
    return [layers objectAtIndex:index];
}

- (NSDictionary *)exifData
{
    return exifData;
}

@end

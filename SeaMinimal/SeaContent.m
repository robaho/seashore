#import "SeaLibrary/SeaLibrary.h"
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
- (int)spp
{
    int result = 0;

    switch (type) {
        case XCF_RGB_IMAGE:
            result = 4;
            break;
        case XCF_GRAY_IMAGE:
            result = 2;
            break;
        default:
            NSLog(@"Document type not recognised by spp");
            break;
    }

    return result;
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

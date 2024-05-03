#import "WEBPImporter.h"
#import "CocoaLayer.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaView.h"
#import "SeaOperations.h"
#import "SeaAlignment.h"
#import "SeaController.h"

#import "decode.h"

//extern int WebPGetInfo(const uint8_t* data,size_t length,int *width, int *height);

@implementation WEBPImporter

- (BOOL)addToDocument:(id)doc contentsOfFile:(NSString *)path
{
    SeaLayer* layer = [self loadLayer:doc path:path];
    if(layer==NULL) return NO;

    // Rename the layer
    [layer setName:[[NSString alloc] initWithString:[[path lastPathComponent] stringByDeletingPathExtension]]];

    // Add the layer
    [[doc contents] addLayerObject:layer];

    // Position the new layer correctly
    [[(SeaOperations *)[doc operations] seaAlignment] centerLayerHorizontally:NULL];
    [[(SeaOperations *)[doc operations] seaAlignment] centerLayerVertically:NULL];

    return YES;
}

-(SeaLayer*)loadLayer:(id)doc path:(NSString *)path
{
    NSData *fileData = [NSData dataWithContentsOfFile:path];

    int width, height;

    int result = WebPGetInfo([fileData bytes],[fileData length], &width, &height);
    if(result==0) return NULL;

    int size = width*height*4;

    unsigned char *argb = malloc(size);

    unsigned char *image = WebPDecodeARGBInto([fileData bytes], [fileData length], argb, size, 4 * width);
    if(image==NULL) {
        free(argb);
        return NULL;
    }

    return [[SeaLayer alloc] initWithDocument:doc rect:IntMakeRect(0,0,width,height) data:argb];
}

+(NSImage *)loadImage:(NSData *)data
{
    int width, height;

    int result = WebPGetInfo([data bytes],[data length], &width, &height);
    if(result==0) return NULL;

    int size = width*height*4;

    unsigned char *argb = malloc(size);

    unsigned char *image = WebPDecodeARGBInto([data bytes], [data length], argb, size, 4 * width);
    if(image==NULL) {
        free(argb);
        return NULL;
    }

    premultiplyBitmap(4,argb,argb,width*height);

    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height
                                                                                    bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
                                                                                   colorSpaceName:MyRGBSpace
                                                                                     bitmapFormat:NSBitmapFormatAlphaFirst
                                                                                      bytesPerRow:width*4
                                                                                     bitsPerPixel:8*4];

    memcpy([rep bitmapData],argb,size);

    free(argb);

    [rep setSize:NSMakeSize(width,height)];

    NSImage* nsImage = [[NSImage alloc] init];
    [nsImage addRepresentation:rep];

    return nsImage;
}


@end

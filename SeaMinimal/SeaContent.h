#import <Foundation/Foundation.h>

#define OTHER_PLUGIN 1

#import "ParasiteData.h"
#import "SeaDocument.h"
#import "SeaLayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface SeaContent : NSObject
{
    int width,height,type;
    int xres,yres;
    bool hasAlpha;

    int activeLayerIndex;

    ParasiteData *parasites;

    char *lostprops;
    int lostprops_len;

    NSArray *layers;

    // The EXIF data associated with this image
    NSDictionary *exifData;
}

- (SeaContent*)initWithDocument:(SeaDocument*)document;
- (int) width;
- (int) height;
- (int) xres;
- (int) yres;
- (int) type;
- (bool) hasAlpha;
- (int) layerCount;
- (SeaLayer*)layer:(int)index;
- (NSDictionary *)exifData;
@end

NS_ASSUME_NONNULL_END

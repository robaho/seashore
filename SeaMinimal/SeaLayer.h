#import <Foundation/Foundation.h>
#include "SeaDocument.h"

NS_ASSUME_NONNULL_BEGIN

@interface SeaLayer : NSObject
{
    int mode;
    int width,height;
    int spp;

    NSString *name;
    int opacity;
    int xoff,yoff;
    bool linked;
    bool visible;
    bool hasAlpha;

    NSData *nsdata;

    char *lostprops;
    int lostprops_len;
}

- (int)mode;
- (SeaLayer*)initWithDocument:(SeaDocument*)doc;
- (NSString*)name;
- (bool)hasAlpha;
- (void)drawLayer:(CGContextRef)context;

@end

NS_ASSUME_NONNULL_END

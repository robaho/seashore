#import "SeaDocument.h"
#import "SeaContent.h"
#import "SVGLayer.h"
#import "SVGContent.h"
#import "Bitmap.h"

@implementation SVGLayer

- (id)initWithImageRep:(id)imageRep document:(id)doc spp:(int)lspp
{
    int i;
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return NULL;
	
	// Determine the width and height of this layer
	width = (int)[(NSImageRep*)imageRep pixelsWide];
	height = (int)[(NSImageRep*)imageRep pixelsHigh];
	
	// Determine samples per pixel
	spp = lspp;

    data = convertImageRep(imageRep,spp);
	if (!data) {
		NSLog(@"Required conversion not supported.");
		[self autorelease];
		return NULL;
	}
    
    hasAlpha = NO;
    for (i = 0; i < width * height; i++) {
        if (data[(i + 1) * spp - 1] != 255)
            hasAlpha = YES;
    }
	
	return self;
}

@end

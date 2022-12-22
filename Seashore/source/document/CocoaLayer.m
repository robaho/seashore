#import "SeaDocument.h"
#import "SeaContent.h"
#import "CocoaLayer.h"
#import "CocoaContent.h"

@implementation CocoaLayer

- (id)initWithImageRep:(id)imageRep document:(id)doc
{
    int i;
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return NULL;
    
    // Determine the width and height of this layer
    
    long lwidth = [(NSImageRep*)imageRep pixelsWide];
    long lheight = [(NSImageRep*)imageRep pixelsHigh];
    
    if(lwidth<kMinImageSize || lwidth > kMaxImageSize ||
       lheight < kMinImageSize || lheight > kMaxImageSize) {
        return NULL;
    }
	
    width = (int)lwidth;
    height = (int)lheight;
    
    unsigned char *data = convertRepToARGB(imageRep);
    if(!data){
        return NULL;
    }
    
    hasAlpha = NO;
    for (i = 0; i < width * height; i++) {
        if (data[i*SPP+alphaPos] != 255)
            hasAlpha = YES;
    }

    nsdata = [NSData dataWithBytesNoCopy:data length:width*height*SPP];
    
	return self;
}

@end

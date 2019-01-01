#import "SeaWhiteboard.h"
#import "StandardMerge.h"
#import "SeaLayer.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "Bitmap.h"

@implementation SeaWhiteboard

- (id)initWithContent:(SeaContent *)cont
{
	gScreenResolution = IntMakePoint(1024, 768);
	// Remember the document we are representing
	contents = cont;
	
	// Initialize the compostior
	compositor = NULL;

	if (compositor == NULL)	compositor = [SeaCompositor alloc];
	[compositor initWithContents:contents andWhiteboard:self];
	
	// Record the width, height and use of greys
	width = [contents width];
	height = [contents height];
	
	// Record the samples per pixel used by the whiteboard
	spp = [contents spp];
	
	// Allocate the whiteboard data
	data = malloc(make_128(width * height * spp));
    
    // these should not be used in quicklook
    overlay = replace = NULL;
	
	return self;
}

- (SeaCompositor *)compositor{
	return compositor;
}

- (void)dealloc
{	
	// Free the room we took for everything else
	if (data) free(data);
}

- (void)forcedUpdate
{
	int i, count = 0, layerCount = [contents layerCount];
	IntRect majorUpdateRect;
	CompositorOptions options;

    majorUpdateRect = IntMakeRect(0, 0, width, height);
	
	// Handle non-channel updates here
	if (majorUpdateRect.size.width > 0 && majorUpdateRect.size.height > 0) {
		
		// Clear the whiteboard
		for (i = 0; i < majorUpdateRect.size.height; i++)
			memset(data + ((majorUpdateRect.origin.y + i) * width + majorUpdateRect.origin.x) * spp, 0, majorUpdateRect.size.width * spp);
			
		// Determine how many layers are visible
		for (i = 0; count < 2 && i < layerCount; i++) {
			if ([[contents layer:i] visible])
				count++;
		}
		
		// Set the composting options
		options.spp = spp;
		options.forceNormal = (count == 1);
		options.rect = majorUpdateRect;
		options.destRect = IntMakeRect(0, 0, width, height);
		options.overlayOpacity = 0; // not used in quicklook
        options.overlayBehaviour = kNormalBehaviour; // not used in quicklook
		options.useSelection = NO;

		// Go through compositing each visible layer
		for (i = layerCount - 1; i >= 0; i--) {
			if ([[contents layer:i] visible]) {
				options.insertOverlay = (i == [contents activeLayerIndex]);
				options.useSelection = NO;
				[compositor compositeLayer:[contents layer:i] withOptions:options];
			}
		}
	}
}

- (void)update
{
	[self forcedUpdate];
}


- (IntRect)imageRect
{
	id layer;
	
    return IntMakeRect(0, 0, width, height);
}


- (NSImage *)printableImage
{
	NSBitmapImageRep *imageRep;

	NSImage *image = [[NSImage alloc] init];
	imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * spp bitsPerPixel:8 * spp];
	[image addRepresentation:imageRep];
	
	return image;
}

- (unsigned char *)data
{
	return data;
}

- (unsigned char *)overlay
{
    return overlay;
}

- (unsigned char *)replace
{
    return replace;
}



@end

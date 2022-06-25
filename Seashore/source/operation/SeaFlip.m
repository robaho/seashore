#import "SeaFlip.h"
#import "SeaHelpers.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaWhiteboard.h"
#import "SeaSelection.h"
#import "SeaLayer.h"
#import "SeaSelection.h"

@implementation SeaFlip


- (void)standardFlip:(int)type
{
    SeaSelection *selection = [document selection];
    if (![selection active])
        return;

	unsigned char *overlay, *data, *replace, *edata = NULL;
	int i, j, k, width, height, spp;
	int src, dest;
	IntRect rect;
	BOOL complex;

    SeaLayer *layer = [[document contents] activeLayer];

	overlay = [[document whiteboard] overlay];
	data = [layer data];
	replace = [[document whiteboard] replace];
	width = [layer width];
	height = [layer height];
	spp = [[document contents] spp];
    
	rect = [selection localRect];

	complex = [selection mask]!=NULL;
	
	// Erase selection if it is complex
	if (complex) {
		edata = malloc(rect.size.width * rect.size.height * spp);
		for (i = 0; i < rect.size.width; i++) {
			for (j = 0; j < rect.size.height; j++) {
				memcpy(&(edata[(j * rect.size.width + i) * spp]), &(data[((j + rect.origin.y) * width +  (i + rect.origin.x)) * spp]), spp);
			}
		}
		[selection deleteSelection];
	}
	
	// Do the correct flip
	if (type == kHorizontalFlip) {
		for (i = 0; i < rect.size.width; i++) {
			for (j = 0; j < rect.size.height; j++) {
				replace[(j + rect.origin.y) * width + (i + rect.origin.x)] = 255;
				if (complex)
					src = (j * rect.size.width + (rect.size.width - i - 1)) * spp;
				else
					src = ((j + rect.origin.y) * width + ((rect.size.width - i - 1) + rect.origin.x)) * spp;
				dest =((j + rect.origin.y) * width + (i + rect.origin.x)) * spp;
				for (k = 0; k < spp; k++) {
					if (complex)
						overlay[dest + k] = edata[src + k];
					else
						overlay[dest + k] = data[src + k];
				}
			}
		}
	}
	else {
		for (i = 0; i < rect.size.width; i++) {
			for (j = 0; j < rect.size.height; j++) {
				replace[(j + rect.origin.y) * width + (i + rect.origin.x)] = 255;
				if (complex)
					src = ((rect.size.height - j - 1) * rect.size.width + i) * spp;
				else
					src = (((rect.size.height - j - 1) + rect.origin.y) * width + (i + rect.origin.x)) * spp;
				dest =((j + rect.origin.y) * width + (i + rect.origin.x)) * spp;
				for (k = 0; k < spp; k++) {
					if (complex)
						overlay[dest + k] = edata[src + k];
					else
						overlay[dest + k] = data[src + k];
				}
			}
		}
	}
	
	// Free used memory
	if (complex) free(edata);
	
	// Flip the selection mask
	[selection flipSelection:type];
	
	[[document whiteboard] setOverlayOpacity:255];
	[[document whiteboard] setOverlayBehaviour:kReplacingBehaviour];
    [[document whiteboard] overlayModified:rect];
	[[document helpers] applyOverlay];
}

- (void)flipSelectionHorizontally
{
    [[document helpers] endLineDrawing];
    [self standardFlip:kHorizontalFlip];
}

- (void)flipSelectionVertically
{
    [[document helpers] endLineDrawing];
    [self standardFlip:kVerticalFlip];
}


- (void)flipLayerHorizontally
{
    [[document helpers] endLineDrawing];

    [[[document undoManager] prepareWithInvocationTarget:self] flipLayerHorizontally];

    SeaLayer *layer = [[document contents] activeLayer];
    [layer flipHorizontally];

    [[document helpers] boundariesAndContentChanged];
}

- (void)flipLayerVertically
{
    [[document helpers] endLineDrawing];

    [[[document undoManager] prepareWithInvocationTarget:self] flipLayerVertically];

    SeaLayer *layer = [[document contents] activeLayer];
    [layer flipVertically];

    [[document helpers] boundariesAndContentChanged];
}


@end

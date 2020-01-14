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
	unsigned char *overlay, *data, *replace, *edata = NULL;
	int i, j, k, width, height, spp;
	int src, dest;
	IntRect rect;
	BOOL complex;
	
	// Fill out variables
	overlay = [[document whiteboard] overlay];
	data = [(SeaLayer *)[[document contents] activeLayer] data];
	replace = [[document whiteboard] replace];
	width = [(SeaLayer *)[[document contents] activeLayer] width];
	height = [(SeaLayer *)[[document contents] activeLayer] height];
	spp = [[document contents] spp];
    
    SeaSelection *selection = [document selection];
	if ([selection active])
		rect = [selection localRect];
	else
		rect = IntMakeRect(0, 0, width, height);
	complex = [selection active] && [selection mask];
	
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
	
	// Flip the selection
	[selection flipSelection:type];
	
	// Apply the changes
	[[document whiteboard] setOverlayOpacity:255];
	[[document whiteboard] setOverlayBehaviour:kReplacingBehaviour];
	[(SeaHelpers *)[document helpers] applyOverlay];	
}

- (void)run:(int)type
{
    [self standardFlip:type];
}

@end

#import "SeaCompositor.h"
#import "SeaWhiteboard.h"
#import "SeaLayer.h"
#import "SeaContent.h"

@implementation SeaCompositor

- (id)initWithContents:(SeaContent *)cont andWhiteboard:(SeaWhiteboard *)board
{
	int i;
	
	// Remember the document we are compositing for
	contents = cont;
	whiteboard = board;
	
	// Work out the random table for the dissolve effect
	srandom(RANDOM_SEED);
	for (i = 0; i < 4096; i++)
		randomTable[i] = random();
	
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)compositeLayer:(id)layer withOptions:(CompositorOptions)options
{
	[self compositeLayer: layer withOptions: options andData: NULL];
}

- (void)compositeLayer:(id)layer withOptions:(CompositorOptions)options andData:(unsigned char *)destPtr
{
	unsigned char *srcPtr, *overlay, *replace;
	int lwidth = [(SeaLayer *)layer width], lheight = [(SeaLayer *)layer height], mode = [(SeaLayer *)layer mode];
	int opacity = [layer opacity], selectedChannel = [contents selectedChannel];
	int xoff = [layer xoff], yoff = [layer yoff], selectOpacity;
	int startX, startY, endX, endY;
	int i, j, k, srcLoc, destLoc;
	unsigned char tempSpace[4], tempSpace2[4];
	BOOL insertOverlay, overlayOkay;
	BOOL floating;
	
	// If the layer has an opacity of zero it does not need to be composited
	if (opacity == 0)
		return;
	
	// If the overlay has an opacity of zero it does not need to be inserted
	if (options.overlayOpacity == 0)
		insertOverlay = NO;
	else
		insertOverlay = options.insertOverlay;
	
	// Determine what is being copied
	startX = MAX(options.rect.origin.x - xoff, (xoff < 0) ? -xoff : 0);
	startY = MAX(options.rect.origin.y - yoff, (yoff < 0) ? -yoff : 0);
	endX = MIN([contents width] - xoff, lwidth);
	endX = MIN(endX, options.rect.origin.x + options.rect.size.width - xoff);
	endY = MIN([contents height] - yoff, lheight);
	endY = MIN(endY, options.rect.origin.y + options.rect.size.height - yoff);
	
	// Get some stuff we're going to use later
	//selectRect = [(SeaSelection *)[document selection] localRect];
	srcPtr = [(SeaLayer *)layer data];
	if(!destPtr) destPtr = [whiteboard data];
	overlay = [whiteboard overlay];
	replace = [whiteboard replace];
	//mask = [[document selection] mask];
	//maskOffset = [[document selection] maskOffset];
	//trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
	//maskSize = [[document selection] maskSize];
	floating = [layer floating];
	
	// Check what we are doing has a point
	if (endX - startX <= 0) return;
	if (endY - startY <= 0) return;
	
	// Go through each row
	for (j = startY; j < endY; j++) {
	
		// Disolving requires us to play with the random number generator
		if (mode == XCF_DISSOLVE_MODE) {
			srandom(randomTable[(j + yoff) % 4096]);
			for (k = 0; k < xoff; k++)
				random();
		}
		
		// Go through each column
		for (i = startX; i < endX; i++) {
		
			// Determine the location in memory of the pixel we are copying from and to
			srcLoc = (j * lwidth + i) * options.spp;
			destLoc = ((j + yoff - options.destRect.origin.y) * options.destRect.size.width + (i + xoff - options.destRect.origin.x)) * options.spp;
			
			// Prepare for overlay application
			for (k = 0; k < options.spp; k++)
				tempSpace2[k] = srcPtr[srcLoc + k];
			if (insertOverlay) {
				
				// Check if we should apply the overlay for this pixel
				overlayOkay = NO;
				switch (options.overlayBehaviour) {
					case kReplacingBehaviour:
					case kMaskingBehaviour:
						selectOpacity = replace[j * lwidth + i];
					break;
					default:
						selectOpacity = options.overlayOpacity;
					break;
				}
				overlayOkay = YES;
				
				// Don't do anything if there's no point
				if (selectOpacity == 0)
					overlayOkay = NO;
				
				// Apply the overlay if we get the okay
				if (overlayOkay) {
					if (selectedChannel == kAllChannels && !floating) {
						switch (options.overlayBehaviour) {
							case kErasingBehaviour:
								eraseMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
							break;
							case kReplacingBehaviour:
								replaceMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
							break;
							default:
								specialMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
							break;
						}
					}
					else if (selectedChannel == kPrimaryChannels || floating) {
						if (selectOpacity > 0) {
							switch (options.overlayBehaviour) {							
								case kReplacingBehaviour:
									replacePrimaryMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
								break;
								default:
									primaryMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity, YES);
								break;
							}
						}
					}
					else if (selectedChannel == kAlphaChannel) {
						if (selectOpacity > 0) {
							switch (options.overlayBehaviour) {							
								case kReplacingBehaviour:
									replaceAlphaMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
								break;
								default:
									alphaMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
								break;
							}
						}
					}
				}
				
			}
			
			// If the layer is going to use a compositing effect...
			if (normal == NO && mode != XCF_NORMAL_MODE && options.forceNormal == NO) {

				// Copy pixel from destination in to temporary memory
				for (k = 0; k < options.spp; k++)
					tempSpace[k] = destPtr[destLoc + k];
				
				// Apply the appropriate effect using the source pixel
				selectMerge(mode, options.spp, tempSpace, 0, tempSpace2, 0);
				
				// Then merge the pixel in temporary memory with the destination pixel
				normalMerge(options.spp, destPtr, destLoc, tempSpace, 0, opacity);
			
			}
			else {
				
				// Then merge the pixel in temporary memory with the destination pixel
				normalMerge(options.spp, destPtr, destLoc, tempSpace2, 0, opacity);
			
			}
			
		}
	}
}

- (void)compositeLayer:(id)layer withFloat:(id)floatingLayer andOptions:(CompositorOptions)options
{
	unsigned char *srcPtr, *floatPtr, *destPtr, *overlay, *replace;
	int lwidth = [(SeaLayer *)layer width], lheight = [(SeaLayer *)layer height], mode = [(SeaLayer *)layer mode];
	int lfwidth = [(SeaLayer *)floatingLayer width], lfheight = [(SeaLayer *)floatingLayer height];
	int opacity = [layer opacity], selectedChannel = [contents selectedChannel];
	int xoff = [layer xoff], yoff = [layer yoff], selectOpacity;
	int xfoff = [floatingLayer xoff], yfoff = [floatingLayer yoff];
	int startX, startY, endX, endY;
	int i, j, k, srcLoc, destLoc, floatLoc, tx, ty;
	unsigned char tempSpace[4], tempSpace2[4], tempSpace3[4];
	BOOL insertOverlay;
	BOOL floating;
	
	// If the layer has an opacity of zero it does not need to be composited
	if (opacity == 0)
		return;
	
	// If the overlay has an opacity of zero it does not need to be inserted
	if (options.overlayOpacity == 0)
		insertOverlay = NO;
	else
		insertOverlay = options.insertOverlay;
	
	// Determine what is being copied
	startX = MAX(options.rect.origin.x - xoff, (xoff < 0) ? -xoff : 0);
	startY = MAX(options.rect.origin.y - yoff, (yoff < 0) ? -yoff : 0);
	endX = MIN([contents width] - xoff, lwidth);
	endX = MIN(endX, options.rect.origin.x + options.rect.size.width - xoff);
	endY = MIN([contents height] - yoff, lheight);
	endY = MIN(endY, options.rect.origin.y + options.rect.size.height - yoff);
	
	// Get some stuff we're going to use later
	//selectRect = [(SeaSelection *)[document selection] localRect];
	srcPtr = [(SeaLayer *)layer data];
	floatPtr = [(SeaLayer *)floatingLayer data];
	destPtr = [whiteboard data];
	overlay = [whiteboard overlay];
	replace = [whiteboard replace];
	//mask = [[document selection] mask];
	//maskOffset = [[document selection] maskOffset];
	//trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
	//maskSize = [[document selection] maskSize];
	floating = [layer floating];
	
	// Check what we are doing has a point
	if (endX - startX <= 0) return;
	if (endY - startY <= 0) return;
	
	// Go through each row
	for (j = startY; j < endY; j++) {
	
		// Disolving requires us to play with the random number generator
		if (mode == XCF_DISSOLVE_MODE) {
			srandom(randomTable[(j + yoff) % 4096]);
			for (k = 0; k < xoff; k++)
				random();
		}
		
		// Go through each column
		for (i = startX; i < endX; i++) {
		
			// Determine the location in memory of the pixel we are copying from and to
			srcLoc = (j * lwidth + i) * options.spp;
			destLoc = ((j + yoff - options.destRect.origin.y) * options.destRect.size.width + (i + xoff - options.destRect.origin.x)) * options.spp;
			
			// Prepare for overlay application
			for (k = 0; k < options.spp; k++)
				tempSpace2[k] = srcPtr[srcLoc + k];
				
			// Insert floating layer
			ty = yoff - yfoff + j;
			tx = xoff - xfoff + i;
			if (ty >= 0 && ty < lfheight) {
				if (tx >= 0 && tx < lfwidth) {
					floatLoc = (ty * lfwidth + tx) * options.spp;
					for (k = 0; k < options.spp; k++)
						tempSpace3[k] = floatPtr[floatLoc + k];
					if (insertOverlay) {
						switch (options.overlayBehaviour) {
							case kReplacingBehaviour:
							case kMaskingBehaviour:
								selectOpacity = replace[ty * lfwidth + tx];
							break;
							default:
								selectOpacity = options.overlayOpacity;
							break;
						}
						if (selectOpacity > 0) {
							primaryMerge(options.spp, tempSpace3, 0, overlay, floatLoc, selectOpacity, YES);
						}
					}
					if (selectedChannel == kAllChannels) {
						normalMerge(options.spp, tempSpace2, 0, tempSpace3, 0, 255);
					}
					else if (selectedChannel == kPrimaryChannels) {
						primaryMerge(options.spp, tempSpace2, 0, tempSpace3, 0, 255, YES);
					}
					else if (selectedChannel == kAlphaChannel) {
						alphaMerge(options.spp, tempSpace2, 0, tempSpace3, 0, 255);
					}
				}
			}
			
			// If the layer is going to use a compositing effect...
			if (normal == NO && mode != XCF_NORMAL_MODE && options.forceNormal == NO) {

				// Copy pixel from destination in to temporary memory
				for (k = 0; k < options.spp; k++)
					tempSpace[k] = destPtr[destLoc + k];
				
				// Apply the appropriate effect using the source pixel
				selectMerge(mode, options.spp, tempSpace, 0, tempSpace2, 0);
				
				// Then merge the pixel in temporary memory with the destination pixel
				normalMerge(options.spp, destPtr, destLoc, tempSpace, 0, opacity);
			
			}
			else {
				
				// Then merge the pixel in temporary memory with the destination pixel
				normalMerge(options.spp, destPtr, destLoc, tempSpace2, 0, opacity);
			
			}
			
		}
	}
}

@end

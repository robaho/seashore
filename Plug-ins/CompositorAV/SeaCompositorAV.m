#import "SeaCompositorAV.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "SeaLayer.h"
#import "SeaContent.h"
#import "SeaSelection.h"

@implementation SeaCompositorAV

- (id)initWithDocument:(id)doc
{
	int i;
	
	// Remember the document we are compositing for
	document = doc;
	
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

- (void)compositeLayerC:(id)layer withOptions:(CompositorOptions)options andData: (unsigned char *) destPtr
{
	unsigned char *srcPtr, *overlay, *mask, *replace;
	int lwidth = [(SeaLayer *)layer width], lheight = [(SeaLayer *)layer height], mode = [(SeaLayer *)layer mode];
	int width = [(SeaContent *)[document contents] width]; 
	int opacity = [layer opacity], selectedChannel = [[document contents] selectedChannel];
	int xoff = [layer xoff], yoff = [layer yoff], selectOpacity;
	int startX, startY, endX, endY, t1;
	int i, j, k, srcLoc, destLoc;
	unsigned char tempSpace[4], tempSpace2[4];
	BOOL insertOverlay, overlayOkay;
	IntPoint point, maskOffset, trueMaskOffset;
	IntSize maskSize;
	IntRect selectRect;
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
	endX = MIN([(SeaContent *)[document contents] width] - xoff, lwidth);
	endX = MIN(endX, options.rect.origin.x + options.rect.size.width - xoff);
	endY = MIN([(SeaContent *)[document contents] height] - yoff, lheight);
	endY = MIN(endY, options.rect.origin.y + options.rect.size.height - yoff);
	
	// Get some stuff we're going to use later
	selectRect = [(SeaSelection *)[document selection] localRect];
	srcPtr = [(SeaLayer *)layer data];
	if(!destPtr) destPtr = [(SeaWhiteboard *)[document whiteboard] data];
	overlay = [(SeaWhiteboard *)[document whiteboard] overlay];
	replace = [(SeaWhiteboard *)[document whiteboard] replace];
	mask = [[document selection] mask];
	maskOffset = [[document selection] maskOffset];
	trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
	maskSize = [[document selection] maskSize];
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
			destLoc = ((j + yoff) * width + (i + xoff)) * options.spp;
			
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
				if (options.useSelection) {
					point.x = i;
					point.y = j;
					if (IntPointInRect(point, selectRect)) {
						overlayOkay = YES;
						if (mask && !floating)
							selectOpacity = int_mult(selectOpacity, mask[(trueMaskOffset.y + point.y) * maskSize.width + (trueMaskOffset.x + point.x)], t1);
					}
				}
				else {
					overlayOkay = YES;
				}
				
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

- (void)compositeLayerAV:(id)layer withOptions:(CompositorOptions)options andData:(vector unsigned char *)destPtr
{
	vector unsigned char *srcPtr = (vector unsigned char *)[(SeaLayer *)layer data], *overlay = (vector unsigned char *)[(SeaWhiteboard *)[document whiteboard] overlay];
	const vector unsigned char emptyVector = (vector unsigned char)(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
	vector unsigned char maskVector, opacityVector, overlayOpacityVector;
	vector unsigned char sourceVector, overlayVector;
	BOOL insertOverlay, fullOpacity, fullOverlayOpacity;
	int lwidth = [(SeaLayer *)layer width], lheight = [(SeaLayer *)layer height];
	int width = [(SeaContent *)[document contents] width]; 
	int opacity = [layer opacity], selectedChannel = [[document contents] selectedChannel];
	int maxSrcLoc = make_128(lwidth * lheight * 4);
	int xoff = [layer xoff], yoff = [layer yoff];
	int overlayOpacity, i, j, k, k1;
	int startX, startY, endX, endY;
	int endSrcLoc, srcLoc, destLoc;
	if(!destPtr) destPtr = (vector unsigned char *)[(SeaWhiteboard *)[document whiteboard] data];
	
	// If the layer has an opacity of zero it does not need to be composited
	if (opacity == 0)
		return;
	
	// If the overlay has an opacity of zero it does not need to be inserted
	overlayOpacity = options.overlayOpacity;
	if (overlayOpacity == 0)
		insertOverlay = NO;
	else
		insertOverlay = options.insertOverlay;
	
	// Determine what is being copied
	startX = MAX(options.rect.origin.x - xoff, (xoff < 0) ? -xoff : 0);
	startY = MAX(options.rect.origin.y - yoff, (yoff < 0) ? -yoff : 0);
	endX = MIN([(SeaContent *)[document contents] width] - xoff, lwidth);
	endX = MIN(endX, options.rect.origin.x + options.rect.size.width - xoff);
	endY = MIN([(SeaContent *)[document contents] height] - yoff, lheight);
	endY = MIN(endY, options.rect.origin.y + options.rect.size.height - yoff);
	
	// Check what we are doing has a point
	if (endX - startX <= 0) return;
	if (endY - startY <= 0) return;
	
	// Determine the opacity vector 
	fullOpacity = (opacity == 255);
	if (!fullOpacity) {
		for (k = 0; k < 16; k++)
			mvec_set_uchar(&opacityVector, k, opacity);
	}
	
	// Determine the overlay opacity vector
	if (insertOverlay) {
		fullOverlayOpacity = (options.overlayOpacity == 255);
		if (!fullOverlayOpacity) {
			for (k = 0; k < 16; k++)
				mvec_set_uchar(&overlayOpacityVector, k, options.overlayOpacity);
		}
	}
	
	// Go through copying line by line
	for (j = startY; j < endY; j++) {
			
		// Remember where to stop drawing in the source
		endSrcLoc = (j * lwidth + endX) * options.spp;
		
		// Set the i variable at the start
		i = startX;
		
		// Determine where to begin drawing in the source and destination
		srcLoc = (j * lwidth + i) * options.spp;
		destLoc = (j + yoff) * width * options.spp + (i + xoff) * options.spp;
		
		// Set all pixels up to the where we begin plotting to transparent
		for (k = 0; k < destLoc % 16; k++)
			mvec_set_uchar(&maskVector, k, 0x10);
		
		// Then put the source pixels in (starting at srcLoc)
		k1 = 16 - (destLoc % 16);
		for (k = 0; k < k1; k++)
			mvec_set_uchar(&maskVector, destLoc % 16 + k, (srcLoc + k) % 16);
		
		// Finally make the above information into a source vector
		sourceVector = vec_perm(srcPtr[srcLoc / 16], emptyVector, maskVector);
		if (insertOverlay) overlayVector = vec_perm(overlay[srcLoc / 16], emptyVector, maskVector);
		
		// If the source pixels reside across two vectors then things get sticky
		if (srcLoc % 16 + k1 > 16) {
		
			// Determine what to preserve from the first vector
			for (k = 0; k < 16 - (srcLoc + k1) % 16; k++)
				mvec_set_uchar(&maskVector, k, k);
			
			// Then introduce the second vector
			for (k = 0; k < (srcLoc + k1) % 16; k++)
				mvec_set_uchar(&maskVector, 16 - (srcLoc + k1) % 16 + k, 0x10 + k);
			
			// Recalculate the source vector
			sourceVector = vec_perm(sourceVector, srcPtr[srcLoc / 16 + 1], maskVector);
			if (insertOverlay) overlayVector = vec_perm(overlayVector, overlay[srcLoc / 16 + 1], maskVector);

		}
		
		// If we are drawing the last vector
		if ((destLoc % 16) + (endSrcLoc - srcLoc) < 16) {
			
			// Assume everything is blank to start with that
			for (k = 0; k < 16; k++)
				mvec_set_uchar(&maskVector, k, 0x10);
			
			// Restore all the in-bounds stuff
			for (k = 0; k < (destLoc % 16) + (endSrcLoc - srcLoc); k++)
				mvec_set_uchar(&maskVector, k, k);
			
			// Recalculate the source vector
			sourceVector = vec_perm(sourceVector, emptyVector, maskVector);
			if (insertOverlay) overlayVector = vec_perm(overlayVector, emptyVector, maskVector);
		
		}
		
		// Finally take the source vector and composite it to the destination
		if (insertOverlay) {
			if (selectedChannel == kAllChannels) {
				switch (options.overlayBehaviour) {
					case kErasingBehaviour:
						sourceVector = eraseMergeAV(options.spp, sourceVector, overlayVector, fullOverlayOpacity ? NULL : &overlayOpacityVector);
					break;
					default:
						sourceVector = specialMergeAV(options.spp, sourceVector, overlayVector, fullOverlayOpacity ? NULL : &overlayOpacityVector);
					break;
				}
			}
			else if (selectedChannel == kPrimaryChannels) {
				sourceVector = primaryMergeAV(options.spp, sourceVector, overlayVector, fullOverlayOpacity ? NULL : &overlayOpacityVector);
			}
			else if (selectedChannel == kAlphaChannel) {
				sourceVector = alphaMergeAV(options.spp, sourceVector, overlayVector, fullOverlayOpacity ? NULL : &overlayOpacityVector);
			}
		}
		destPtr[destLoc / 16] = normalMergeAV(options.spp, destPtr[destLoc / 16], sourceVector, fullOpacity ? NULL : &opacityVector);
		
		// Move along to just after we finished plotting
		i += (k1 / options.spp);
		
		// Determine where to draw next in the source and destination
		srcLoc = (j * lwidth + i) * options.spp;
		destLoc = ((j + yoff) * width + (i + xoff)) * options.spp;
		
		// Precalculate the mask
		for (k = 0; k < 16 - (srcLoc % 16); k++)
			mvec_set_uchar(&maskVector, k, (srcLoc % 16) + k);
		for (k = 0; k < (srcLoc % 16); k++)
			mvec_set_uchar(&maskVector, 16 - (srcLoc % 16) + k, 0x10 + k);
		
		// While there is still stuff to be drawn...
		while (endSrcLoc - srcLoc > 0) {
			
			// Recalculate the source vector
			sourceVector = vec_perm(srcPtr[srcLoc / 16], (srcLoc / 16 + 1 < maxSrcLoc / 16) ? srcPtr[srcLoc / 16 + 1] : emptyVector, maskVector);
			if (insertOverlay) overlayVector = vec_perm(overlay[srcLoc / 16], (srcLoc / 16 + 1 < maxSrcLoc / 16) ? overlay[srcLoc / 16 + 1] : emptyVector, maskVector);
			
			// If we are drawing the last vector - is this accurate?
			if (endSrcLoc - srcLoc < 16) {
				
				// Assume everything is blank to start with that
				for (k = 0; k < 16; k++)
					mvec_set_uchar(&maskVector, k, 0x10);
					
				// Preserve all the in-bounds stuff from the above vector
				for (k = 0; k < endSrcLoc - srcLoc; k++)
					mvec_set_uchar(&maskVector, k, k);
				
				// Recalculate the source vector
				sourceVector = vec_perm(sourceVector, emptyVector, maskVector);
				if (insertOverlay) overlayVector = vec_perm(overlayVector, emptyVector, maskVector);
				
			}
			
			// Finally take the source vector and composite it to the destination
			if (insertOverlay) {
				if (selectedChannel == kAllChannels) {
					switch (options.overlayBehaviour) {
						case kErasingBehaviour:
							sourceVector = eraseMergeAV(options.spp, sourceVector, overlayVector, fullOverlayOpacity ? NULL : &overlayOpacityVector);
						break;
						default:
							sourceVector = specialMergeAV(options.spp, sourceVector, overlayVector, fullOverlayOpacity ? NULL : &overlayOpacityVector);
						break;
					}
				}
				else if (selectedChannel == kPrimaryChannels) {
					sourceVector = primaryMergeAV(options.spp, sourceVector, overlayVector, fullOverlayOpacity ? NULL : &overlayOpacityVector);
				}
				else if (selectedChannel == kAlphaChannel) {
					sourceVector = alphaMergeAV(options.spp, sourceVector, overlayVector, fullOverlayOpacity ? NULL : &overlayOpacityVector);
				}
			}
			destPtr[destLoc / 16] = normalMergeAV(options.spp, destPtr[destLoc / 16], sourceVector, fullOpacity ? NULL : &opacityVector);
			
			// Determine where to draw next in the source and destination
			srcLoc += 16;
			destLoc += 16;
		}

	}
}

- (void)compositeLayer:(id)layer withOptions:(CompositorOptions)options
{
	[self compositeLayer: layer withOptions: options andData: NULL];
}

- (void)compositeLayer:(id)layer withOptions:(CompositorOptions)options andData:(unsigned char *)destPtr
{
	int  mode = [(SeaLayer *)layer mode];
	
	if ((normal == NO && mode != XCF_NORMAL_MODE) || options.overlayBehaviour == kReplacingBehaviour  || options.overlayBehaviour == kMaskingBehaviour || options.useSelection || [layer floating]) {
		[self compositeLayerC:layer withOptions:options andData: destPtr];
	}
	else {
		[self compositeLayerAV:layer withOptions:options andData:(vector unsigned char *)destPtr];
	}
}

- (void)compositeLayer:(id)layer withFloat:(id)floatingLayer andOptions:(CompositorOptions)options
{
	unsigned char *srcPtr, *floatPtr, *destPtr, *overlay, *mask, *replace;
	int lwidth = [(SeaLayer *)layer width], lheight = [(SeaLayer *)layer height], mode = [(SeaLayer *)layer mode];
	int lfwidth = [(SeaLayer *)floatingLayer width], lfheight = [(SeaLayer *)floatingLayer height];
	int width = [(SeaContent *)[document contents] width]; 
	int opacity = [layer opacity], selectedChannel = [[document contents] selectedChannel];
	int xoff = [layer xoff], yoff = [layer yoff], selectOpacity;
	int xfoff = [floatingLayer xoff], yfoff = [floatingLayer yoff];
	int startX, startY, endX, endY;
	int i, j, k, srcLoc, destLoc, floatLoc, tx, ty;
	unsigned char tempSpace[4], tempSpace2[4], tempSpace3[4];
	BOOL insertOverlay;
	IntPoint maskOffset, trueMaskOffset;
	IntSize maskSize;
	IntRect selectRect;
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
	endX = MIN([(SeaContent *)[document contents] width] - xoff, lwidth);
	endX = MIN(endX, options.rect.origin.x + options.rect.size.width - xoff);
	endY = MIN([(SeaContent *)[document contents] height] - yoff, lheight);
	endY = MIN(endY, options.rect.origin.y + options.rect.size.height - yoff);
	
	// Get some stuff we're going to use later
	selectRect = [(SeaSelection *)[document selection] localRect];
	srcPtr = [(SeaLayer *)layer data];
	floatPtr = [(SeaLayer *)floatingLayer data];
	destPtr = [(SeaWhiteboard *)[document whiteboard] data];
	overlay = [(SeaWhiteboard *)[document whiteboard] overlay];
	replace = [(SeaWhiteboard *)[document whiteboard] replace];
	mask = [[document selection] mask];
	maskOffset = [[document selection] maskOffset];
	trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
	maskSize = [[document selection] maskSize];
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
			destLoc = ((j + yoff) * width + (i + xoff)) * options.spp;
			
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

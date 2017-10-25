#import "XCFLayer.h"
#import "RLE.h"

@implementation XCFLayer

static inline void fix_endian_read(int *input, int size)
{
#ifdef __i386__
	int i;
	
	for (i = 0; i < size; i++) {
		input[i] = ntohl(input[i]);
	}
#endif
}

- (BOOL)readHeader:(FILE *)file
{
	char nameString[256];
	int i;
	
	// Read the width and height
	fread(tempIntString, sizeof(int), 3, file);
	fix_endian_read(tempIntString, 3);
	width = tempIntString[0];
	height = tempIntString[1];
	
	// Read the name
	fread(tempIntString, sizeof(int), 1, file);
	fix_endian_read(tempIntString, 1);
	if (tempIntString[0] > 0) {
		i = 0;
		nameString[255] = 0;
		do {
			if (i < 255) {
				nameString[i] = fgetc(file);
				i++;
			}
		} while (nameString[i - 1] != 0 && !ferror(file));
		if (name) [name autorelease];
		name = [[NSString alloc] initWithUTF8String:nameString];
	}
	else {
		if (name) [name autorelease];
		name = [[NSString alloc] initWithString:LOCALSTR(@"untitled", @"Untitled")];
	}
	
	// Fail if anything goes wrong
	if (ferror(file))
		return NO;
	
	return YES;
}


- (BOOL)readProperties:(FILE *)file sharedInfo:(SharedXCFInfo *)info
{
	int propType, propSize;
	BOOL finished = NO;
	int lostprops_pos;
	
	// Keep reading until we're finished or hit an error
	info->active = NO;
	while (!finished && !ferror(file)) {
		fread(tempIntString, sizeof(int), 2, file);
		fix_endian_read(tempIntString, 2);
		propType = tempIntString[0];
		propSize = tempIntString[1];
		switch (propType) {
			case PROP_END:
				finished = YES;
				break;
			case PROP_OPACITY:
				
				// Store the layer's opacity
				fread(tempIntString, sizeof(int), 1, file);
				fix_endian_read(tempIntString, 1);
				opacity = tempIntString[0];
				
				break;
			case PROP_VISIBLE:
				
				// Store the layer's visibility
				fread(tempIntString, sizeof(int), 1, file);
				fix_endian_read(tempIntString, 1);
				visible = tempIntString[0];
				
				break;
			case PROP_OFFSETS:
				
				// Store the layer's offsets
				fread(tempIntString, sizeof(int), 2, file);
				fix_endian_read(tempIntString, 2);
				xoff = ((int *)tempIntString)[0];
				yoff = ((int *)tempIntString)[1];
				
				break;
			case PROP_MODE:
				
				// Store the layer's mode
				fread(tempIntString, sizeof(int), 1, file);
				fix_endian_read(tempIntString, 1);
				mode = tempIntString[0];
				
				break;
			case PROP_ACTIVE_LAYER:
				
				// Store whether the layer is the active one
				info->active = YES;
				
				break;
			case PROP_LINKED:
				
				// Store whether the layer's linked
				fread(tempIntString, sizeof(int), 1, file);
				fix_endian_read(tempIntString, 1);
				linked = tempIntString[0];
				
				break;
			case PROP_FLOATING_SELECTION:
				
				// Store that the layer is floating
				fread(tempIntString, sizeof(int), 1, file);
				fix_endian_read(tempIntString, 1);
				floating = YES;
				
				break;
			case PROP_APPLY_MASK:
			case PROP_EDIT_MASK:
			case PROP_SHOW_MASK:
				
				// Skip these properties
				fseek(file, propSize, SEEK_CUR);
				
				break;
			default:
				
				// Skip these properties but record them for saving
				fseek(file, -2 * sizeof(int), SEEK_CUR);
				lostprops_pos = lostprops_len;
				if (lostprops_len == 0) {
					lostprops_len = 2 * sizeof(int) + propSize;
					lostprops = malloc(lostprops_len);
				}
				else {
					lostprops_len += 2 * sizeof(int) + propSize;
					lostprops = realloc(lostprops, lostprops_len);
				}
				fread(&(lostprops[lostprops_pos]), sizeof(char), 2 * sizeof(int) + propSize, file);
				
				break;
				
		}
	}
	
	// If we've had a problem fail
	if (ferror(file))
		return NO;
	
	return YES;
}

- (BOOL)skipMaskHeader:(FILE *)file
{
	int propType, propSize;
	BOOL finished;
	
	// Skip width, height and name
	fseek(file, sizeof(int) * 2, SEEK_CUR);
	fread(tempIntString, sizeof(int), 1, file);
	fix_endian_read(tempIntString, 2);
	if (tempIntString[0]) {
		do { } while (fgetc(file) != 0 && !ferror(file));
	}
	if (ferror(file))
		return NO;
	
	// Skip properties
	finished = NO;
	while (!finished && !ferror(file)) {
		fread(tempIntString, sizeof(int), 2, file);
		fix_endian_read(tempIntString, 2);
		propType = tempIntString[0];
		propSize = tempIntString[1];
		switch (propType) {
			case PROP_END:
				finished = YES;
				break;
			default:
				fseek(file, propSize, SEEK_CUR);
				break;
		}
	}
	
	// If we've had a problem fail
	if (ferror(file))
		return NO;
	
	// Move into position
	fread(tempIntString, sizeof(int), 1, file);
	fix_endian_read(tempIntString, 1);
	fseek(file, tempIntString[0], SEEK_SET);
	fread(tempIntString, sizeof(int), 4, file);
	fix_endian_read(tempIntString, 4);
	fseek(file, tempIntString[3], SEEK_SET);
	
	return YES;
}

- (unsigned char *)readPixels:(FILE *)file sharedInfo:(SharedXCFInfo *)info
{
	int tilesPerRow = (width % XCF_TILE_WIDTH) ? (width / XCF_TILE_WIDTH + 1) : (width / XCF_TILE_WIDTH);
	int tilesPerColumn = (height % XCF_TILE_HEIGHT) ? (height / XCF_TILE_HEIGHT + 1) : (height / XCF_TILE_HEIGHT);
	int whichTile = 0, i, j, k, curColor, srcSPP, destSPP;
	int tileHeight, tileWidth;
	int tileOffset, oldOffset, srcLoc, destLoc, expectedSize, srcSize;
	unsigned char *cmap = info->cmap;
	unsigned char *srcData, *tileData, *totalData;
	BOOL finished;
	
	// Determine the source's samples per pixel
	fread(tempIntString, sizeof(int), 4, file);
	fix_endian_read(tempIntString, 4);
	destSPP = tempIntString[2];
	srcSPP = destSPP;
	fseek(file, tempIntString[3], SEEK_SET);
	
	// NSLog(@"%d - %d - %d - %d", tempIntString[0], tempIntString[1], tempIntString[2], tempIntString[3]);
	
	// Determine the target samples per pixel
	oldOffset = ftell(file) + 2 * sizeof(int);
	fread(tempIntString, sizeof(int), 2, file);
	fix_endian_read(tempIntString, 2);
	// NSLog(@"%d - %d", tempIntString[0], tempIntString[1]);
	if (info->type == XCF_INDEXED_IMAGE || info->type == XCF_RGB_IMAGE)
		destSPP = 4;
	else
		destSPP = 2;
	
	// Allocate memory for loading
	tileData = malloc(XCF_TILE_HEIGHT * XCF_TILE_WIDTH * srcSPP);
	totalData = malloc(make_128(width * height * destSPP));
	// do_128_clean(totalData, make_128(width * height * spp));
	
	do {
		
		// Read the offset of the next tile
		fseek(file, oldOffset, SEEK_SET);
		fread(tempIntString, sizeof(int), 1, file);
		fix_endian_read(tempIntString, 1);
		oldOffset = ftell(file);
		tileOffset = tempIntString[0];
		finished = (tileOffset == 0);
		
		// Determine the tile's width, height and expected size
		tileWidth =  (whichTile % tilesPerRow == tilesPerRow - 1 && width % XCF_TILE_WIDTH != 0) ? (width % XCF_TILE_WIDTH) : XCF_TILE_WIDTH;
		tileHeight = (whichTile / tilesPerRow == tilesPerColumn - 1 && height % XCF_TILE_HEIGHT != 0) ? (height % XCF_TILE_HEIGHT) : XCF_TILE_HEIGHT;
		expectedSize = tileHeight * tileWidth * srcSPP;
		
		// If we have another tile...
		if (!finished) {
			
			// Read the tile data
			fseek(file, tileOffset, SEEK_SET);
			switch (info->compression) {
				case COMPRESS_NONE:
					
					// In case of no compression...
					srcData = malloc(expectedSize);
					if (fread(srcData, sizeof(char), expectedSize, file) != expectedSize) {
						// NSRunAlertPanel(@"Unexpected end-of-file", @"The data being loaded has unexpectedly ended, this could be due to an incomplete or corrupted XCF file. As such this file cannot be properly loaded.", @"OK", NULL, NULL);
						//NSLog(@"Unexpected end-of-file (no compression pixles)");
						free(srcData); free(tileData); free(totalData);
						return NULL;
					}
					for (i = 0; i < srcSPP; i++) {
						for (j = 0; j < expectedSize; j++)
							tileData[i + j * srcSPP] = srcData[i * width * height + j];
					}
					free(srcData);
					
					break;
				case COMPRESS_RLE:
					
					// In case of RLE compression (typical case)...
					// NSLog(@"Tile begins at: %d", ftell(file));
					srcData = malloc(expectedSize * 1.3 + 1);
					srcSize = fread(srcData, sizeof(char), expectedSize * 1.3 + 1, file);
					if (!RLEDecompress(tileData, srcData, srcSize, tileWidth, tileHeight, srcSPP)) {
						// NSRunAlertPanel(@"RLE decompression failed", @"The RLE decompression of a certain part of this file failed, this could be due to an incomplete or corrupted XCF file. As such this file cannot be properly loaded.", @"OK", NULL, NULL);
						//NSLog(@"RLE decompression failed (pixels)");
						free(srcData); free(tileData); free(totalData);
						return NULL;
					}
					free(srcData);
					
					break;
			}
			
			// Now transfer that data to the big picture
			for (j = 0; j < tileHeight; j++) {
				for (i = 0; i < tileWidth; i++) {
					srcLoc = (i + j * tileWidth) * srcSPP;
					destLoc = (((whichTile % tilesPerRow) * XCF_TILE_WIDTH) + i) * destSPP + ((whichTile /  tilesPerRow) * XCF_TILE_HEIGHT + j) * width * destSPP;
					
					// There is a different transfer mechanism for indexed and non-indexed formats
					switch (info->type) {
						case XCF_GRAY_IMAGE:
						case XCF_RGB_IMAGE:
							for (k = 0; k < srcSPP; k++)
								totalData[destLoc + k] = tileData[srcLoc + k];
							if (srcSPP + 1 == destSPP)
								totalData[destLoc + srcSPP] = 255;
							break;
						case XCF_INDEXED_IMAGE:
							curColor = (int)tileData[srcLoc];
							if (curColor < info->cmap_len - 1) {
								for (k = 0; k < 3; k++)
									totalData[destLoc + k] = cmap[curColor * 3 + k];
								totalData[destLoc + 3] = 255;
							}
							else {
								for (k = 0; k < 4; k++)
									totalData[destLoc + k] = 0;
							}
							break;
					}
					
					
				}
			}
			
			// Move to the next tile
			whichTile++;
			
		}
		
	} while (!finished && !ferror(file));
	
	// If we've had a problem fail
	if (ferror(file)) {
		free(tileData); free(totalData);
		return NULL;
	}
	
	// Free the redundant tile data, remember the images samples per pixel
	free(tileData);
	spp = destSPP;
	
	return totalData;
}

- (BOOL)readMaskPixels:(FILE *)file toData:(unsigned char *)totalData sharedInfo:(SharedXCFInfo *)info
{
	int tilesPerRow = (width % XCF_TILE_WIDTH) ? (width / XCF_TILE_WIDTH + 1) : (width / XCF_TILE_WIDTH);
	int tilesPerColumn = (width % XCF_TILE_HEIGHT) ? (height / XCF_TILE_HEIGHT + 1) : (height / XCF_TILE_HEIGHT);
	int tileHeight, tileWidth;
	int tileOffset, oldOffset, srcLoc, destLoc, expectedSize, srcSize;
	unsigned char *srcData, *tileData;
	int whichTile = 0, i, j;
	BOOL finished;
	
	// We have no use for the mask's header information (we assume its reasonable)
	if (![self skipMaskHeader:file])
		return NO;
	
	// Prepare to load tile-by-tile
	oldOffset = ftell(file) + 2 * sizeof(int);
	tileData = malloc(XCF_TILE_HEIGHT * XCF_TILE_WIDTH);
	
	do {
		
		// Read the offset of the next tile
		fseek(file, oldOffset, SEEK_SET);
		fread(tempIntString, sizeof(int), 1, file);
		fix_endian_read(tempIntString, 1);
		oldOffset = ftell(file);
		tileOffset = tempIntString[0];
		finished = (tileOffset == 0);
		
		// Determine the tile's width, height and expected size
		tileWidth =  (whichTile % tilesPerRow == tilesPerRow - 1 && width % XCF_TILE_WIDTH != 0) ? (width % XCF_TILE_WIDTH) : XCF_TILE_WIDTH;
		tileHeight = (whichTile / tilesPerRow == tilesPerColumn - 1 && height % XCF_TILE_HEIGHT != 0) ? (height % XCF_TILE_HEIGHT) : XCF_TILE_HEIGHT;
		expectedSize = tileHeight * tileWidth;
		
		// If we have another tile...
		if (!finished) {
			
			// Read the tile data
			fseek(file, tileOffset, SEEK_SET);
			switch (info->compression) {
				case COMPRESS_NONE:
					
					// In case of no compression...
					srcData = malloc(expectedSize);
					if (fread(srcData, sizeof(char), expectedSize, file) != expectedSize) {
						// NSRunAlertPanel(@"Unexpected end-of-file", @"The data being loaded has unexpectedly ended, this could be due to an incomplete or corrupted XCF file. As such this file cannot be properly loaded.", @"OK", NULL, NULL);
						//NSLog(@"Unexpected end-of-file (no compression mask)");
						free(srcData); free(tileData); free(totalData);
						return NO;
					}
					for (i = 0; i < expectedSize; i++)
						tileData[i] = srcData[i];
					free(srcData);
					
					break;
				case COMPRESS_RLE:
					
					// In case of RLE compression (typical case)...
					srcData = malloc(expectedSize * 1.3 + 1);
					srcSize = fread(srcData, sizeof(char), expectedSize * 1.3 + 1, file);
					if (!RLEDecompress(tileData, srcData, srcSize, tileWidth, tileHeight, 1)) {
						// NSRunAlertPanel(@"RLE decompression failed", @"The RLE decompression of a certain part of this file failed, this could be due to an incomplete or corrupted XCF file. As such this file cannot be properly loaded.", @"OK", NULL, NULL);
						//NSLog(@"RLE decompression failed (mask)");
						free(srcData); free(tileData); free(totalData);
						return NO;
					}
					free(srcData);
					
					break;
			}
			
			// Now transfer that data to the big picture overwriting any existing alpha channel
			for (j = 0; j < tileHeight; j++) {
				for (i = 0; i < tileWidth; i++) {
					srcLoc = (i + j * tileWidth);
					destLoc = (((whichTile % tilesPerRow) * XCF_TILE_WIDTH) + i) * spp + ((whichTile /  tilesPerRow) * XCF_TILE_HEIGHT + j) * width * spp;
					totalData[destLoc + (spp - 1)] = tileData[srcLoc];				
				}
			}
			
			// Move to the next tile
			whichTile++;
			
		}
		
	} while (!finished && !ferror(file));
	
	// If we've had a problem fail
	if (ferror(file)) {
		free(tileData); free(totalData);
		return NO;
	}
	
	// Free the redundant tile data
	free(tileData);
	
	return YES;
}

- (BOOL)readBody:(FILE *)file sharedInfo:(SharedXCFInfo *)info
{
	int maskOffset, pixelsOffset;
	
	// Determine relevant file positions
	fread(tempIntString, sizeof(int), 2, file);
	fix_endian_read(tempIntString, 2);
	pixelsOffset = tempIntString[0];
	maskOffset = tempIntString[1];
	fseek(file, pixelsOffset, SEEK_SET);
	
	// NSLog(@"Layer Pixels Present At: %d", pixelsOffset);
	// NSLog(@"Mask Present At: %d", maskOffset);
	
	// Read in the image data
	data = [self readPixels:file sharedInfo:info];
	
	// If we've had a problem fail
	if (data == NULL)
		return NO;
	
	// Read in the mask (and overwrite the alpha channel)
	if (maskOffset != 0) {
		info->maskToAlpha = YES;
		fseek(file, maskOffset, SEEK_SET);
		if (![self readMaskPixels:file toData:data sharedInfo:info]) {
			return NO;
		}
	}
	else {
		info->maskToAlpha = NO;
	}
	
	return YES;
}

- (id)initWithFile:(FILE *)file offset:(int)offset sharedInfo:(SharedXCFInfo *)info
{
	int i;
	
	// Initialize superclass first
	if (![super  init])
		return NULL;
	
	// Go to the given offset
	fseek(file, offset, SEEK_SET);
	
	// NSLog(@"Layer Header Begin: %d", ftell(file));
	
	// Read the header
	if ([self readHeader:file] == NO) {
		[self autorelease];
		return NULL;
	}
	
	// NSLog(@"Layer Properties Begin: %d", ftell(file));
	
	// Read the properties
	if ([self readProperties:file sharedInfo:info] == NO) {
		[self autorelease];
		return NULL;
	}
	
	// NSLog(@"Layer Properties End: %d", ftell(file));
	
	// Read the body
	if ([self readBody:file sharedInfo:info] == NO) {
		[self autorelease];
		return NULL;
	}
	
	// Check the alpha
	hasAlpha = NO;
	for (i = 0; i < width * height; i++) {
		if (data[(i + 1) * spp - 1] != 255)
			hasAlpha = YES;
	}
	
	return self;
}

@end

#import "XCFLayer.h"
#import <SeaLibrary/RLE.h>
#import <SeaLibrary/Bitmap.h>

@implementation XCFLayer

static inline void fix_endian_read(int *input, int size)
{
#ifdef __LITTLE_ENDIAN__
	int i;
	
	for (i = 0; i < size; i++) {
		input[i] = ntohl(input[i]);
	}
#endif
}

static inline void fix_endian_readl(long *input, int size)
{
#ifdef __LITTLE_ENDIAN__
    int i;
    
    for (i = 0; i < size; i++) {
        input[i] = ntohll(input[i]);
    }
#endif
}

- (long)readOffset:(FILE*)file;
{
    if(version>=11){
        long offset;
        fread(&offset, sizeof(long), 1, file);
        fix_endian_readl(&offset,1);
        return offset;
    } else {
        int offset;
        fread(&offset, sizeof(int), 1, file);
        fix_endian_read(&offset,1);
        return offset;
    }
}

- (BOOL)readHeader:(FILE *)file
{
	char nameString[256];
	int i;
    
    int tempIntString[16];
	
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
		name = [[NSString alloc] initWithUTF8String:nameString];
	}
	else {
		name = [[NSString alloc] initWithString:LOCALSTR(@"untitled", @"Untitled")];
	}
	
	// NSLog(@"Layer's name: %@", name);
	
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
    
    int tempIntString[16];
	
	// Keep reading until we're finished or hit an error
	
	// We should be doing bounds checking for all of this but we aren't
	
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
				
				// Bounds checking in case of corruption
				if (opacity < 0 || opacity > 255) opacity = 255;
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
                int xcf_mode = tempIntString[0];
                if(XcfLayerModeMap[xcf_mode].blendMode==-1){
                    info->unsupported_mode = TRUE;
                    xcf_mode = GIMP_LAYER_MODE_NORMAL;
                }
                mode = XcfLayerModeMap[xcf_mode].blendMode;
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
				fread(tempIntString, sizeof(int), 1, file);
				fix_endian_read(tempIntString, 1);
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
					lostprops_len += (2 * sizeof(int) + propSize);
					lostprops = realloc(lostprops, lostprops_len);
				}
                CHECK_MALLOC(lostprops);
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
    
    int tempIntString[16];
	
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
    
    fseek(file,[self readOffset:file],SEEK_SET); // move to start of hierarchy
	
	return YES;
}

- (unsigned char *)readPixels:(FILE *)file sharedInfo:(SharedXCFInfo *)info
{
	int tilesPerRow = (width % XCF_TILE_WIDTH) ? (width / XCF_TILE_WIDTH + 1) : (width / XCF_TILE_WIDTH);
	int tilesPerColumn = (height % XCF_TILE_HEIGHT) ? (height / XCF_TILE_HEIGHT + 1) : (height / XCF_TILE_HEIGHT);
	int whichTile = 0, i, j, k, curColor, srcSPP, destSPP;
	int tileHeight, tileWidth;
    long tileOffset, oldOffset;
    int srcLoc, destLoc, expectedSize, srcSize;
	unsigned char *cmap = info->cmap;
	unsigned char *srcData, *tileData, *totalData;
	BOOL finished;
    
    int tempIntString[16];

	// Determine the source's samples per pixel
    fread(tempIntString, sizeof(int), 3, file); // read width, height, bpp
    fix_endian_read(tempIntString, 3);
    
	destSPP = tempIntString[2];
	srcSPP = destSPP;
    
    oldOffset = [self readOffset:file]; // we only ever process the 1st level
    oldOffset+=8; // skip width & height

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
        tileOffset = [self readOffset:file];
        oldOffset = ftell(file);
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
						NSLog(@"Unexpected end-of-file (no compression pixles)");
						free(srcData); free(tileData);
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
						NSLog(@"RLE decompression failed (pixels)");
						free(srcData); free(tileData);
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

static inline int alphaReplaceMerge(int dstOpacity,int srcOpacity)
{
    if (srcOpacity == 255)
        return dstOpacity;
    if (srcOpacity == 0)
        return 0;
    
    return (dstOpacity * srcOpacity)/255;
}

- (BOOL)readMaskPixels:(FILE *)file toData:(unsigned char *)totalData sharedInfo:(SharedXCFInfo *)info
{
	int tilesPerRow = (width % XCF_TILE_WIDTH) ? (width / XCF_TILE_WIDTH + 1) : (width / XCF_TILE_WIDTH);
	int tilesPerColumn = (height % XCF_TILE_HEIGHT) ? (height / XCF_TILE_HEIGHT + 1) : (height / XCF_TILE_HEIGHT);
    
	int tileHeight, tileWidth;
    long tileOffset, oldOffset;
    int srcLoc, destLoc, expectedSize, srcSize, allocSize;
	unsigned char *srcData, *tileData;
	int whichTile = 0, i, j;
	BOOL finished;
    int tempIntString[16];

	// We have no use for the mask's header information (we assume its reasonable)
	if (![self skipMaskHeader:file])
		return NO;
    
    fread(tempIntString, sizeof(int), 3, file); // read width, height, bpp
    fix_endian_read(tempIntString, 3);
    
    oldOffset = [self readOffset:file]; // we only ever process the 1st level
    oldOffset+=8; // skip width & height

	tileData = malloc(XCF_TILE_HEIGHT * XCF_TILE_WIDTH);
			
	do {
		
        // Read the offset of the next tile
        fseek(file, oldOffset, SEEK_SET);
        tileOffset = [self readOffset:file];
        oldOffset = ftell(file);
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
                    CHECK_MALLOC(srcData);
                    
					if (fread(srcData, sizeof(char), expectedSize, file) != expectedSize) {
						// NSRunAlertPanel(@"Unexpected end-of-file", @"The data being loaded has unexpectedly ended, this could be due to an incomplete or corrupted XCF file. As such this file cannot be properly loaded.", @"OK", NULL, NULL);
						NSLog(@"Unexpected end-of-file (no compression mask)");
						free(srcData); free(tileData);
						return NO;
					}
					for (i = 0; i < expectedSize; i++)
						tileData[i] = srcData[i];
					free(srcData);
				
				break;
				case COMPRESS_RLE:
					
					// In case of RLE compression (typical case)...
                    allocSize = (expectedSize * 1.3)+1;
					srcData = malloc(allocSize);
                    CHECK_MALLOC(srcData);
                    srcSize = fread(srcData, sizeof(char), allocSize, file);
					if (!RLEDecompress(tileData, srcData, srcSize, tileWidth, tileHeight, 1)) {
						// NSRunAlertPanel(@"RLE decompression failed", @"The RLE decompression of a certain part of this file failed, this could be due to an incomplete or corrupted XCF file. As such this file cannot be properly loaded.", @"OK", NULL, NULL);
						NSLog(@"RLE decompression failed (mask)");
						free(srcData); free(tileData);
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
                    totalData[destLoc + (spp - 1)] = alphaReplaceMerge(totalData[destLoc + (spp-1)],tileData[srcLoc]);
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
	long maskOffset, pixelsOffset;
	
	// Determine relevant file positions
    
    pixelsOffset = [self readOffset:file];
    maskOffset = [self readOffset:file];
    
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

- (id)initWithFile:(FILE *)file offset:(long)offset document:(id)doc sharedInfo:(SharedXCFInfo *)info
{
	// int i;
	
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return NULL;
    
    @try {
    
        version = info->version;
        
        // Go to the given offset
        fseek(file, offset, SEEK_SET);
        
        // NSLog(@"Layer Header Begin: %d", ftell(file));
        
        // Read the header
        if ([self readHeader:file] == NO) {
            return NULL;
        }
        
        if(width<=0 || height <=0) {
            return NULL;
        }
        
        // NSLog(@"Layer Properties Begin: %d", ftell(file));
        
        // Read the properties
        if ([self readProperties:file sharedInfo:info] == NO) {
            return NULL;
        }
        
        // NSLog(@"Layer Properties End: %d", ftell(file));
        
        // Read the body
        if ([self readBody:file sharedInfo:info] == NO) {
            return NULL;
        }
        
        hasAlpha = YES;

        return self;
    }
    @catch (NSException *exception) {
        NSMutableDictionary * info = [NSMutableDictionary dictionary];
        [info setValue:exception.name forKey:@"ExceptionName"];
        [info setValue:exception.reason forKey:@"ExceptionReason"];
        [info setValue:exception.callStackReturnAddresses forKey:@"ExceptionCallStackReturnAddresses"];
        [info setValue:exception.callStackSymbols forKey:@"ExceptionCallStackSymbols"];
        [info setValue:exception.userInfo forKey:@"ExceptionUserInfo"];
        [info setValue:@"Error reading XCF file. Please report to the developer using 'Help->Report A Problem' and attach the file." forKey:NSLocalizedRecoverySuggestionErrorKey];
        [info setValue:exception.reason forKey:NSLocalizedFailureReasonErrorKey];

        NSError *error = [[NSError alloc] initWithDomain:@"Seashore" code:100 userInfo:info];
        [[NSAlert alertWithError:error] runModal];
        return NULL;
    }
}

@end

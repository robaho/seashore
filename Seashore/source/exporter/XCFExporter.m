#import "XCFExporter.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "SeaController.h"
#import "SeaWarning.h"
#import "RLE.h"

@implementation XCFExporter

static inline void fix_endian_write(int *input, int size)
{
#ifdef __LITTLE_ENDIAN__
	int i;
	
	for (i = 0; i < size; i++) {
		input[i] = htonl(input[i]);
	}
#endif
}

- (BOOL)hasOptions
{
	return NO;
}

- (IBAction)showOptions:(id)sender
{
}

- (NSString *)title
{
	return @"GIMP image";
}

- (NSString *)extension
{
	return @"xcf";
}

- (BOOL)writeHeader:(FILE *)file
{
	int i;
	id contents = [document contents];
	
	// Start with lowest version possible
	version = 0;
		
	// Determine if file must be version 2 - we don't match exactly with 1.3.x but I think we have it correct
	for (i = 0; i < [contents layerCount]; i++) {
		switch ([(SeaLayer *)[contents layer:i] mode]) {
			case XCF_DODGE_MODE:
			case XCF_BURN_MODE:
			case XCF_HARDLIGHT_MODE:
			case XCF_SOFTLIGHT_MODE:
			case XCF_GRAIN_EXTRACT_MODE:
			case XCF_GRAIN_MERGE_MODE:
				if (version < 2)
					version = 2;
			break;
		}
	}
	if (version == 2)
		[[SeaController seaWarning] addMessage:LOCALSTR(@"compatibility (gimp) message", @"This file contains layer modes which will not be recognized by the GIMP 1.2 series and earlier.") level:kVeryLowImportance];

	
	// Write the correct signature to file according to the version
	if (version > 0) {
		fprintf(file, "gimp xcf v%03d", version);
		fputc(0, file);
	}
	else {
		fprintf(file, "gimp xcf file");
		fputc(0, file);
	}
	
	// Write the width, height and type to file
	tempIntString[0] = [(SeaContent *)contents width];
	tempIntString[1] = [(SeaContent *)contents height];
	tempIntString[2] = [(SeaContent *)contents type];
	fix_endian_write(tempIntString, 3);
	fwrite(tempIntString, sizeof(int), 3, file);
	
	// Check for any problems
	if (ferror(file))
		return NO;
		
	return YES;
}

- (BOOL)writeProperties:(FILE *)file
{
	id contents = [document contents];
	int offsetPos, count, size, i;
	ParasiteData *parasites;
	ParasiteData parasite;
	
	// Write compression
	tempIntString[0] = PROP_COMPRESSION;
	tempIntString[1] = sizeof(char);
	fix_endian_write(tempIntString, 2);
	fwrite(tempIntString, sizeof(int), 2, file);
	fputc(COMPRESS_RLE, file);
	
	// Write resolution
	tempIntString[0] = PROP_RESOLUTION;
	tempIntString[1] = sizeof(float) * 2;
	fix_endian_write(tempIntString, 2);
	fwrite(tempIntString, sizeof(int), 2, file);
	((float *)tempString)[0] = (float)[contents xres];
	((float *)tempString)[1] = (float)[contents yres];
	fwrite(tempString, sizeof(float), 2, file);
	
	// Write parasites
	count = [contents parasites_count];
	if (count > 0) {
		tempIntString[0] = PROP_PARASITES;
		tempIntString[1] = 0;
		fix_endian_write(tempIntString, 2);
		fwrite(tempIntString, sizeof(int), 2, file);
		offsetPos = ftell(file);
		parasites = [contents parasites];
		for (i = 0; i < count; i++) {
			parasite = parasites[i];
			tempIntString[0] = strlen([parasite.name UTF8String]) + 1;
			fix_endian_write(tempIntString, 1);
			fwrite(tempIntString, sizeof(int), 1, file);
			fwrite([parasite.name UTF8String], sizeof(char), strlen([parasite.name UTF8String]) + 1, file);
			tempIntString[0] = parasite.flags;
			tempIntString[1] = parasite.size;
			fix_endian_write(tempIntString, 2);
			fwrite(tempIntString, sizeof(int), 2, file);
			if (parasite.size > 0) {
				fwrite(parasite.data, sizeof(char), parasite.size, file);
			}
		}
		size = ftell(file) - offsetPos;
		fseek(file, -size - sizeof(int), SEEK_CUR);
		tempIntString[0] = size;
		fix_endian_write(tempIntString, 1);
		fwrite(tempIntString, sizeof(int), 1, file);
		fseek(file, size, SEEK_CUR);
	}
	
	// Write the lost properties
	if ([contents lostprops])
		fwrite([contents lostprops], sizeof(char), [contents lostprops_len], file);
	
	// Write that the properties have finished
	tempIntString[0] = PROP_END;
	tempIntString[1] = 0;
	fix_endian_write(tempIntString, 2);
	fwrite(tempIntString, sizeof(int), 2, file);
		
	// Check for any problems
	if (ferror(file))
		return NO;
	
	return YES;
}

- (BOOL)writeLayerHeader:(int)index file:(FILE *)file
{
	id contents = [document contents];
	id layer = [contents layer:index];

	// Write the width, height and type of the layer
	tempIntString[0] = [(SeaLayer *)layer width];
	tempIntString[1] = [(SeaLayer *)layer height];
	tempIntString[2] = ([(SeaContent *)contents spp] == 4) ? GIMP_RGBA_IMAGE : GIMP_GRAYA_IMAGE;
	fix_endian_write(tempIntString, 3);
	fwrite(tempIntString, sizeof(int), 3, file);
	
	// Write the name of the layer
	if ([layer name]) {
		tempIntString[0] = strlen([[layer name] UTF8String]) + 1;
		fix_endian_write(tempIntString, 1);
		fwrite(tempIntString, sizeof(int), 1, file);
		fwrite([[layer name] UTF8String], sizeof(char), strlen([[layer name] UTF8String]) + 1, file);
	}
	else {
		tempIntString[0] = 0;
		fix_endian_write(tempIntString, 1);
		fwrite(tempIntString, sizeof(int), 1, file);
	}
	// Check for any problems
	if (ferror(file))
		return NO;
		
	return YES;
}

- (BOOL)writeLayerProperties:(int)index file:(FILE *)file
{
	id layer = [[document contents] layer:index];
	
	// Write if the layer is the acitve layer
	if ([[document contents] activeLayerIndex] == index) {
		tempIntString[0] = PROP_ACTIVE_LAYER;
		tempIntString[1] = 0;
		fix_endian_write(tempIntString, 2);
		fwrite(tempIntString, sizeof(int), 2, file);
	}
	
	// Write if the layer is floating
	if ([layer floating]) {
		floatingFiller = ftell(file) + 2 * sizeof(int);
		tempIntString[0] = PROP_FLOATING_SELECTION;
		tempIntString[1] = sizeof(int);
		tempIntString[2] = 0;
		fix_endian_write(tempIntString, 3);
		fwrite(tempIntString, sizeof(int), 3, file);
	}
	
	// Write the layer's opacity
	tempIntString[0] = PROP_OPACITY;
	tempIntString[1] = sizeof(int);
	tempIntString[2] = [(SeaLayer*)layer opacity];
	fix_endian_write(tempIntString, 3);
	fwrite(tempIntString, sizeof(int), 3, file);
	
	// Write the layer's visibility
	tempIntString[0] = PROP_VISIBLE;
	tempIntString[1] = sizeof(int);
	tempIntString[2] = [layer visible];
	fix_endian_write(tempIntString, 3);
	fwrite(tempIntString, sizeof(int), 3, file);
	
	// Write the whether or not the layer is linked
	tempIntString[0] = PROP_LINKED;
	tempIntString[1] = sizeof(int);
	tempIntString[2] = [layer linked];
	fix_endian_write(tempIntString, 3);
	fwrite(tempIntString, sizeof(int), 3, file);
	
	// Write the layer's offsets
	tempIntString[0] = PROP_OFFSETS;
	tempIntString[1] = sizeof(int) * 2;
	tempIntString[2] = [layer xoff];
	tempIntString[3] = [layer yoff];
	fix_endian_write(tempIntString, 4);
	fwrite(tempIntString, sizeof(int), 4, file);
	
	// Write the layer's mode
	tempIntString[0] = PROP_MODE;
	tempIntString[1] = sizeof(int);
	tempIntString[2] = [(SeaLayer *)layer mode];
	fix_endian_write(tempIntString, 3);
	fwrite(tempIntString, sizeof(int), 3, file);

	// Write the layer's lost properties
	if ([layer lostprops])
		fwrite([layer lostprops], sizeof(char), [layer lostprops_len], file);
	
	// Write the layer's end
	tempIntString[0] = PROP_END;
	tempIntString[1] = 0;
	fix_endian_write(tempIntString, 2);
	fwrite(tempIntString, sizeof(int), 2, file);

	// Check for any problems
	if (ferror(file))
		return NO;
		
	return YES;
}

- (BOOL)writeLayerPixels:(int)index file:(FILE *)file
{
	id layer = [[document contents] layer:index];
	int width = [(SeaLayer *)layer width], height = [(SeaLayer *)layer height], spp = [[document contents] spp];
	int tilesPerRow = (width % XCF_TILE_WIDTH) ? (width / XCF_TILE_WIDTH + 1) : (width / XCF_TILE_WIDTH);
	int tilesPerColumn = (height % XCF_TILE_HEIGHT) ? (height / XCF_TILE_HEIGHT + 1) : (height / XCF_TILE_HEIGHT);
	int offsetPos, oldPos, whichTile, i, j, k, tileWidth, tileHeight, tileSize, srcLoc, destLoc, compressedLength;
	unsigned char *totalData, *tileData, *compressedTileData;

	// Direct to the layer's pixels
	tempIntString[0] = ftell(file) + 2 * sizeof(int);
	tempIntString[1] = 0;
	fix_endian_write(tempIntString, 2);
	fwrite(tempIntString, sizeof(int), 2, file);
	
	// Write the layer's width, height and spp
	tempIntString[0] = width;
	tempIntString[1] = height;
	tempIntString[2] = spp;
	tempIntString[3] = ftell(file) + sizeof(int) * 5;
	tempIntString[4] = 0;
	fix_endian_write(tempIntString, 5);
	fwrite(tempIntString, sizeof(int), 5, file);
	
	// Allocate memory for the tile data, point to the total data
	tileData = malloc(XCF_TILE_HEIGHT * XCF_TILE_WIDTH * spp);
	compressedTileData = malloc(XCF_TILE_HEIGHT * XCF_TILE_WIDTH * spp * 1.3 + 1);
	totalData = [(SeaLayer *)layer data];
	
	// Write in our default tile height and width
	tempIntString[0] = width;
	tempIntString[1] = height;
	fix_endian_write(tempIntString, 2);
	fwrite(tempIntString, sizeof(int), 2, file);
	
	// Skip past the offsets
	offsetPos = ftell(file);
	fseek(file, (tilesPerRow * tilesPerColumn + 1) * sizeof(int), SEEK_CUR);
	
	// Write each tile
	for (whichTile = 0; whichTile < tilesPerRow * tilesPerColumn && !ferror(file); whichTile++) {
			
		// Fill in the offset
		oldPos = ftell(file);
		fseek(file, offsetPos + whichTile * sizeof(int), SEEK_SET);
		tempIntString[0] = oldPos;
		fix_endian_write(tempIntString, 1);
		fwrite(tempIntString, sizeof(int), 1, file);
		fseek(file, oldPos, SEEK_SET);
		
		// Determine tile size
		tileWidth =  (whichTile % tilesPerRow == tilesPerRow - 1 && width % XCF_TILE_WIDTH != 0) ? (width % XCF_TILE_WIDTH) : XCF_TILE_WIDTH;
		tileHeight = (whichTile / tilesPerRow == tilesPerColumn - 1 && height % XCF_TILE_HEIGHT != 0) ? (height % XCF_TILE_HEIGHT) : XCF_TILE_HEIGHT;
		tileSize = tileWidth * tileHeight * spp;
		
		// Copy data from totalData to tileData
		for (j = 0; j < tileHeight; j++) {
			for (i = 0; i < tileWidth; i++) {
				srcLoc = (((whichTile % tilesPerRow) * XCF_TILE_WIDTH) + i) * spp + ((whichTile /  tilesPerRow) * XCF_TILE_HEIGHT + j) * width * spp;
				destLoc = (i + j * tileWidth) * spp;
				for (k = 0; k < spp; k++) 
					tileData[destLoc + k] = totalData[srcLoc + k];
			}
		}
		
		// Compress the tile data
		compressedLength = RLECompress(compressedTileData, tileData, tileWidth, tileHeight, spp);
		
		// Write it
		fwrite(compressedTileData, sizeof(char), compressedLength, file);
		
	}
	
	// Write the tile end
	fseek(file, offsetPos + whichTile * sizeof(int), SEEK_SET);
	tempIntString[0] = 0;
	fix_endian_write(tempIntString, 1);
	fwrite(tempIntString, sizeof(int), 1, file);
	
	// Move to the very end of the file for the next step
	fseek(file, 0, SEEK_END);
	
	// Free memory we've assigned to ourselves
	free(tileData);
	free(compressedTileData);
	
	// Check for any problems
	if (ferror(file))
		return NO;
	
	return YES;
}


- (BOOL)writeLayer:(int)index file:(FILE *)file
{	
	int storedOffset;
	
	// If the previous layer was a floating one we need to make some changes
	if (floatingFiller != -1) {
		storedOffset = ftell(file);
		fseek(file, floatingFiller, SEEK_SET);
		tempIntString[0] = storedOffset;
		fix_endian_write(tempIntString, 1);
		fwrite(tempIntString, sizeof(int), 1, file);
		fseek(file, storedOffset, SEEK_SET);
		floatingFiller = -1;
	}
	
	// Write the header
	if ([self writeLayerHeader:index file:file] == NO) {
		return NO;
	}
	
	// Write the properties
	if ([self writeLayerProperties:index file:file] == NO) {
		return NO;
	}
	
	// Write the pixels
	if ([self writeLayerPixels:index file:file] == NO) {
		return NO;
	}

	return YES;
}

- (BOOL)writeDocument:(id)doc toFile:(NSString *)path
{
	FILE *file;
	int i, offsetPos, oldPos, layerCount;
	ParasiteData exifParasite;
	NSString *errorString;
	NSData *exifContainer;
	
	// Remember the document
	document = doc;
	floatingFiller = -1;
	layerCount = [[document contents] layerCount];
		
	// Add EXIF parasite
	if ([[document contents] exifData]) {
		exifContainer = [NSPropertyListSerialization dataFromPropertyList:[[document contents] exifData] format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorString];
		if (exifContainer) {
			exifParasite.name = @"exif-plist";
			exifParasite.flags = 0;
			exifParasite.size = [exifContainer length];
			exifParasite.data = malloc(exifParasite.size);
			memcpy(exifParasite.data, (char *)[exifContainer bytes], exifParasite.size);
			[[document contents] addParasite:exifParasite];
		}
	}	
	
	// Open the file for writing
	file = fopen([path fileSystemRepresentation], "w");
	if (file == NULL) {
		return NO;
	}
	
	// Write the header
	if ([self writeHeader:file] == NO) {
		fclose(file);
		return NO;
	}
	
	// Write the properties
	if ([self writeProperties:file] == NO) {
		fclose(file);
		return NO;
	}
	
	// Skip the offsets to begin with
	offsetPos = ftell(file);
	fseek(file, (layerCount + 2) * sizeof(int), SEEK_CUR);
	
	// Write all layers 
	for (i = 0; i < layerCount; i++) {
	
		// Fill in the offset
		oldPos = ftell(file);
		fseek(file, offsetPos + i * sizeof(int), SEEK_SET);
		tempIntString[0] = oldPos;
		fix_endian_write(tempIntString, 1);
		fwrite(tempIntString, sizeof(int), 1, file);
		fseek(file, oldPos, SEEK_SET);
		
		// Write given layer
		if ([self writeLayer:i file:file] == NO) {
			fclose(file);
			return NO;
		}
	
	}
	
	// Write the layer and channel ends
	fseek(file, offsetPos + i * sizeof(int), SEEK_SET);
	tempIntString[0] = 0;
	tempIntString[1] = 0;
	fix_endian_write(tempIntString, 2);
	fwrite(tempIntString, sizeof(int), 2, file);
	
	// Close the file - we're done
	fclose(file);
	
	// Remove EXIF parasite
	if ([[document contents] exifData]) {
		[[document contents] deleteParasiteWithName:@"exif-plist"];
	}
	
	return YES;
}

@end

#import "XCFImporter.h"
#import "XCFLayer.h"
#import "SeaController.h"
#import "SeaWarning.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "SeaAlignment.h"
#import "SeaOperations.h"

@implementation XCFImporter

static inline void fix_endian_read(int *input, int size)
{
#ifdef __LITTLE_ENDIAN__
	int i;
	
	for (i = 0; i < size; i++) {
		input[i] = ntohl(input[i]);
	}
#endif
}


- (BOOL)readHeader:(FILE *)file
{
	// Check signature
	if (fread(tempString, sizeof(char), 9, file) == 9) {
		if (memcmp(tempString, "gimp xcf", 8))
			return NO;
	}
	else 
		return NO;
	
	// Read the version of the file
	fread(tempString, sizeof(char), 5, file);
	if (memcmp(tempString, "file", 4) == 0)
		version = 0;
	else {
		if (tempString[0] == 'v') {
			version = atoi(&(tempString[1]));
		}
	}
	
	// Read in the width, height and type
	fread(tempIntString, sizeof(int), 3, file);
	fix_endian_read(tempIntString, 2);
	// width = tempIntString[0];
	// height = tempIntString[1];
	type = tempIntString[2];
	
	return YES;
}

- (BOOL)readProperties:(FILE *)file sharedInfo:(SharedXCFInfo *)info
{
	int propType, propSize;
	BOOL finished = NO;
	
	// Keep reading until we're finished or hit an error
	while (!finished && !ferror(file)) {
	
		// Read the property information
		fread(tempIntString, sizeof(int), 2, file);
		fix_endian_read(tempIntString, 2);
		propType = tempIntString[0];
		propSize = tempIntString[1];
		
		// Act appropriately on the property type
		switch (propType) {
			case PROP_END:
				finished = YES;
			break;
			case PROP_COLORMAP:
			
				// Store the color map and complain if we are using the problematic version 0 XCF file
				if (version == 0) {
					return NO;
				}
				else {
					fread(tempIntString, sizeof(int), 1, file);
					fix_endian_read(tempIntString, 1);
					info->cmap_len = (int)tempIntString[0];
					info->cmap = calloc(256 * 3, sizeof(char));
					fread(info->cmap, sizeof(char), info->cmap_len * 3, file);
				}
				
			break;
			case PROP_COMPRESSION:
			
				// Remember the compression
				fread(tempString, sizeof(char), 1, file);
				info->compression = (int)(tempString[0]);
				if (info->compression != COMPRESS_NONE && info->compression != COMPRESS_RLE)
					return NO;
				
			break;
			default:

				// Skip these properties but record them for saving
				fseek(file, propSize, SEEK_CUR);
				
			break;
		}
	}
	
	// If we've had a problem fail
	if (ferror(file))
		return NO;
	
	return YES;
}

- (BOOL)addToDocument:(id)doc contentsOfFile:(NSString *)path
{
	SharedXCFInfo info;
	int layerOffsets, offset;
	FILE *file;
	id layer;
	int i, newType = [(SeaContent *)[doc contents] type];
	NSArray *layers;

	// Clear all links
	[[doc contents] clearAllLinks];

	// Open the file
	file = fopen([path fileSystemRepresentation], "rb");
	if (file == NULL) {
		return NO;
	}
	
	// Read the header
	if ([self readHeader:file] == NO) {
		fclose(file);
		return NO;
	}
	
	// NSLog(@"Properties begin: %d", ftell(file));
	
	// Read properties
	if ([self readProperties:file sharedInfo:&info] == NO) {
		fclose(file);
		return NO;
	}
	
	// NSLog(@"Properties end: %d", ftell(file));
	
	// Provide the type for the layer
	info.type = type;
	
	// Determine the offset for the next layer
	i = 0;
	layerOffsets = ftell(file);
	layers = [NSArray array];
	do {
		fseek(file, layerOffsets + i * sizeof(int), SEEK_SET);
		fread(tempIntString, sizeof(int), 1, file);
		fix_endian_read(tempIntString, 1);
		offset = tempIntString[0];
		// NSLog(@"Layer begins: %d", offset);
		
		// If it exists, move to it
		if (offset != 0) {
			layer = [[XCFLayer alloc] initWithFile:file offset:offset document:doc sharedInfo:&info];
			if (layer == NULL) {
				fclose(file);
				return NO;
			}
			[layer convertFromType:(type == XCF_INDEXED_IMAGE) ? XCF_RGB_IMAGE : type to:newType];
			[layer setLinked:YES];
			layers = [layers arrayByAddingObject:layer];
		}
		
		i++;
	} while (offset != 0);
	
	// Add the layers
	for (i = [layers count] - 1; i >= 0; i--) {
		[[doc contents] addLayerObject:[layers objectAtIndex:i]];
	}
	
	// Close the file
	fclose(file);
	
	// We don't support indexed images any more
	if (type == XCF_INDEXED_IMAGE) {
		type = XCF_RGB_IMAGE;
		free(info.cmap);
	}
	
	// Position the new layer correctly
	[[(SeaOperations *)[doc operations] seaAlignment] centerLayerHorizontally:NULL];
	[[(SeaOperations *)[doc operations] seaAlignment] centerLayerVertically:NULL];
	
	return YES;
}

@end

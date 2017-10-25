#import "XCFContent.h"
#import "XCFLayer.h"

@implementation XCFContent

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
	fix_endian_read(tempIntString, 3);
	width = tempIntString[0];
	height = tempIntString[1];
	type = tempIntString[2];
	
	return YES;
}

- (BOOL)readProperties:(FILE *)file sharedInfo:(SharedXCFInfo *)info
{
	int propType, propSize;
	BOOL finished = NO;
	int lostprops_pos;
	int parasites_start;
	char *nameString;
	int pos, i;
	
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
					//NSRunAlertPanel(LOCALSTR(@"indexed color title", @"Indexed colour not supported"), LOCALSTR(@"indexed color body", @"XCF files using indexed colours are only supported if they are of version 1 or greater. This is because version 0 is known to have certain problems with indexed colours."), LOCALSTR(@"ok", @"OK"), NULL, NULL);
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
			case PROP_RESOLUTION:
				
				// Remember the resolution
				fread(tempString, sizeof(float), 2, file);
				fix_endian_read((int *)tempIntString, 2);
				xres = ((float *)tempString)[0];
				yres = ((float *)tempString)[1];
				
			break;
			case PROP_PARASITES:
			
				// Remember the parasites
				parasites_start = ftell(file);
				while (ftell(file) - parasites_start < propSize && !ferror(file)) {
				
					// Expand list of parasites
					if (parasites_count == 0) {
						parasites_count++;
						parasites = malloc(sizeof(ParasiteData));
					}
					else {
						parasites_count++;
						parasites = realloc(parasites, sizeof(ParasiteData) * parasites_count);
					}
					pos = parasites_count - 1; 
					
					// Remember name
					fread(tempIntString, sizeof(int), 1, file);
					fix_endian_read(tempIntString, 1);
					if (tempIntString[0] > 0) {
						nameString = malloc(tempIntString[0]);
						i = 0;
						do {
							if (i < tempIntString[0]) {
								nameString[i] = fgetc(file);
								i++;
							}
						} while (nameString[i - 1] != 0 && !ferror(file));
						parasites[pos].name = [[NSString alloc] initWithUTF8String:nameString];
						free (nameString);
					}
					else {
						parasites[pos].name = [[NSString alloc] initWithString:@"unnamed"];
					}
					
					// Remember flags and data size
					fread(tempIntString, sizeof(int), 2, file);
					fix_endian_read(tempIntString, 2);
					parasites[pos].flags = tempIntString[0];
					parasites[pos].size = tempIntString[1];
					
					// Remember data
					if (parasites[pos].size > 0) {
						parasites[pos].data = malloc(parasites[pos].size);
						fread(parasites[pos].data, sizeof(char), parasites[pos].size, file);
					}
					
				}
				
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

- (id)initWithContentsOfFile:(NSString *)path;
{
	SharedXCFInfo info;
	int layerOffsets, offset;
	FILE *file;
	id layer;
	int i;
	BOOL maskToAlpha = NO;
	ParasiteData *exifParasite;
	NSString *errorString;
	NSData *exifContainer;
	
	// Initialize superclass first
	if (![super init])
		return NULL;
	
	const char *fsRep = [path fileSystemRepresentation];

	// Open the file
	file = fopen(fsRep, "r");
	if (file == NULL) {
		[self autorelease];
		return NULL;
	}

	// Read the header
	if ([self readHeader:file] == NO) {
		fclose(file);
		[self autorelease];
		return NULL;
	}
	
	// Read properties
	if ([self readProperties:file sharedInfo:&info] == NO) {
		fclose(file);
		[self autorelease];
		return NULL;
	}

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
		
		// If it exists, move to it
		if (offset != 0) {
			layer = [[XCFLayer alloc] initWithFile:file offset:offset sharedInfo:&info];
			if (layer == NULL) {
				fclose(file);
				[layers retain];
				[self autorelease];
				return NULL;
			}
			layers = [layers arrayByAddingObject:layer];
			if (info.active)
				activeLayerIndex = i;
			maskToAlpha = maskToAlpha || info.maskToAlpha;
		}
		
		i++;
	} while (offset != 0);
	[layers retain];
	
	// Check for channels
	fseek(file, layerOffsets + i * sizeof(int), SEEK_SET);
	fread(tempIntString, sizeof(int), 1, file);
	fix_endian_read(tempIntString, 1);
	
	// Close the file
	fclose(file);
	
	// Do some final checks to make sure we're are working with reasonable figures before returning ourselves
	if ( xres < kMinResolution || yres < kMinResolution || xres > kMaxResolution || yres > kMaxResolution)
		xres = yres = 72;
	if (width < kMinImageSize || height < kMinImageSize || width > kMaxImageSize || height > kMaxImageSize) {
		[self autorelease];
		return NULL;
	}
	
	// We don't support indexed images any more
	if (type == XCF_INDEXED_IMAGE) {
		type = XCF_RGB_IMAGE;
		free(info.cmap);
	}

	// Store EXIF data
	exifParasite = [self parasiteWithName:@"exif-plist"];
	if (exifParasite) {
		exifContainer = [NSData dataWithBytesNoCopy:exifParasite->data length:exifParasite->size freeWhenDone:NO];
		exifData = [NSPropertyListSerialization propertyListFromData:exifContainer mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&errorString];
		[exifData retain];
	}
	[self deleteParasiteWithName:@"exif-plist"];
	
	return self;
}

@end

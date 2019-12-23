#import "XCFContent.h"
#import "XCFLayer.h"

#ifndef OTHER_PLUGIN
#import "SeaController.h"
#import "SeaWarning.h"
#import "SeaDocumentController.h"
#endif

@implementation XCFContent

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

+ (BOOL)typeIsEditable:(NSString *)aType
{
#ifdef OTHER_PLUGIN
    return TRUE;
#else
	return [[SeaDocumentController sharedDocumentController] type: aType isContainedInDocType: @"Seashore/GIMP image"];
#endif
}

- (BOOL)readHeader:(FILE *)file
{
    int tempIntString[16];
    char tempString[64];

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
    
    if (version >= 4)
    {
        int precision;
        
        fread(tempIntString, sizeof(int), 1, file);
        fix_endian_read(tempIntString,1);
        precision = tempIntString[0];
        
//        if (version == 4)
//        {
//            switch (precision)
//            {
//                case 0: precision = GIMP_PRECISION_U8_NON_LINEAR;  break;
//                case 1: precision = GIMP_PRECISION_U16_NON_LINEAR; break;
//                case 2: precision = GIMP_PRECISION_U32_LINEAR;     break;
//                case 3: precision = GIMP_PRECISION_HALF_LINEAR;    break;
//                case 4: precision = GIMP_PRECISION_FLOAT_LINEAR;   break;
//                default:
//                    goto hard_error;
//            }
//        }
//        else if (version == 5 || version == 6)
//        {
//            switch (precision)
//            {
//                case 100: precision = GIMP_PRECISION_U8_LINEAR;        break;
//                case 150: precision = GIMP_PRECISION_U8_NON_LINEAR;    break;
//                case 200: precision = GIMP_PRECISION_U16_LINEAR;       break;
//                case 250: precision = GIMP_PRECISION_U16_NON_LINEAR;   break;
//                case 300: precision = GIMP_PRECISION_U32_LINEAR;       break;
//                case 350: precision = GIMP_PRECISION_U32_NON_LINEAR;   break;
//                case 400: precision = GIMP_PRECISION_HALF_LINEAR;      break;
//                case 450: precision = GIMP_PRECISION_HALF_NON_LINEAR;  break;
//                case 500: precision = GIMP_PRECISION_FLOAT_LINEAR;     break;
//                case 550: precision = GIMP_PRECISION_FLOAT_NON_LINEAR; break;
//                default:
//                    goto hard_error;
//            }
//        }
//        else
//        {
//            precision = p;
//        }
    }
    
	return YES;
hard_error:
    return NO;
}

- (BOOL)readProperties:(FILE *)file sharedInfo:(SharedXCFInfo *)info
{
	int propType, propSize;
	BOOL finished = NO;
	long lostprops_pos;
	long parasites_start;
	char *nameString;
	int pos, i;
    
    int tempIntString[16];
    char tempString[64];
	
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
#ifdef OTHER_PLUGIN
                    NSLog( @"indexed color files not supported");
#else
					NSRunAlertPanel(LOCALSTR(@"indexed color title", @"Indexed colour not supported"), LOCALSTR(@"indexed color body", @"XCF files using indexed colours are only supported if they are of version 1 or greater. This is because version 0 is known to have certain problems with indexed colours."), LOCALSTR(@"ok", @"OK"), NULL, NULL);
					return NO;
#endif
				}
				else {
					fread(tempIntString, sizeof(int), 1, file);
					fix_endian_read(tempIntString, 1);
					info->cmap_len = (int)tempIntString[0];
					info->cmap = calloc(256 * 3, sizeof(unsigned char));
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
                        parasites[pos].name = nameString;
					}
					else {
                        parasites[pos].name = strdup("unnamed");
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

- (id)initWithDocument:(id)doc contentsOfFile:(NSString *)path;
{
	SharedXCFInfo info;
	long layerOffsets, offset;
	FILE *file;
	id layer;
	int i;
	BOOL maskToAlpha = NO;
	ParasiteData *exifParasite;
	NSString *errorString;
	NSData *exifContainer;
    
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return NULL;
	
	// Open the file
	file = fopen([path fileSystemRepresentation], "rb");
	if (file == NULL) {
		return NULL;
	}
	
	// Read the header
	if ([self readHeader:file] == NO) {
		fclose(file);
		return NULL;
	}
	
	// Express warning if necessary
    if (version > 2) {
#ifdef OTHER_PLUGIN
        NSLog(LOCALSTR(@"xcf version body", @"The version of the XCF file you are trying to load is not fully supported by this program, loading may fail."));
#else
		NSRunAlertPanel(LOCALSTR(@"xcf version title", @"XCF version not supported"), LOCALSTR(@"xcf version body", @"The version of the XCF file you are trying to load is not fully supported by this program, loading may fail."), LOCALSTR(@"ok", @"OK"), NULL, NULL);
#endif
    }
	
	// NSLog(@"Properties begin: %d", ftell(file));
	
	// Read properties
	if ([self readProperties:file sharedInfo:&info] == NO) {
		fclose(file);
		return NULL;
	}
	
	// NSLog(@"Properties end: %d", ftell(file));
	
	// Provide the type for the layer
	info.type = type;
	
	// Determine the offset for the next layer
	i = 0;
	layerOffsets = ftell(file);
	layers = [NSArray array];
    
    int offsetSize = 4;
    if(version>=11){
        offsetSize=8;
    }
    
    info.version = version;
    
	do {
		fseek(file, layerOffsets + i * offsetSize, SEEK_SET);
        offset = [self readOffset:file];
		// NSLog(@"Layer begins: %d", offset);
		
		// If it exists, move to it
		if (offset != 0) {
			layer = [[XCFLayer alloc] initWithFile:file offset:offset document:doc sharedInfo:&info];
			if (layer == NULL) {
				fclose(file);
				return NULL;
			}
			layers = [layers arrayByAddingObject:layer];
			if (info.active)
				activeLayerIndex = i;
			maskToAlpha = maskToAlpha || info.maskToAlpha;
		}
		
		i++;
	} while (offset != 0);
	
	// Check for channels
	fseek(file, layerOffsets + i * offsetSize, SEEK_SET);
    if ([self readOffset:file] != 0) {
#ifndef OTHER_PLUGIN
		[[SeaController seaWarning] addMessage:LOCALSTR(@"channels message", @"This XCF file contains channels which are not currently supported by Seashore. These channels will be lost upon saving.") forDocument: doc level:kHighImportance];
#endif
	}
	
	// Close the file
	fclose(file);
	
	// Do some final checks to make sure we're are working with reasonable figures before returning ourselves
	if ( xres < kMinResolution || yres < kMinResolution || xres > kMaxResolution || yres > kMaxResolution)
		xres = yres = 72;
	if (width < kMinImageSize || height < kMinImageSize || width > kMaxImageSize || height > kMaxImageSize) {
		return NULL;
	}
	
	// We don't support indexed images any more
	if (type == XCF_INDEXED_IMAGE) {
		type = XCF_RGB_IMAGE;
		free(info.cmap);
	}
	
	// Inform user if we've composited the mask to the alpha channel
	if (maskToAlpha) {
#ifndef OTHER_PLUGIN
		[[SeaController seaWarning] addMessage:LOCALSTR(@"mask-to-alpha message", @"Some of the masks in this image have been composited to their layer's alpha channel. These masks will be lost upon saving.") forDocument: doc level:kHighImportance];
#endif
	}
	
	// Store EXIF data
	exifParasite = [self parasiteWithName:"exif-plist"];
	if (exifParasite) {
		exifContainer = [NSData dataWithBytesNoCopy:exifParasite->data length:exifParasite->size freeWhenDone:NO];
		exifData = [NSPropertyListSerialization propertyListFromData:exifContainer mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&errorString];
	}
	[self deleteParasiteWithName:"exif-plist"];
	
	return self;
}

@end

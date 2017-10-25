#import "PNGExporter.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import <PNG/png.h>
#import <zlib.h>

static unsigned char *cmData;
static unsigned int cmLen;

static OSErr getcm(SInt32 command, SInt32 *size, void *data, void *refCon)
{
	if (cmData == NULL) {
		cmData = malloc(*size);
		memcpy(cmData, data, *size);
		cmLen = *size;
	}
	else {
		cmData = realloc(cmData, cmLen + *size);
		memcpy(&(cmData[cmLen]), data, *size);
		cmLen += *size;
	}
	
	return 0;
}

@implementation PNGExporter

- (id)init
{	
	if ([gUserDefaults objectForKey:@"png interlace"] == NULL) {
		interlace = NO;
	}
	else {
		interlace = [gUserDefaults boolForKey:@"png interlace"];
	}
	
	if ([gUserDefaults objectForKey:@"png ICC"] == NULL) {
		ICC = YES;
	}
	else {
		ICC = [gUserDefaults boolForKey:@"png ICC"];
	}
	
	return self;
}

- (void)dealloc
{
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
	return @"PNG";
}

- (NSString *)name
{
	return @"Portable Network Graphics Image";
}

- (NSString *)extension
{
	return @"png";
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
	FILE *file;
	png_structp png_ptr;
	png_infop info_ptr;
	int i, j, width, height, spp, xres, yres;
	int interlace_type, color_type;
	unsigned char *srcData, *destData;
	BOOL hasAlpha;
	CMProfileRef cmProfile;
	Boolean cmmNotFound;
	png_bytep *rows;
	
	// Open the file for writing
	file = fopen([path fileSystemRepresentation], "wb");
	if (file == NULL) {
		return NO;
	}
	
	// Create the PNG structures
	png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	if (!png_ptr) {
		return NO;
	}
	info_ptr = png_create_info_struct(png_ptr);
	if (!info_ptr) {
		png_destroy_write_struct(&png_ptr, NULL);
		fclose(file);
		return NO;
	}
	
	// In case of error return here
	if (setjmp(png_jmpbuf(png_ptr))) {
       png_destroy_write_struct(&png_ptr, &info_ptr);
       fclose(file);
       return NO;
    }
	
	// Set file for writing
	png_init_io(png_ptr, file);
	
	// We want the best compression
	png_set_compression_level(png_ptr, Z_BEST_COMPRESSION);
	
	// Get the data to write
	srcData = [(SeaWhiteboard *)[document whiteboard] data];
	width = [(SeaContent *)[document contents] width];
	height = [(SeaContent *)[document contents] height];
	spp = [(SeaContent *)[document contents] spp];
	xres = [[document contents] xres];
	yres = [[document contents] yres];
	
	// Determine whether or not an alpha channel would be redundant
	hasAlpha = NO;
	for (i = 0; i < width * height && hasAlpha == NO; i++) {
		if (srcData[(i + 1) * spp - 1] != 255)
			hasAlpha = YES;
	}
	
	// Strip the alpha channel if necessary
	if (!hasAlpha) {
		spp--;
		destData = malloc(width * height * spp);
		for (i = 0; i < width * height; i++) {
			for (j = 0; j < spp; j++)
				destData[i * spp + j] = srcData[i * (spp + 1) + j];
		}
	}
	else
		destData = srcData;
	
	// Determine variables for saving
	switch (spp) {
		case 1:
			color_type = PNG_COLOR_TYPE_GRAY;
		break;
		case 2:
			color_type = PNG_COLOR_TYPE_GRAY_ALPHA;
		break;
		case 3:
			color_type = PNG_COLOR_TYPE_RGB;
		break;
		case 4:
			color_type = PNG_COLOR_TYPE_RGB_ALPHA;
		break;
	}
	interlace_type = (interlace) ? PNG_INTERLACE_ADAM7 : PNG_INTERLACE_NONE;
	
	// Save intelligently
	png_set_IHDR(png_ptr, info_ptr, width, height, 8, color_type, interlace_type, PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
	png_set_pHYs(png_ptr, info_ptr, xres * 39.37, yres * 39.37, PNG_RESOLUTION_METER);
	rows = malloc(height * sizeof(png_bytep));
	for (i = 0; i < height; i++)
		rows[i] = &(destData[width * spp * i]);
	png_set_rows(png_ptr, info_ptr, rows);
	free(rows);
	
	// Embed ColorSync profile
	if (NO) {
		CMGetDefaultProfileBySpace((spp < 3) ? cmGrayData : cmRGBData, &cmProfile);
		cmData = NULL;
		CMFlattenProfile(cmProfile, 0, (CMFlattenUPP)&getcm, NULL, &cmmNotFound);
		if (cmData) {
			png_set_iCCP(png_ptr, info_ptr, "", PNG_COMPRESSION_TYPE_BASE, cmData, cmLen);
			free(cmData);
		}
	}
	
	// Write out the PNG file
	png_write_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY, NULL);
	
	// Clean up after ourselves
   png_destroy_write_struct(&png_ptr, &info_ptr);
   fclose(file);
	if (destData != srcData)
		free(destData);
	
	return YES;
}

@end

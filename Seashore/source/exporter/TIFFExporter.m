#import "TIFFExporter.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "Bitmap.h"
#import <TIFF/tiff.h>
#import <TIFF/tiffio.h>

static unsigned char *cmData;
static int cmLen;
static BOOL cmOkay;

enum {
   openReadSpool = 1,	/* start read data process */
   openWriteSpool= 2,	/* start write data process */
   readSpool   = 3,		/* read specified number of bytes */
   writeSpool  = 4,		/* write specified number of bytes */
   closeSpool  = 5		/* complete data transfer process */
}; 

static OSErr getcm(SInt32 command, SInt32 *size, void *data, void *refCon)
{
	if (command == openWriteSpool) {
		cmData = malloc(*size);
		memcpy(cmData, data, *size);
		cmLen = *size;
	}
	else if (command == writeSpool) {
		cmData = realloc(cmData, cmLen + *size);
		memcpy(&(cmData[cmLen]), data, *size);
		cmLen += *size;
	}
	else if (command == closeSpool) {
		cmOkay = YES;
	}
	
	return 0;
}

@implementation TIFFExporter

- (id)init
{
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (BOOL)hasOptions
{
	return YES;
}

- (IBAction)showOptions:(id)sender
{
	// Work things out
	if ([[idocument contents] cmykSave])
		[targetRadios selectCellAtRow:1 column:0];
	else
		[targetRadios selectCellAtRow:0 column:0];
	
	// Display the options dialog
	[panel center];
	[NSApp runModalForWindow:panel];
	[panel orderOut:self];
}

- (IBAction)targetChanged:(id)sender
{
	switch ([targetRadios selectedRow]) {
		case 0:
			[[idocument contents] setCMYKSave:NO];
		break;
		case 1:
			[[idocument contents] setCMYKSave:YES];
		break;
	}
}

- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

- (NSString *)title
{
	return @"TIFF image";
}

- (NSString *)extension
{
	return @"tiff";
}

- (NSString *)optionsString
{
	if ([[idocument contents] cmykSave])
		return @"CMYK";
	else
		return @"RGB/RGBA";
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
	int i, j, width, height, spp, xres, yres, linebytes;
	unsigned char *srcData, *tempData, *destData, *buf;
	//NSBitmapImageRep *imageRep;
	BOOL hasAlpha = NO;
	CMProfileRef cmProfile;
	CMProfileRef srcProf, destProf;
	CMWorldRef cw;
	Boolean cmmNotFound;
	CMBitmap srcBitmap, destBitmap;
	TIFF *tiff;

	// Get the data to write
	srcData = [(SeaWhiteboard *)[document whiteboard] data];
	width = [(SeaContent *)[document contents] width];
	height = [(SeaContent *)[document contents] height];
	spp = [(SeaContent *)[document contents] spp];
	xres = [[document contents] xres];
	yres = [[document contents] yres];
	
	// Determine whether or not an alpha channel would be redundant
	for (i = 0; i < width * height && hasAlpha == NO; i++) {
		if (srcData[(i + 1) * spp - 1] != 255)
			hasAlpha = YES;
	}
	
	// Behave differently if we are targeting a CMYK file
	if ([[document contents] cmykSave] && spp == 4) {
	
		// Strip the alpha channel
		tempData = malloc(width * height * 3);
		stripAlphaToWhite(spp, tempData, srcData, width * height);
		spp--;
		
		// Establish the color world
		OpenDisplayProfile(&srcProf);
		CMGetDefaultProfileBySpace(cmCMYKData, &destProf);
		NCWNewColorWorld(&cw, srcProf, destProf);

		// Define the source
		srcBitmap.image = (char *)tempData;
		srcBitmap.width = width;
		srcBitmap.height = height;
		srcBitmap.rowBytes = width * 3;
		srcBitmap.pixelSize = 8 * 3;
		srcBitmap.space = cmRGB24Space;
	
		// Define the destination
		destBitmap = srcBitmap;
		destData = malloc(width * height * 4);
		destBitmap.image = (char *)destData;
		destBitmap.rowBytes = width * 4;
		destBitmap.pixelSize = 8 * 4;
		destBitmap.space = cmCMYK32Space;
			
		// Execute the conversion
		CWMatchBitmap(cw, &srcBitmap, NULL, 0, &destBitmap);
		
		// Clean up after ourselves
		if (cw) CWDisposeColorWorld(cw);
		free(tempData);
		CloseDisplayProfile(srcProf);
		
		// Embed ColorSync profile
		cmData = NULL;
		cmOkay = NO;
		CMFlattenProfile(destProf, 0, (CMFlattenUPP)&getcm, NULL, &cmmNotFound);
		
		// Open the file for writing
		tiff = TIFFOpen([path fileSystemRepresentation], "w");
		
		// Write the data
		TIFFSetField(tiff, TIFFTAG_IMAGEWIDTH, (uint32)width);
		TIFFSetField(tiff, TIFFTAG_IMAGELENGTH, (uint32)height);
		TIFFSetField(tiff, TIFFTAG_ORIENTATION, ORIENTATION_TOPLEFT);
		TIFFSetField(tiff, TIFFTAG_SAMPLESPERPIXEL, 4);
		TIFFSetField(tiff, TIFFTAG_BITSPERSAMPLE, 8);
		TIFFSetField(tiff, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
		TIFFSetField(tiff, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_SEPARATED);
		TIFFSetField(tiff, TIFFTAG_INKSET, INKSET_CMYK);
		TIFFSetField(tiff, TIFFTAG_COMPRESSION, COMPRESSION_LZW);
		TIFFSetField(tiff, TIFFTAG_PREDICTOR, PREDICTOR_HORIZONTAL);
		TIFFSetField(tiff, TIFFTAG_XRESOLUTION, (float)xres);
		TIFFSetField(tiff, TIFFTAG_YRESOLUTION, (float)yres);
		TIFFSetField(tiff, TIFFTAG_RESOLUTIONUNIT, RESUNIT_INCH);
		TIFFSetField(tiff, TIFFTAG_SOFTWARE, "Seashore 0.2.0");
		if (cmOkay) TIFFSetField(tiff, TIFFTAG_ICCPROFILE, cmLen, cmData);
		TIFFSetField(tiff, TIFFTAG_ROWSPERSTRIP, (width * 4 * height > 8192) ? (8192 / (width * 4) + 1) : height);
		linebytes = 4 * width;
		if (TIFFScanlineSize(tiff) > linebytes) {
			buf = (unsigned char *)malloc(TIFFScanlineSize(tiff));
			memset(buf, 0, TIFFScanlineSize(tiff));
		}
		else {
			buf = (unsigned char *)malloc(linebytes);
		}
		for (i = 0; i < height; i++) {
			memcpy(buf, &(destData[width * 4 * i]), linebytes);
			if (TIFFWriteScanline(tiff, buf, i, 0) < 0) {
				if (destData != srcData) free(destData);
				return NO;
			}
		}
		
		// Close the file
		TIFFClose(tiff);
		free(buf);
		if (cmData) { free(cmData); }
		
	}
	else {
		
		// Strip the alpha channel if necessary
		if (!hasAlpha) {
			spp--;
			destData = malloc(width * height * spp);
			for (i = 0; i < width * height; i++) {
				for (j = 0; j < spp; j++)
					destData[i * spp + j] = srcData[i * (spp + 1) + j];
			}
		}
		else {
			destData = malloc(width * height * spp);
			unpremultiplyBitmap(spp, destData, srcData, width * height);
		}
		
		// Get embedded ColorSync profile
		if (spp < 3)
			CMGetDefaultProfileBySpace(cmGrayData, &cmProfile);
		else
			OpenDisplayProfile(&cmProfile);
		cmData = NULL;
		cmOkay = NO;
		CMFlattenProfile(cmProfile, 0, (CMFlattenUPP)&getcm, NULL, &cmmNotFound);
		
		// Open the file for writing
		tiff = TIFFOpen([path fileSystemRepresentation], "w");
		
		// Write the data
		TIFFSetField(tiff, TIFFTAG_IMAGEWIDTH, (uint32)width);
		TIFFSetField(tiff, TIFFTAG_IMAGELENGTH, (uint32)height);
		TIFFSetField(tiff, TIFFTAG_ORIENTATION, ORIENTATION_TOPLEFT);
		TIFFSetField(tiff, TIFFTAG_SAMPLESPERPIXEL, spp);
		TIFFSetField(tiff, TIFFTAG_BITSPERSAMPLE, 8);
		TIFFSetField(tiff, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
		if (spp < 3)
			TIFFSetField(tiff, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_MINISBLACK);
		else
			TIFFSetField(tiff, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_RGB);
		TIFFSetField(tiff, TIFFTAG_COMPRESSION, COMPRESSION_LZW);
		TIFFSetField(tiff, TIFFTAG_PREDICTOR, PREDICTOR_HORIZONTAL);
		TIFFSetField(tiff, TIFFTAG_XRESOLUTION, (float)xres);
		TIFFSetField(tiff, TIFFTAG_YRESOLUTION, (float)yres);
		TIFFSetField(tiff, TIFFTAG_RESOLUTIONUNIT, RESUNIT_INCH);
		TIFFSetField(tiff, TIFFTAG_SOFTWARE, "Seashore 0.1.9");
		if (cmOkay) TIFFSetField(tiff, TIFFTAG_ICCPROFILE, cmLen, cmData);
		TIFFSetField(tiff, TIFFTAG_ROWSPERSTRIP, (width * spp * height > 8192) ? (8192 / (width * spp) + 1) : height);
		linebytes = spp * width;
		if (TIFFScanlineSize(tiff) > linebytes) {
			buf = (unsigned char *)malloc(TIFFScanlineSize(tiff));
			memset(buf, 0, TIFFScanlineSize(tiff));
		}
		else {
			buf = (unsigned char *)malloc(linebytes);
		}
		for (i = 0; i < height; i++) {
			memcpy(buf, &(destData[width * spp * i]), linebytes);
			if (TIFFWriteScanline(tiff, buf, i, 0) < 0) {
				if (destData != srcData) free(destData);
				return NO;
			}
		}
		
		// Close the file
		TIFFClose(tiff);
		free(buf);
		if (cmData) { free(cmData); }
		if (spp >= 3) CloseDisplayProfile(cmProfile);
		
	}
	
	// If the destination data is not equivalent to the source data free the former
	if (destData != srcData)
		free(destData);
	
	return YES;
}

@end

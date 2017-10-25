#import "JPEGExporter.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "Bitmap.h"
#import "SeaDocument.h"
#import "Bitmap.h"

static unsigned char *cmData;
static unsigned int cmLen;

static BOOL JPEGReviseResolution(unsigned char *input, unsigned int len, int xres, int yres)
{
	int dataPos;
	short *temp;
	unsigned short xress, yress;
	
	for (dataPos = 0; dataPos < len; dataPos++) {
		if (input[dataPos] == 'J') {
			if (memcmp(&(input[dataPos]), "JFIF\x00\x01", 6) == 0) {
				dataPos = dataPos + 7;
				xress = xres;
				yress = yres;
				xress = htons(xress);
				yress = htons(yress);
				input[dataPos] = 0x01;
				dataPos++;
				temp = (short *)&(input[dataPos]);
				temp[0] = xress;
				temp[1] = yress;
				return YES;
			}
		}
	}
	
	return NO;
}

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

@implementation JPEGExporter

- (id)init
{
	int value;
	
	if ([gUserDefaults objectForKey:@"jpeg target"] == NULL)
		targetWeb = YES;
	else
		targetWeb = [gUserDefaults boolForKey:@"jpeg target"];
	
	if ([gUserDefaults objectForKey:@"jpeg web compression"] == NULL) {
		value = 26;
	}
	else {
		value = [gUserDefaults integerForKey:@"jpeg web compression"];
		if (value < 0 || value > kMaxCompression)
			value = 26;
	}
	webCompression = value;
	
	if ([gUserDefaults objectForKey:@"jpeg print compression"] == NULL) {
		value = 30;
	}
	else {
		value = [gUserDefaults integerForKey:@"jpeg print compression"];
		if (value < 0 || value > kMaxCompression)
			value = 30;
	}
	printCompression = value;
	
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

- (float)reviseCompression
{
	float result;
	
	if (targetWeb) {
		if (webCompression < 5) {
			result = 0.1 + 0.08 * (float)webCompression;
		}
		else if (webCompression < 10) {
			result = 0.3 + 0.04 * (float)webCompression;
		}
		else if (webCompression < 20) {
			result = 0.5 + 0.02 * (float)webCompression;
		}
		else {
			result = 0.7 + 0.01 * (float)webCompression;
		}
	}
	else {
		if (printCompression < 5) {
			result = 0.1 + 0.08 * (float)printCompression;
		}
		else if (printCompression < 10) {
			result = 0.3 + 0.04 * (float)printCompression;
		}
		else if (printCompression < 20) {
			result = 0.5 + 0.02 * (float)printCompression;
		}
		else {
			result = 0.7 + 0.01 * (float)printCompression;
		}
	}
	[compressLabel setStringValue:[NSString stringWithFormat:@"Compressed - %d%%", (int)roundf(result * 100.0)]];
	
	return result;
}

- (void)showOptions:(id)document
{
	unsigned char *temp, *data;
	int width = [(SeaContent *)[document contents] width], height = [(SeaContent *)[document contents] height], spp = [[document contents] spp];
	int i, j, k, x, y;
	id realImage, compressImage;
	float value;
	
	// Work things out
	if (targetWeb)
		[targetRadios selectCellAtRow:0 column:0];
	else
		[targetRadios selectCellAtRow:0 column:1];
	
	// Revise the compression
	if (targetWeb)
		[compressSlider setIntValue:webCompression];
	else
		[compressSlider setIntValue:printCompression];
	value = [self reviseCompression];
	
	// Set-up the sample data
	data = [(SeaWhiteboard *)[document whiteboard] data];
	sampleData = malloc(40 * 40 * 3);
	temp = malloc(40 * 40 * 4);
	memset(temp, 0x00, 40 * 40 * 4);
	for (j = 0; j < 40; j++) {
		for (i = 0; i < 40; i++) {
			x = width / 2 - 20 + i;
			y = height / 2 - 20 + j;
			if (x >= 0 && x < width && y >= 0 && y < height) {
				if (spp == 4) {
					for (k = 0; k < 4; k++)
						temp[(j * 40 + i) * 4 + k] = data[(y * width + x) * 4 + k];
				}
				else {
					for (k = 0; k < 3; k++)
						temp[(j * 40 + i) * 4 + k] = data[(y * width + x) * 2];
					temp[(j * 40 + i) * 4 + 3] = data[(y * width + x) * 2 + 1];
				}
			}
		}
	}
	stripAlphaToWhite(4, sampleData, temp, 40 * 40);
	free(temp);
	
	// Now make an image for the view
	realImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&sampleData pixelsWide:40 pixelsHigh:40 bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:40 * 3 bitsPerPixel:8 * 3];
	realImage = [[NSImage alloc] initWithSize:NSMakeSize(160, 160)];
	[realImage addRepresentation:realImageRep];
	[realImageView setImage:realImage];
	compressImage = [[NSImage alloc] initWithData:[realImageRep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]]];
	[compressImage setSize:NSMakeSize(160, 160)];
	[compressImageView setImage:compressImage];
	[compressImage autorelease];
	
	// Display the options dialog
	[panel center];
	[NSApp runModalForWindow:panel];
	[panel orderOut:self];
	
	// Clean-up
	[gUserDefaults setObject:(targetWeb ? @"YES" : @"NO") forKey:@"jpeg target"];
	if (targetWeb)
		[gUserDefaults setInteger:webCompression forKey:@"jpeg web compression"];
	else
		[gUserDefaults setInteger:printCompression forKey:@"jpeg print compression"];
	free(sampleData);
	[realImageRep autorelease];
	[realImage autorelease];
}

- (IBAction)compressionChanged:(id)sender
{
	id compressImage;
	float value;
	
	if (targetWeb)
		webCompression = [compressSlider intValue];
	else
		printCompression = [compressSlider intValue];
	value = [self reviseCompression];
	compressImage = [[NSImage alloc] initWithData:[realImageRep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]]];
	[compressImage setSize:NSMakeSize(160, 160)];
	[compressImage autorelease];
	[compressImageView setImage:compressImage];
	[compressImageView display];
}

- (IBAction)targetChanged:(id)sender
{
	id compressImage;
	float value;
	
	// Determine the target
	if ([targetRadios selectedColumn] == 0)
		targetWeb = YES;
	else
		targetWeb = NO;
	
	// Revise the compression
	if (targetWeb)
		[compressSlider setIntValue:webCompression];
	else
		[compressSlider setIntValue:printCompression];
	value = [self reviseCompression];
	compressImage = [[NSImage alloc] initWithData:[realImageRep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]]];
	[compressImage setSize:NSMakeSize(160, 160)];
	[compressImage autorelease];
	[compressImageView setImage:compressImage];
	[compressImageView display];
}

- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

- (NSString *)title
{
	return @"JPEG image";
}

- (NSString *)extension
{
	return @"jpg";
}

- (NSString *)optionsString
{
	if (targetWeb)
		return [NSString stringWithFormat:@"Web %.0f%%", [self reviseCompression] * 100.0];
	else
		return [NSString stringWithFormat:@"Print %.0f%%", [self reviseCompression] * 100.0];
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
	int width, height, xres, yres, spp;
	unsigned char *srcData, *destData;
	NSBitmapImageRep *imageRep;
	NSData *imageData;
	NSDictionary *exifData;
	CMProfileRef cmProfile;
	Boolean cmmNotFound;
	
	// Get the data to write
	srcData = [(SeaWhiteboard *)[document whiteboard] data];
	width = [(SeaContent *)[document contents] width];
	height = [(SeaContent *)[document contents] height];
	spp = [(SeaContent *)[document contents] spp];
	xres = [[document contents] xres];
	yres = [[document contents] yres];
	
	// Strip the alpha channel if necessary
	destData = malloc(width * height * (spp - 1));
	stripAlphaToWhite(spp, destData, srcData, width * height);
	spp--;
	
	// Make an image representation from the data
	imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&destData pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:NO isPlanar:NO colorSpaceName:(spp > 2) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * spp bitsPerPixel:8 * spp];
	
	// Add EXIF data
	exifData = [[document contents] exifData];
	if (exifData) [imageRep setProperty:@"NSImageEXIFData" withValue:exifData];
	
	// Embed ColorSync profile
	if (!targetWeb) {
		if (spp < 3)
			CMGetDefaultProfileBySpace(cmGrayData, &cmProfile);
		else
			OpenDisplayProfile(&cmProfile);
		cmData = NULL;
		CMFlattenProfile(cmProfile, 0, (CMFlattenUPP)&getcm, NULL, &cmmNotFound);
		if (cmData) {
			[imageRep setProperty:NSImageColorSyncProfileData withValue:[NSData dataWithBytes:cmData length:cmLen]];
			free(cmData);
		}
		if (spp >= 3) CloseDisplayProfile(cmProfile);
	}
	
	// Finally build the JPEG data
	imageData = [imageRep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]];
	
	// Now add in the resolution settings
	// Notice how we are working on [imageData bytes] despite being explicitly told not to in Cocoa's documentation - well if Cocoa gave us proper resolution handling that wouldn't be a problem
	if (!JPEGReviseResolution((unsigned char *)[imageData bytes], [imageData length], xres, yres))
		NSLog(@"The resolution of the current JPEG file could not be saved. This indicates a change in the approach with which Cocoa saves JPEG files. Please contact the author, quoting this log message, for further assistance."); 

	// Save our file and let's go
	[imageData writeToFile:path atomically:YES];
	[imageRep autorelease];
	
	// If the destination data is not equivalent to the source data free the former
	if (destData != srcData)
		free(destData);
	
	return YES;
}

@end

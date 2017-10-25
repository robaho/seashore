#import "BrushDocument.h"

typedef struct {
  unsigned int   header_size;  /*  header_size = sizeof (BrushHeader) + brush name  */
  unsigned int   version;      /*  brush file version #  */
  unsigned int   width;        /*  width of brush  */
  unsigned int   height;       /*  height of brush  */
  unsigned int   bytes;        /*  depth of brush in bytes */
  unsigned int   magic_number; /*  GIMP brush magic number  */
  unsigned int   spacing;      /*  brush spacing  */
} BrushHeader;

#define GBRUSH_MAGIC    (('G' << 24) + ('I' << 16) + ('M' << 8) + ('P' << 0))
#define window [[[self windowControllers] objectAtIndex:0] window]
#define int_mult(a,b,t)  ((t) = (a) * (b) + 0x80, ((((t) >> 8) + (t)) >> 8))

@implementation BrushDocument

- (id)init
{
	// Initialize superclass first
	if (![super init])
		return NULL;
	
	// Set values to suitable default ones
	width = height = 0;
	mask = pixmap = NULL;
	usePixmap = NO;
	spacing = 25;
	name = [NSString stringWithString:@"Untitled"];
	pastNames = [[NSArray alloc] initWithObjects:name, nil];
	[self addToUndoRecords];
	curUndoPos = 0;
	
	return self;
}

- (void)awakeFromNib
{
	// Set interface elements to match brush settings
	[spacingSlider setIntValue:(spacing == 1) ? 0 : spacing];
	[spacingLabel setStringValue:[NSString stringWithFormat:@"Spacing - %d%%", spacing]];
	[nameTextField setStringValue:name];
	if (usePixmap) [typeButton setTitle:@"Type - Full Colour"];
	else [typeButton setTitle:@"Type - Monochrome"];
	[dimensionsLabel setStringValue:[NSString stringWithFormat:@"%d x %d", width, height]];
}

- (void)dealloc
{
	int i;
	
	if (pastNames) [pastNames autorelease];
	if (undoRecords) {
		for (i = 0; i < undoRecordsSize; i++) {
			if (undoRecords[i].mask) free(undoRecords[i].mask);
			if (undoRecords[i].pixmap) free(undoRecords[i].pixmap);
		}
		free(undoRecords);
	}
	
	[super dealloc];
}

- (NSImage *)brushImage
{
	NSBitmapImageRep *tempRep;
	NSImage *brushImage;
	
	// If we have no width or height in the image return NULL
	if (width == 0 || height == 0) return NULL;
	
	// Create the representation
	if (usePixmap)
		tempRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&pixmap pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:width * 4 bitsPerPixel:32];
	else
		tempRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&mask pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSCalibratedBlackColorSpace bytesPerRow:width bitsPerPixel:8];
	
	// Wrap it up in an NSImage
	brushImage = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
	[brushImage addRepresentation:tempRep];
	[tempRep autorelease];
	
	return brushImage;
}

- (void)addToUndoRecords
{
	// Start increasing the undo stack's size
	if (undoRecords == NULL)
		undoRecords = malloc(sizeof(BitmapUndo));
	else
		undoRecords = realloc(undoRecords, sizeof(BitmapUndo) * (undoRecordsSize + 1));
	
	// Fill in the new record on the undo stack
	undoRecords[undoRecordsSize].mask = mask;
	undoRecords[undoRecordsSize].pixmap = pixmap;
	undoRecords[undoRecordsSize].width = width;
	undoRecords[undoRecordsSize].height = height;
	undoRecords[undoRecordsSize].usePixmap = usePixmap;
	
	// Finish increasing the undo stack's size
	undoRecordsSize++;
}

- (BOOL)changeImage:(NSBitmapImageRep *)newImage
{
	BOOL invert, isRGB, useAlpha;
	int i, j, t, spp = [newImage samplesPerPixel];
	unsigned char *data = [newImage bitmapData];
	
	// Check we can handle this image
	if ([newImage bitsPerSample] != 8)
		return NO;
		
	// Fill out isRGB and invert booleans
	if ([[newImage colorSpaceName] isEqualToString:NSCalibratedWhiteColorSpace] || [[newImage colorSpaceName] isEqualToString:NSDeviceWhiteColorSpace]) {
		isRGB = NO; invert = YES;
	} else if ([[newImage colorSpaceName] isEqualToString:NSCalibratedBlackColorSpace] || [[newImage colorSpaceName] isEqualToString:NSDeviceBlackColorSpace]) {
		isRGB = NO; invert = NO;
	} else if ([[newImage colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace] || [[newImage colorSpaceName] isEqualToString:NSDeviceRGBColorSpace]) {
		isRGB = YES; invert = NO;
	} else {
		return NO;
	}
	
	// Fill out useAlpha boolean
	useAlpha = NO;
	if ([newImage hasAlpha]) {
		for (i = 0; i < [newImage size].width * [newImage size].height && !useAlpha; i++) {
			if (data[i * 2 + 1] != 0xFF)
				useAlpha = YES;
		}
	}
	
	// Allow the undo
	[[[self undoManager] prepareWithInvocationTarget:self] undoImageTo:curUndoPos];
	
	// Replace with appropriate values
	usePixmap = isRGB;
	width = [newImage size].width; height = [newImage size].height;
	if (!isRGB) {
		mask = malloc(width * height);
		for (i = 0; i < width * height; i++) {
			if (useAlpha)
				mask[i] = data[i * spp + 1];
			else
				mask[i] = (invert) ? 255 - data[i * spp] : data[i * spp];
		}
		pixmap = malloc(width * height * 4);
		for (i = 0; i < width * height; i++) {
			if (spp == 2) {
				pixmap[i * 4] = pixmap[i * 4 + 1] = pixmap[i * 4 + 2] = int_mult((invert) ? data[i * spp] : 255 - data[i * spp], data[i * spp + 1], t);
				pixmap[i * 4 + 3] = data[i * spp + 1];
			}
			else {
				pixmap[i * 4] = pixmap[i * 4 + 1] = pixmap[i * 4 + 2] = (invert) ? data[i * spp] : 255 - data[i * spp];
				pixmap[i * 4 + 3] = 255;
			}
		}
	}
	else {
		mask = malloc(width * height);
		for (i = 0; i < width * height; i++) {
			if (useAlpha)
				mask[i] = data[i * spp + 3];
			else
				mask[i] = 255 - (unsigned char)(((int)data[i * spp] + (int)data[i * spp + 1] + (int)data[i * spp + 2]) / 3);
		}
		pixmap = malloc(width * height * 4);
		pixmap = memset(pixmap, 255, width * height * 4);
		for (i = 0; i < width * height; i++) {
			for (j = 0; j < spp; j++)
				pixmap[i * 4 + j] = data[i * spp + j];
		}
	}
	
	// Update everything
	[view setNeedsDisplay:YES];
	[dimensionsLabel setStringValue:[NSString stringWithFormat:@"%d x %d", width, height]];
	if (usePixmap) [typeButton setTitle:@"Type - Full Colour"];
	else [typeButton setTitle:@"Type - Monochrome"];
	
	// Add to undo stack
	[self addToUndoRecords];
	curUndoPos = undoRecordsSize - 1;
	
	return YES;
}

- (IBAction)changeName:(id)sender
{
	// Only do the following if the name has actually changed
	if (![name isEqualToString:[nameTextField stringValue]]) {
	
		// Allow the undo
		[[[self undoManager] prepareWithInvocationTarget:self] undoNameTo:name];
		
		// Store new name and remember last names for undo
		name = [NSString stringWithString:[nameTextField stringValue]];
		[pastNames autorelease];
		pastNames = [[pastNames arrayByAddingObject:name] retain];
	
	}
}

- (IBAction)changeSpacing:(id)sender
{
	// Allow the undo
	if ([[NSApp currentEvent] type] == NSLeftMouseDown)
		[[[self undoManager] prepareWithInvocationTarget:self] undoSpacingTo:spacing];
		
	// Adjust the spacing
	spacing = ([spacingSlider intValue] / 5 * 5 == 0) ? 1 : [spacingSlider intValue] / 5 * 5;
	[spacingLabel setStringValue:[NSString stringWithFormat:@"Spacing - %d%%", spacing]];
}

- (IBAction)changeType:(id)sender
{
	// Allow the undo
	[[[self undoManager] prepareWithInvocationTarget:self] changeType:sender];
	
	// Make the changes
	usePixmap = !usePixmap;
	[view setNeedsDisplay:YES];
	if (usePixmap) [typeButton setTitle:@"Type - Full Colour"];
	else [typeButton setTitle:@"Type - Monochrome"];
}

- (BOOL)readFromFile:(NSString *)path ofType:(NSString *)docType
{
	FILE *file;
	BrushHeader header;
	BOOL versionGood = NO;
	char nameString[512];
	int nameLen, tempSize;
	
	// Set variables appropriately
	if (pastNames) [pastNames autorelease];
	if (undoRecords) free(undoRecords);
	undoRecords = NULL;
	undoRecordsSize = curUndoPos = 0;
	
	// Open the brush file
	file = fopen([path cString], "rb");
	if (file == NULL)
		return NO;
		
	// Read in the header
	fread(&header, sizeof(BrushHeader), 1, file);

	// Convert brush header to proper endianess
	header.header_size = ntohl(header.header_size);
	header.version = ntohl(header.version);
	header.width = ntohl(header.width);
	header.height = ntohl(header.height);
	header.bytes = ntohl(header.bytes);
	header.magic_number = ntohl(header.magic_number);
	header.spacing = ntohl(header.spacing);
	
	// Check version compatibility
	versionGood = (header.version == 2 && header.magic_number == GBRUSH_MAGIC);
	versionGood = versionGood || (header.version == 1); 
	if (!versionGood)
		return NO;

	// Accomodate version 1 brushes (no spacing)
	if (header.version == 1) {
		fseek(file, -8, SEEK_CUR);
		header.header_size += 8;
		header.spacing = 25;
	}
	
	// Store information from the header
	width = header.width;
	height = header.height;
	spacing = header.spacing;
	
	// Read in brush name
	nameLen = header.header_size - sizeof(header);
	if (nameLen > 512) { return NO; }
	if (nameLen > 0) {
		fread(nameString, sizeof(char), nameLen, file);
		name = [NSString stringWithUTF8String:nameString];
	}
	else {
		name = [NSString stringWithString:@"Untitled"];
	}
	pastNames = [[NSArray alloc] initWithObjects:name, nil];
	
	// And then read in the important stuff
	switch (header.bytes) {
		case 1:
			usePixmap = NO;
			tempSize = width * height;
			mask = malloc(tempSize);
			if (fread(mask, sizeof(char), tempSize, file) < tempSize) 
				return NO;
		break;
		case 4:
			usePixmap = YES;
			tempSize = width * height * 4;
			pixmap = malloc(tempSize);
			if (fread(pixmap, sizeof(char), tempSize, file) < tempSize)
				return NO;
			premultiplyAlpha(4, pixmap, pixmap, width * height);
		break;
		default:
			return NO;
		break;
	}
	
	// Close the brush file
	fclose(file);
	
	// Add to the stack
	[self addToUndoRecords];
	curUndoPos = 0;
	
	return YES;
}

- (void)undoImageTo:(int)index
{
	// Allow the redo
	[[[self undoManager] prepareWithInvocationTarget:self] undoImageTo:curUndoPos];
	
	// Restore image from undo record
	pixmap = undoRecords[index].pixmap;
	mask = undoRecords[index].mask;
	width = undoRecords[index].width;
	height = undoRecords[index].height;
	usePixmap = undoRecords[index].usePixmap;
	
	// Update everything
	curUndoPos = index;
	[view setNeedsDisplay:YES];
	[dimensionsLabel setStringValue:[NSString stringWithFormat:@"%d x %d", width, height]];
	if (usePixmap) [typeButton setTitle:@"Type - Full Colour"];
	else [typeButton setTitle:@"Type - Monochrome"];
}

- (void)undoNameTo:(NSString *)string
{
	// Allow the redo
	[[[self undoManager] prepareWithInvocationTarget:self] undoNameTo:name];
	
	// Set the new name
	name = string;
	[nameTextField setStringValue:name];
}

- (void)undoSpacingTo:(int)value
{	
	// Allow the redo
	[[[self undoManager] prepareWithInvocationTarget:self] undoSpacingTo:spacing];
		
	// Adjust the spacing
	spacing = value;
	[spacingSlider setIntValue:spacing];
	[spacingLabel setStringValue:[NSString stringWithFormat:@"Spacing - %d%%", spacing]];
}

- (NSString *)windowNibName
{
	return @"BrushDocument";
}

- (BOOL)writeToFile:(NSString *)path ofType:(NSString *)docType
{
	FILE *file;
	BrushHeader header;
	NSString *tempName;
	
	// Open the brush file
	file = fopen([path cString], "wb");
	if (file == NULL)
		return NO;
	
	// Set-up the header
	if ([name length] > 128) tempName = [name substringToIndex:128];
	else tempName = name;
	header.header_size = strlen([name UTF8String]) + 1 + sizeof(header);
	header.version = 2;
	header.width = width;
	header.height = height;
	header.bytes = (usePixmap) ? 4 : 1;
	header.magic_number = GBRUSH_MAGIC;
	header.spacing = spacing;
	
	// Convert brush header to proper endianess
	header.header_size = htonl(header.header_size);
	header.version = htonl(header.version);
	header.width = htonl(header.width);
	header.height = htonl(header.height);
	header.bytes = htonl(header.bytes);
	header.magic_number = htonl(header.magic_number);
	header.spacing = htonl(header.spacing);
	
	// Write the header
	fwrite(&header, sizeof(BrushHeader), 1, file);
	
	// Write down brush name
	fwrite([name UTF8String], sizeof(char), strlen([name UTF8String]), file);
	fputc(0x00, file);
	
	// And then write down the meat of the brush
	if (usePixmap) {
		unpremultiplyBitmap(4, pixmap, pixmap, width * height);
		fwrite(pixmap, sizeof(char), width * height * 4, file);
	}
	else {
		fwrite(mask, sizeof(char), width * height, file);
	}
	
	// Close the brush file
	fclose(file);
	
	return YES;
}

- (IBAction)import:(id)sender
{
	NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
	
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setPrompt:@"Import"];
	[openPanel beginSheetForDirectory:nil file:nil types:[NSArray arrayWithObjects:@"tiff", @"tif", @"jpeg", @"jpg", @"png", nil] modalForWindow:window modalDelegate:self didEndSelector:@selector(importPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	[openPanel autorelease];
}

- (void)importPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	BOOL success;
	
	if (returnCode == NSCancelButton) return;
	success = [self changeImage:[NSBitmapImageRep imageRepWithData:[NSData dataWithContentsOfFile:[[openPanel filenames] objectAtIndex:0]]]];
	if (!success) {
		NSRunAlertPanel(@"Cannot Import", @"Brushed can only import JPEG, PNG and TIFF files with 8-bit RGB channels or an 8-bit Grays channel and optionally an additional alpha channel.", @"Ok", NULL, NULL);
	}
}

- (IBAction)export:(id)sender
{
	NSSavePanel *savePanel = [[NSSavePanel alloc] init];
	
	[savePanel setPrompt:@"Export"];
	[savePanel setRequiredFileType:@"tiff"];
	[savePanel beginSheetForDirectory:nil file:@"Untitled" modalForWindow:window modalDelegate:self didEndSelector:@selector(exportPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	[savePanel autorelease];
}

- (void)exportPanelDidEnd:(NSOpenPanel *)savePanel returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	if (returnCode == NSCancelButton) return;
	[[[self brushImage] TIFFRepresentation] writeToFile:[savePanel filename] atomically:YES];
}

- (IBAction)preSaveDocument:(id)sender
{
	[self changeName:sender];
	[NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(saveDocument:) userInfo:nil repeats:NO];
}

- (IBAction)preSaveDocumentAs:(id)sender
{
	[self changeName:sender];
	[NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(saveDocumentAs:) userInfo:nil repeats:NO];
}

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
	[savePanel setTreatsFilePackagesAsDirectories:YES];
	[savePanel setDirectory:@"/Applications/Seashore.app/Contents/Resources/brushes/"];
	
	return YES;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	switch ([menuItem tag]) {
		case 120:
		case 121:
			if (pixmap == NULL && mask == NULL) return NO;
		break;
	}
	
	return [super validateMenuItem:menuItem];
}

@end

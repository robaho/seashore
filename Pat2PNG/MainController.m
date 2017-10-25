#import "MainController.h"

typedef struct {
  unsigned int	header_size;  	/*  header_size = sizeof(PatternHeader) + pattern name  */
  unsigned int	version;  		/*  pattern file version #  */
  unsigned int	width;			/*  width of pattern  */
  unsigned int	height;			/*  height of pattern  */
  unsigned int	bytes;			/*  depth of pattern in bytes  */
  unsigned int	magic_number;	/*  GIMP pattern magic number  */
} PatternHeader;

#define GPATTERN_MAGIC    (('G' << 24) + ('P' << 16) + ('A' << 8) + ('T' << 0))

@implementation MainController

- (IBAction)run:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	NSArray *types = [NSArray arrayWithObject:@"pat"];
	PatternHeader header;
	char nameString[512];
	int nameLen;
	NSString *path, *name, *colorSpace;
	NSBitmapImageRep *bitmapImage;
	unsigned char *data;
	FILE *file;
	int i, spp;
	
	// Request the file
	[panel setAllowsMultipleSelection:YES];
	[panel runModalForTypes:types];
	
	// Go through each of the files
	for (i = 0; i < [[panel filenames] count]; i++) {
		
		// Get the file name
		path = [[panel filenames] objectAtIndex:i];
		
		// Open the pattern file
		file = fopen([path cString], "rb");
		if (file == NULL)
			continue;
		
		// Read in the header
		fread(&header, sizeof(PatternHeader), 1, file);
			
		// Don't open files with inconsistent header information
		if (header.magic_number != GPATTERN_MAGIC || header.version != 1 || header.header_size <= sizeof(header) || (header.bytes != 1 && header.bytes != 3)) {
			fclose(file);
			continue;
		}
		
		// Read in brush name
		nameLen = header.header_size - sizeof(header);
		if (nameLen > 512) { continue; }
		if (nameLen > 0) {
			fread(nameString, sizeof(char), nameLen, file);
			name = [NSString stringWithUTF8String:nameString];
		}
		else {
			name = [NSString stringWithString:@"Untitled"];
		}
		
		// Get the pattern data
		data = malloc(header.width * header.height * header.bytes);
		fread(data, sizeof(char), header.width * header.height * header.bytes, file);
		
		// Close the pattern file
		fclose(file);
		
		// Make an image based on the pattern data
		if (header.bytes == 3) {
			colorSpace = NSCalibratedRGBColorSpace;
			spp = 3;
		}
		else {
			colorSpace = NSCalibratedWhiteColorSpace;
			spp = 1;
		}
		bitmapImage = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data pixelsWide:header.width pixelsHigh:header.height bitsPerSample:8 samplesPerPixel:spp hasAlpha:NO isPlanar:NO colorSpaceName:colorSpace bytesPerRow:0 bitsPerPixel:0];
		
		// Save the pattern as a PNG file
		[[bitmapImage representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]] writeToFile:[[path stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@.png", name] atomically:YES];
		
		// And finally free everything
		[bitmapImage autorelease];
		free(data);
		
	}
	
}

@end

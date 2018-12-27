#import "SeaTexture.h"
#import "Bitmap.h"

@implementation SeaTexture

- (id)initWithContentsOfFile:(NSString *)path
{
	NSBitmapImageRep *tempBitmapRep;
	int k, j, l;
	BOOL isDir;
	
	// Check if file is a directory
	if ([gFileManager fileExistsAtPath:path isDirectory:&isDir] && isDir) {
		[self autorelease];
		return NULL;
	}
	
	// Get the image
	tempBitmapRep = [NSBitmapImageRep imageRepWithData:[NSData dataWithContentsOfFile:path]];
	width = (int)[tempBitmapRep pixelsWide];
	height = (int)[tempBitmapRep pixelsHigh];

    // convert to RGBA
    unsigned char *dataWithAlpha = convertImageRep(tempBitmapRep,4);
    
	// Allocate space for the greyscale and color textures
	colorTexture = malloc(width * height * 3);
	greyTexture = malloc(width * height);
    
    int bpr = width * 4;
    
    for (j = 0; j < height; j++) {
        for (k = 0; k < width; k++) {
            for (l = 0; l < 3; l++)
                colorTexture[j * width * 3 + k * 3 + l] = dataWithAlpha[j * bpr + k * 4 + l];
        }
    }
    
    for (k = 0; k < width * height; k++) {
        greyTexture[k] = (unsigned char)(((int)(colorTexture[k * 3]) + (int)(colorTexture[k * 3 + 1]) + (int)(colorTexture[k * 3 + 2])) / 3);
    }
    
    free(dataWithAlpha);

	// Remember the texture name
	name = [[[path lastPathComponent] stringByDeletingPathExtension] retain];

	return self;
}

- (void)dealloc
{
	if (colorTexture) free(colorTexture);
	if (greyTexture) free(greyTexture);
	if (name) [name autorelease];
	[super dealloc];
}

- (void)activate
{
}

- (void)deactivate
{
}

- (NSImage *)thumbnail
{
	NSBitmapImageRep *tempRep;
	int thumbWidth, thumbHeight;
	NSImage *thumbnail;
	
	// Determine the thumbnail size
	thumbWidth = width;
	thumbHeight = height;
	if (width > 44 || height > 44) {
		if (width > height) {
			thumbHeight = (int)((float)height * (44.0 / (float)width));
			thumbWidth = 44;
		}
		else {
			thumbWidth = (int)((float)width * (44.0 / (float)height));
			thumbHeight = 44;
		}
	}
	
	// Create the representation
	tempRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&colorTexture pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO isPlanar:NO colorSpaceName:MyRGBSpace bytesPerRow:width * 3 bitsPerPixel:8 * 3];

	// Wrap it up in an NSImage
	thumbnail = [[NSImage alloc] initWithSize:NSMakeSize(thumbWidth, thumbHeight)];
	[thumbnail addRepresentation:tempRep];
	[tempRep autorelease];
	[thumbnail autorelease];
	
	return thumbnail;
}

- (NSString *)name
{
	return name;
}

- (int)width
{
	return width;
}

- (int)height
{
	return height;
}

- (unsigned char *)texture:(BOOL)color
{
	return (color) ? colorTexture : greyTexture;
}

- (NSColor *)textureAsNSColor:(BOOL)color
{
	NSColor *nsColor;
	NSImage *image;
	NSBitmapImageRep *rep;
	
	image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
	
	if (color)
		rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&colorTexture pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO isPlanar:NO colorSpaceName:MyRGBSpace bytesPerRow:width * 3 bitsPerPixel:24];
	else
		rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&greyTexture pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:MyGraySpace bytesPerRow:width bitsPerPixel:8];
	
	[image addRepresentation:rep];
	[image autorelease];
	[rep autorelease];
	
	nsColor = [NSColor colorWithPatternImage:image];
	
	return nsColor;
}

- (NSComparisonResult)compare:(id)other
{
	return [[self name] caseInsensitiveCompare:[other name]];
}

@end

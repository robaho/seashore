#import "SeaBrush.h"
#import <Accelerate/Accelerate.h>

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

#define BrushThumbnail 42

@implementation SeaBrush

- (id)initWithContentsOfFile:(NSString *)path
{
	FILE *file;
	BrushHeader header;
	BOOL versionGood = NO;
	char nameString[512];
	int nameLen, tempSize;
	
	// Open the brush file
	file = fopen([path fileSystemRepresentation] ,"rb");
	if (file == NULL) {
		NSLog(@"Brush \"%@\" failed to load\n", [path lastPathComponent]);
		return NULL;
	}
	
	// Read in the header
	fread(&header, sizeof(BrushHeader), 1, file);
	
	// Convert brush header to proper endianess
#ifdef __LITTLE_ENDIAN__
	header.header_size = ntohl(header.header_size);
	header.version = ntohl(header.version);
	header.width = ntohl(header.width);
	header.height = ntohl(header.height);
	header.bytes = ntohl(header.bytes);
	header.magic_number = ntohl(header.magic_number);
	header.spacing = ntohl(header.spacing);
#endif

	// Check version compatibility
	versionGood = (header.version == 2 && header.magic_number == GBRUSH_MAGIC);
	versionGood = versionGood || (header.version == 1); 
	if (!versionGood) {
		NSLog(@"Brush \"%@\" failed to load\n", [path lastPathComponent]);
		return NULL;
	}
	
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
	if (nameLen > 512) { return NULL; }
	if (nameLen > 0) {
		fread(nameString, sizeof(char), nameLen, file);
		name = [[NSString alloc] initWithUTF8String:nameString];
	}
	else {
		name = [[NSString alloc] initWithString:LOCALSTR(@"untitled", @"Untitled")];
	}
	
	// And then read in the important stuff
	switch (header.bytes) {
		case 1:
			usePixmap = NO;
			tempSize = width * height;
			mask = malloc(make_128(tempSize));
			if (fread(mask, sizeof(char), tempSize, file) < tempSize) {
				NSLog(@"Brush \"%@\" failed to load\n", [path lastPathComponent]);
				return NULL;
			}
		break;
		case 4:
			usePixmap = YES;
			tempSize = width * height * 4;
			pixmap = malloc(make_128(tempSize));
			if (fread(pixmap, sizeof(char), tempSize, file) < tempSize) {
				NSLog(@"Brush \"%@\" failed to load\n", [path lastPathComponent]);
				return NULL;
			}
		break;
		default:
			NSLog(@"Brush \"%@\" failed to load\n", [path lastPathComponent]);
			return NULL;
		break;
	}

	// Close the brush file
	fclose(file);
	
	return self;
}

- (void)dealloc
{
	int i;
	
	if (mask) free(mask);
	if (pixmap) free(pixmap);

    CGImageRelease(bitmap);
}

- (NSString *)pixelTag
{
	unichar tchar;
	int i, start, end;
	BOOL canCut = NO;
	
	if (width > 40 || height > 40) {
		start = end = -1;
		for (i = 0; i < [name length]; i++) {
			tchar = [name characterAtIndex:i];
			if (tchar == '(') { 
				start = i + 1;
				canCut = YES;
			}
			else if (canCut) {
				if (tchar == '0')
					start = i + 1;
				else
					canCut = NO;
			}
			if (tchar == ')') end = i;
		}
		if (start != -1 && end != -1) {
			return [name substringWithRange:NSMakeRange(start, end - start)];
		}
	}
	
	return NULL;
}

- (NSImage *)thumbnail
{
    CGImageRef bm = [self bitmap];

    CGImageRef thumbnail = getTintedCG(bm,[NSColor controlTextColor]);

    NSImage *_thumbnail = [[NSImage alloc] initWithCGImage:thumbnail size:CGSizeMake(CGImageGetWidth(bm),CGImageGetHeight(bm))];
    [_thumbnail setFlipped:TRUE];

    CGImageRelease(thumbnail);

    return _thumbnail;
}

- (NSString *)name
{
	return name;
}

- (int)spacing
{
	return spacing;
}

- (int)width
{
	return width;
}

- (int)height
{
	return height;
}

- (unsigned char*)mask
{
    return mask;
}

- (NSComparisonResult)compare:(id)other
{
	return [[self name] caseInsensitiveCompare:[other name]];
}

- (void)drawBrushAt:(NSRect)rect
{
    if (width <= BrushThumbnail && height <= BrushThumbnail) {
        rect = NSMakeRect(rect.origin.x+(rect.size.width-width)/2,rect.origin.y+(rect.size.height-height)/2,width,height);
    } else {
        float proportion = width/height;

        if(proportion>1) {
            float new_height = BrushThumbnail/proportion;
            rect.origin.y += (rect.size.height - new_height)/2;
            rect.size.height = new_height;
        }
        else {
            float new_width = proportion*rect.size.height;
            rect.origin.x += (rect.size.width - new_width)/2;
            rect.size.width = new_width;
        }
    }

    NSImage *thumbnail = [self thumbnail];

    // Draw the thumbnail
    [thumbnail drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:TRUE hints:NULL];

    // Draw the pixel tag if needed
    NSString *pixelTag = [self pixelTag];
    if (pixelTag) {
        NSFont *font = [NSFont systemFontOfSize:10.0];
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, [NSColor controlBackgroundColor], NSForegroundColorAttributeName, NULL];
        IntSize fontSize = NSSizeMakeIntSize([pixelTag sizeWithAttributes:attributes]);
        [pixelTag drawAtPoint:NSMakePoint(rect.origin.x + rect.size.width / 2 - fontSize.width / 2, rect.origin.y + rect.size.height / 2 - fontSize.height / 2) withAttributes:attributes];
    }
}

- (CGImageRef)bitmap
{
    if(bitmap!=NULL){
        return bitmap;
    }

    if (usePixmap){
        CGDataProviderRef dp = CGDataProviderCreateWithData(NULL, pixmap, width*height*4, NULL);
        bitmap = CGImageCreate(width, height, 8, 8*4, 4*width, rgbCS, kCGImageAlphaLast,dp, NULL, TRUE, 0);
        CGDataProviderRelease(dp);
    } else {
        CGDataProviderRef dp = CGDataProviderCreateWithData(NULL, mask, width*height, NULL);
        bitmap = CGImageCreate(width, height, 8, 8, width, grayCS, kCGImageAlphaNone,dp, NULL, TRUE, 0);
        CGDataProviderRelease(dp);
    }

    return bitmap;
}

- (CGImageRef)maskImg
{
    if(maskImg!=NULL) {
        return maskImg;
    }
    CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, width, grayCS, kCGImageAlphaNone);
    CGContextDrawImage(ctx, NSMakeRect(0,0,width,height),[self bitmap]);
    maskImg = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);

    return maskImg;
}


@end

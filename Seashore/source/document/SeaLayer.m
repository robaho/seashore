#import "SeaLayer.h"
#import "SeaContent.h"
#import "SeaDocument.h"
#import "SeaLayerUndo.h"
#import "SeaController.h"
#import "PegasusUtility.h"
#import "Bitmap.h"
#import "SeaWarning.h"
#import "SeaPrefs.h"
#import "SeaPlugins.h"
#import "CIAffineTransformClass.h"
#import <ApplicationServices/ApplicationServices.h>
#import <CoreImage/CoreImage.h>
#import <sys/stat.h>
#import <sys/mount.h>

@implementation SeaLayer

- (id)initWithDocument:(id)doc
{	
	// Set the data members to reasonable values
	height = width = mode = 0;
	opacity = 255; xoff = yoff = 0;
	spp = 4; visible = YES; data = NULL; hasAlpha = YES;
	lostprops = NULL; lostprops_len = 0;
	document = doc;
	thumbnail = NULL; thumbData = NULL;
	floating = NO;
	seaLayerUndo = [[SeaLayerUndo alloc] initWithDocument:doc forLayer:self];
	uniqueLayerID = [(SeaDocument *)doc uniqueLayerID];
	if (uniqueLayerID == 0)
		name = [[NSString alloc] initWithString:LOCALSTR(@"background layer", @"Background")];
	else
		name = [[NSString alloc] initWithFormat:LOCALSTR(@"layer title", @"Layer %d"), uniqueLayerID];
	oldNames = [[NSArray alloc] init];
	
	return self;
}

-  (id)initWithDocument:(id)doc width:(int)lwidth height:(int)lheight opaque:(BOOL)opaque spp:(int)lspp;
{
	// Call the core initializer
	if (![self initWithDocument:doc])
		return NULL;
    
    if(lwidth<=0 || lheight<=0)
        return NULL;
	
	// Extract appropriate values of master
	width = lwidth; height = lheight;
	
	// Get the appropriate samples per pixel
	spp = lspp;
	
	// Create a representation in memory of the blank canvas
	data = malloc(make_128(width * height * spp));
	if (opaque)
		memset(data, 255, width * height * spp);
	else
		memset(data, 0, width * height * spp);
	
	// Remember the alpha situation
	hasAlpha = !opaque;
		
	return self;
}

- (id)initWithDocument:(id)doc rect:(IntRect)lrect data:(unsigned char *)ldata spp:(int)lspp
{
	// Call the core initializer
	if (![self initWithDocument:doc])
		return NULL;
	
	// Derive the width and height from the imageRep
	xoff = lrect.origin.x; yoff = lrect.origin.y;
	width = lrect.size.width; height = lrect.size.height;
    
    if(width<=0 || height<=0)
        return NULL;
	
	// Get the appropriate samples per pixel
	spp = lspp;
	
	// Copy over the bitmap data
	data = malloc(make_128(width * height * spp));
	memcpy(data, ldata, width * height * spp);

	// We should always have an alpha layer unless you turn it off
	hasAlpha = YES;
	
	return self;
}

- (id)initWithDocument:(id)doc layer:(SeaLayer*)layer
{
	// Call the core initializer
	if (![self initWithDocument:doc])
		return NULL;
		
	// Synchronize properties
	width = [layer width];
	height = [layer height];
    
    if(width<=0 || height<=0)
        return NULL;
    
    
	mode = [layer mode];
	spp = [[[layer document] contents] spp];
	data = malloc(make_128(width * height * spp));
	data = memcpy(data, [layer data], width * height * spp);
	xoff = [layer xoff];
	yoff = [layer yoff];
	visible = [layer visible];
	opacity = [layer opacity];
	name = [NSString stringWithString:[layer name]];
	
	// Assume we always have alpha
	hasAlpha = YES;
	
	// Finally convert the bitmap to the correct type
	[self convertFromType:[(SeaContent *)[[layer document] contents] type] to:[(SeaContent *)[document contents] type]];
	
	return self;
}

- (id)initFloatingWithDocument:(id)doc rect:(IntRect)lrect data:(unsigned char *)ldata
{
	// Set the offsets, height and width
	xoff = lrect.origin.x;
	yoff = lrect.origin.y;
    
	width = lrect.size.width;
	height = lrect.size.height;
	
	// Set the other variables according to the arguments
	document = doc;
	data = ldata;
	
	// And then make some sensible choices for the other variables
	mode = 0;
	opacity = 255;
	spp = [[document contents] spp];
	visible = YES;
	hasAlpha = YES;
	thumbnail = NULL; thumbData = NULL;
	floating = YES;
	
	// Setup for undoing
	seaLayerUndo = [[SeaLayerUndo alloc] initWithDocument:doc forLayer:self];
	uniqueLayerID = [(SeaDocument *)doc uniqueFloatingLayerID];
	name = NULL; oldNames = NULL;
	
	return self;
}

- (void)dealloc
{	
    if (data) free(data);
	if (thumbData) free(thumbData);
}

- (id)document
{
	return document;
}

- (int)width
{
	return width;
}

- (int)height
{
	return height;
}

- (int)xoff
{
	return xoff;
}

- (int)yoff
{
	return yoff;
}

- (IntRect)localRect
{
	return IntMakeRect(xoff, yoff, width, height);
}

- (void)setOffsets:(IntPoint)newOffsets
{
	xoff = newOffsets.x;
	yoff = newOffsets.y;
}

- (void)trimLayer
{
	int i, j;
	int left, right, top, bottom;
	
	// Start out with invalid content borders
	left = right = top = bottom =  -1;
	
	// Determine left content margin
	for (i = 0; i < width && left == -1; i++) {
		for (j = 0; j < height && left == -1; j++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				left = i;
			}
		}
	}
	
	// Determine right content margin
	for (i = width - 1; i >= 0 && right == -1; i--) {
		for (j = 0; j < height && right == -1; j++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				right = width - 1 - i;
			}
		}
	}
	
	// Determine top content margin
	for (j = 0; j < height && top == -1; j++) {
		for (i = 0; i < width && top == -1; i++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				top = j;
			}
		}
	}
	
	// Determine bottom content margin
	for (j = height - 1; j >= 0 && bottom == -1; j--) {
		for (i = 0; i < width && bottom == -1; i++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				bottom = height - 1 - j;
			}
		}
	}
	
	// Make the change
	if (left != 0 || top != 0 || right != 0 || bottom != 0)
		[self setMarginLeft:-left top:-top right:-right bottom:-bottom];
}

- (void)flipHorizontally
{
	unsigned char temp[4];
	int i, j;
	
	for (j = 0; j < height; j++) {
		for (i = 0; i < width / 2; i++) {
			memcpy(temp, &(data[(j * width + i) * spp]), spp);
			memcpy(&(data[(j * width + i) * spp]), &(data[(j * width + (width - i - 1)) * spp]), spp);
			memcpy(&(data[(j * width + (width - i - 1)) * spp]), temp, spp);
		}
	}
	
	xoff = [(SeaContent *)[document contents] width] - xoff - width;
}

- (void)flipVertically
{
	unsigned char temp[4];
	int i, j;
	
	for (j = 0; j < height / 2; j++) {
		for (i = 0; i < width; i++) {
			memcpy(temp, &(data[(j * width + i) * spp]), spp);
			memcpy(&(data[(j * width + i) * spp]), &(data[((height - j - 1) * width + i) * spp]), spp);
			memcpy(&(data[((height - j - 1) * width + i) * spp]), temp, spp);
		}
	}
	
	yoff = [(SeaContent *)[document contents] height] - yoff - height;
}

- (void)rotateLeft
{
	int newWidth, newHeight, ox, oy;
	unsigned char *newData;
	int i, j, k;
	
	newWidth = height;
	newHeight = width;
	newData = malloc(make_128(newWidth * newHeight * spp));
	
	for (j = 0; j < height; j++) {
		for (i = 0; i < width; i++) {
			for (k = 0; k < spp; k++) {
				newData[((newHeight - i - 1) * newWidth + j) * spp + k] = data[(j * width + i) * spp + k]; 
			}
		}
	}
	free(data);
	
	ox = [(SeaContent *)[document contents] width] - xoff - width;
	oy = yoff;
	
	width = newWidth;
	height = newHeight;
	data = newData;
	
	xoff = oy;
	yoff = ox;
}

- (void)rotateRight
{
	int newWidth, newHeight, ox, oy;
	unsigned char *newData;
	int i, j, k;
	
	newWidth = height;
	newHeight = width;
	newData = malloc(make_128(newWidth * newHeight * spp));
	
	for (j = 0; j < height; j++) {
		for (i = 0; i < width; i++) {
			for (k = 0; k < spp; k++) {
				newData[(i * newWidth + (newWidth - j - 1)) * spp + k] = data[(j * width + i) * spp + k]; 
			}
		}
	}
	free(data);
	
	ox = xoff;
	oy = [(SeaContent *)[document contents] height] - yoff - height;
	
	width = newWidth;
	height = newHeight;
	data = newData;
	
	xoff = oy;
	yoff = ox;
}

- (void)setRotation:(float)degrees interpolation:(int)interpolation withTrim:(BOOL)trim
{
    
    NSRect bounds = NSMakeRect(0,0,width,height);
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:bounds];
    NSAffineTransform *at = [NSAffineTransform transform];
    [at rotateByDegrees:degrees];
    [path transformUsingAffineTransform:at];
    NSRect rotatedBounds = [path bounds];

    int newWidth = (int)NSWidth(rotatedBounds);
    int newHeight = (int)NSHeight(rotatedBounds);

    unsigned char *buffer = malloc(newWidth*newHeight*spp);
    memset(buffer,0,newWidth*newHeight*spp);

    NSBitmapImageRep *new = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&buffer
                                                                    pixelsWide:newWidth pixelsHigh:newHeight
                                                                 bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO
                                                                colorSpaceName:spp>2 ? MyRGBSpace : MyGraySpace bytesPerRow:newWidth*spp
                                                                  bitsPerPixel:8*spp];
    
    
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:new];
    [NSGraphicsContext setCurrentContext:ctx];
    
    [ctx setImageInterpolation:interpolation];
    
    at = [NSAffineTransform transform];
    [at translateXBy:NSWidth(rotatedBounds)/2 yBy:NSHeight(rotatedBounds)/2];
    [at rotateByDegrees:degrees];
    [at concat];
    
    [[self bitmap] drawAtPoint:NSMakePoint(-NSWidth(bounds)/2,-NSHeight(bounds)/2)];
    [NSGraphicsContext restoreGraphicsState];
    
    unpremultiplyBitmap(spp,buffer,buffer,newWidth*newHeight);
    
    free(data);
    data = buffer;
    
    xoff += width / 2 - newWidth / 2;
    yoff += height / 2 - newHeight / 2;
    width = newWidth; height = newHeight;
    
    // Destroy the thumbnail data
    if (thumbData) free(thumbData);
    thumbnail = NULL; thumbData = NULL;
    
    // Make margin changes
    if (trim) [self trimLayer];
}

- (BOOL)visible
{
	return visible;
}

- (void)setVisible:(BOOL)value
{
	visible = value;
}

- (BOOL)linked
{
	return linked;
}

- (void)setLinked:(BOOL)value
{
	linked = value;
}

- (int)opacity
{
	return opacity;
}

- (void)setOpacity:(int)value
{
	opacity = value;
}

- (int)mode
{
	return mode;
}

- (void)setMode:(int)value
{
	mode = value;
}

- (NSString *)name
{
	return name;
}

- (void)setName:(NSString *)newName
{
	if (name) {
		oldNames = [oldNames arrayByAddingObject:name];
		name = newName;
	}
}

- (unsigned char *)data
{
	return data;
}

- (BOOL)hasAlpha
{
	return hasAlpha;
}

- (void)toggleAlpha
{
	// Do nothing if we can't do anything
	if (![self canToggleAlpha])
		return;
	
	// Change the alpha channel treatment
	hasAlpha = !hasAlpha;
	
	// Update the Pegasus utility
	[[document pegasusUtility] update:kPegasusUpdateAll]; 

	// Make action undoable
	[[[document undoManager] prepareWithInvocationTarget:self] toggleAlpha];
}

- (void)introduceAlpha
{
	hasAlpha = YES;
}

- (BOOL)canToggleAlpha
{
	int i;
	
	if (floating)
		return NO;
	
	if (hasAlpha) {
		for (i = 0; i < width * height; i++) {
			if (data[(i + 1) * spp - 1] != 255)
				return NO;
		}
	}
	
	return YES;
}

- (char *)lostprops
{
	return lostprops;
}

- (int)lostprops_len
{
	return lostprops_len;
}

- (int)uniqueLayerID
{
	return uniqueLayerID;
}

- (int)index
{
	int i;
	
	for (i = 0; i < [(SeaContent*)[document contents] layerCount]; i++) {
		if ([[document contents] layer:i] == self)
			return i;
	}
	
	return -1;
}

- (BOOL)floating
{
	return floating;
}

- (id)seaLayerUndo
{
	return seaLayerUndo;
}

- (NSImage *)thumbnail
{
	NSBitmapImageRep *tempRep;
	
	// Check if we need an update
	if (thumbData == NULL) {
		
		// Determine the size for the image
		thumbWidth = width; thumbHeight = height;
		if (width > 40 || height > 32) {
			if ((float)width / 40.0 > (float)height / 32.0) {
				thumbHeight = (int)((float)height * (40.0 / (float)width));
				thumbWidth = 40;
			}
			else {
				thumbWidth = (int)((float)width * (32.0 / (float)height));
				thumbHeight = 32;
			}
		}
		if(thumbWidth <= 0){
			thumbWidth = 1;
		}
		if(thumbHeight <= 0){
			thumbHeight = 1;
		}
		// Create the thumbnail
		thumbData = malloc(thumbWidth * thumbHeight * spp);
		
		// Determine the thumbnail data
		[self updateThumbnail];
		
	}
	
	// Create the representation
	tempRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&thumbData pixelsWide:thumbWidth pixelsHigh:thumbHeight bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:thumbWidth * spp bitsPerPixel:8 * spp];
	
	thumbnail = [[NSImage alloc] initWithSize:NSMakeSize(thumbWidth, thumbHeight)];
	[thumbnail addRepresentation:tempRep];
    [thumbnail setFlipped:true];
		
	return thumbnail;
}

- (void)updateThumbnail
{
	float horizStep, vertStep;
	int i, j, k, temp;
	int srcPos, destPos;
	
	if (thumbData) {
	
		// Determine the thumbnail data
		horizStep = (float)width / (float)thumbWidth;
		vertStep = (float)height / (float)thumbHeight;
		for (j = 0; j < thumbHeight; j++) {
			for (i = 0; i < thumbWidth; i++) {
				srcPos = ((int)(j * vertStep) * width + (int)(i * horizStep)) * spp;
				destPos = (j * thumbWidth + i) * spp;
				
				if (data[srcPos + (spp - 1)] == 255) {
					for (k = 0; k < spp; k++)
						thumbData[destPos + k] = data[srcPos + k];
				}
				else if (data[srcPos + (spp - 1)] == 0) {
					for (k = 0; k < spp; k++)
						thumbData[destPos + k] = 0;
				}
				else {
					for (k = 0; k < spp - 1; k++)
						thumbData[destPos + k] = int_mult(data[srcPos + k], data[srcPos + (spp - 1)], temp);
					thumbData[destPos + (spp - 1)] = data[srcPos + (spp - 1)];
				}
			}
		}
		
	}
}

- (NSData *)TIFFRepresentation
{
	NSBitmapImageRep *imageRep;
	NSData *imageTIFFData;
	unsigned char *pmImageData;
	int i, j, tspp;
	
	// Allocate room for the premultiplied image data
	if (hasAlpha)
		pmImageData = malloc(width * height * spp);
	else
		pmImageData = malloc(width * height * (spp - 1));
		
	// If there is an alpha channel...
	if (hasAlpha) {
		
		// Formulate the premultiplied data from the data
		premultiplyBitmap(spp, pmImageData, data, width * height);
	
	}
	else {
	
		// Strip the alpha channel
		for (i = 0; i < width * height; i++) {
			for (j = 0; j < spp - 1; j++) {
				pmImageData[i * (spp - 1) + j] = data[i * spp + j];
			}
		}
		
	}
	
	// Then create the representation
	tspp = (hasAlpha ? spp : spp - 1);
	imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&pmImageData pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:tspp hasAlpha:hasAlpha isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * tspp bitsPerPixel:8 * tspp];
	
	// Work out the image data
	imageTIFFData = [imageRep TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:255];
	
	// Release the representation and the image data
	free(pmImageData);
	
	return imageTIFFData;
}

- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom
{
	unsigned char *newImageData;
	int i, j, k, destPos, srcPos, newWidth, newHeight;
	
	// Allocate an appropriate amount of memory for the new bitmap
	newWidth = width + left + right;
	newHeight = height + top + bottom;
    
    if(newWidth<0 || newHeight<0){
        return;
    }
    
	newImageData = malloc(make_128(newWidth * newHeight * spp));
	// do_128_clean(newImageData, make_128(newWidth * newHeight * spp));
	
	// Fill the new bitmap with the appropriate values
	for (j = 0; j < newHeight; j++) {
		for (i = 0; i < newWidth; i++) {
			
			destPos = (j * newWidth + i) * spp;
			
			if (i < left || i >= left + width || j < top || j >= top + height) {
				if (!hasAlpha) { for (k = 0; k < spp; k++) newImageData[destPos + k] = 255; }
				else { for (k = 0; k < spp; k++) newImageData[destPos + k] = 0; }
			}
			else {
				srcPos = ((j - top) * width + (i - left)) * spp;
				for (k = 0; k < spp; k++)
					newImageData[destPos + k] = data[srcPos + k];
			}
			
		}
	}
	
	// Replace the old bitmap with the new bitmap
	free(data);
	data = newImageData;
	width = newWidth; height = newHeight;
	xoff -= left; yoff -= top; 
	
	if (thumbData) free(thumbData);
	thumbnail = NULL; thumbData = NULL;
}

- (void)setWidth:(int)newWidth height:(int)newHeight interpolation:(int)interpolation
{
    unsigned char *buffer = malloc(newWidth*newHeight*spp);
    memset(buffer,0,newWidth*newHeight*spp);
    
    NSBitmapImageRep *bitmap = [self bitmap];
    NSBitmapImageRep *new = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&buffer
                                                                    pixelsWide:newWidth pixelsHigh:newHeight
                                                                 bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO
                                                                colorSpaceName:spp>2 ? MyRGBSpace : MyGraySpace bytesPerRow:newWidth*spp
                                                                  bitsPerPixel:8*spp];
    
    
    NSRect newRect = NSMakeRect(0,0,newWidth,newHeight);
    
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:new];
    [NSGraphicsContext setCurrentContext:ctx];
    
    [ctx setImageInterpolation:interpolation];
    
    [bitmap drawInRect:newRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:NO hints:NULL];
    [NSGraphicsContext restoreGraphicsState];
    
    free(data);
    
    unpremultiplyBitmap(spp,buffer,buffer,newWidth*newHeight);
    
    data = buffer;
    
    width = newWidth; height = newHeight;
    
    if (thumbData) free(thumbData);
    thumbnail = NULL; thumbData = NULL;
}

- (NSBitmapImageRep *)bitmap
{
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data
                                                                         pixelsWide:width pixelsHigh:height bitsPerSample:8
                                                                    samplesPerPixel:spp hasAlpha:TRUE isPlanar:NO
                                                                     colorSpaceName:(spp == 4) ? MyRGBSpace : MyGraySpace
                                                                       bitmapFormat:NSBitmapFormatAlphaNonpremultiplied
                                                                        bytesPerRow:width * spp bitsPerPixel:8 * spp];
    return imageRep;
}

- (void)convertFromType:(int)srcType to:(int)destType
{
	if (thumbData) free(thumbData);
	thumbnail = NULL; thumbData = NULL;
    
	// Don't do anything if there is nothing to do
	if (srcType == destType)
		return;
    
    unsigned char *newdata;
    
    NSBitmapImageRep *imageRep = [self bitmap];
		
	if (srcType == XCF_RGB_IMAGE && destType == XCF_GRAY_IMAGE) {
        spp=2;
    } else {
        spp=4;
    }
    
    newdata = convertImageRep(imageRep,spp);

    free(data);
    
    data = newdata;
}

@end

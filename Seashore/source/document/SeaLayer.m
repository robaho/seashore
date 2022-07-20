#import "SeaLayer.h"
#import "SeaContent.h"
#import "SeaDocument.h"
#import "SeaLayerUndo.h"
#import "SeaController.h"
#import "LayersUtility.h"
#import "SeaPrefs.h"
#import "SeaPlugins.h"
#import "SeaTools.h"
#import "PositionTool.h"
#import "NSAffineTransform_Extensions.h"

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
	spp = 4; visible = YES; nsdata = [NSData data]; hasAlpha = YES;
	lostprops = NULL; lostprops_len = 0;
	document = doc;
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

    int len = width*height*spp;
	
	// Create a representation in memory of the blank canvas
	unsigned char *data = malloc(len);

	if (opaque)
		memset(data, 255, len);
	else
		memset(data, 0, len);

    nsdata = [NSData dataWithBytesNoCopy:data length:len];
	
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
    // Get the appropriate samples per pixel
    spp = lspp;

    nsdata = [NSData dataWithBytesNoCopy:ldata length:width*height*spp];

    if(width<=0 || height<=0)
        return NULL;

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

    nsdata = [NSData dataWithData:[layer layerData]];
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

- (void)dealloc
{	
    CGImageRelease(pre_bitmap);
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

- (BOOL)active
{
    return self == [[document contents] activeLayer];
}

- (IntRect)globalRect
{
	return IntMakeRect(xoff, yoff, width, height);
}

- (IntRect)translateView:(IntRect)viewRect
{
    return IntMakeRect(viewRect.origin.x-xoff,viewRect.origin.y-yoff,viewRect.size.width,viewRect.size.height);
}

- (IntPoint)origin
{
    return IntMakePoint(xoff, yoff);
}

- (IntSize)size
{
    return IntMakeSize(width, height);
}

- (void)setOffsets:(IntPoint)newOffsets
{
	xoff = newOffsets.x;
	yoff = newOffsets.y;
}

- (void)trimLayer
{
    Margins m = [self contentMargins];
    
	if (m.left != 0 || m.top != 0 || m.right != 0 || m.bottom != 0)
		[self setMarginLeft:-m.left top:-m.top right:-m.right bottom:-m.bottom];
}

- (Margins)contentMargins
{
    int i, j, k;
    int left, right, top, bottom;

    // Start out with invalid content borders
    left = right = top = bottom = -1;

    unsigned char *data = [nsdata bytes];

    // Determine left content margin
    for (i = 0; i < width && left == -1; i++) {
        for (j = 0; j < height && left == -1; j++) {
            if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
                for (k = 0; k < spp; k++) {
                    if (data[j * width * spp + i * spp + k] != data[k])
                        left = i;
                }
            }
        }
    }

    // Determine right content margin
    for (i = width - 1; i >= 0 && right == -1; i--) {
        for (j = 0; j < height && right == -1; j++) {
            if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
                for (k = 0; k < spp; k++) {
                    if (data[j * width * spp + i * spp + k] != data[k])
                        right = width - 1 - i;
                }
            }
        }
    }

    // Determine top content margin
    for (j = 0; j < height && top == -1; j++) {
        for (i = 0; i < width && top == -1; i++) {
            if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
                for (k = 0; k < spp; k++) {
                    if (data[j * width * spp + i * spp + k] != data[k])
                        top = j;
                }
            }
        }
    }

    // Determine bottom content margin
    for (j = height - 1; j >= 0 && bottom == -1; j--) {
        for (i = 0; i < width && bottom == -1; i++) {
            if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
                for (k = 0; k < spp; k++) {
                    if (data[j * width * spp + i * spp + k] != data[k])
                        bottom = height - 1 - j;
                }
            }
        }
    }

    Margins m = { left:left, top:top, right:right, bottom:bottom};
    return m;
}

- (void)flipHorizontally
{
	unsigned char temp[4];
	int i, j;

    unsigned char *data = [nsdata bytes];

	for (j = 0; j < height; j++) {
		for (i = 0; i < width / 2; i++) {
			memcpy(temp, &(data[(j * width + i) * spp]), spp);
			memcpy(&(data[(j * width + i) * spp]), &(data[(j * width + (width - i - 1)) * spp]), spp);
			memcpy(&(data[(j * width + (width - i - 1)) * spp]), temp, spp);
		}
	}

}

- (void)flipVertically
{
	unsigned char temp[4];
	int i, j;
	
    unsigned char *data = [nsdata bytes];

	for (j = 0; j < height / 2; j++) {
		for (i = 0; i < width; i++) {
			memcpy(temp, &(data[(j * width + i) * spp]), spp);
			memcpy(&(data[(j * width + i) * spp]), &(data[((height - j - 1) * width + i) * spp]), spp);
			memcpy(&(data[((height - j - 1) * width + i) * spp]), temp, spp);
		}
	}
}

- (void)rotateLeft
{
    int ox = [[document contents] width] - xoff - width;
    int oy = yoff;

    [self setRotation:-90 interpolation:0 withTrim:FALSE];
    xoff = oy;
    yoff = ox;
}

- (void)rotateRight
{
    int ox = xoff;
    int oy = [[document contents] height] - yoff - height;
    [self setRotation:90 interpolation:0 withTrim:FALSE];
    xoff = oy;
    yoff = ox;
}

- (void)setRotation:(float)degrees interpolation:(int)interpolation withTrim:(BOOL)trim
{
    float radians = degrees * PI / 180.0;

    int oldWidth = width;
    int oldHeight = height;

    [self scaleX:1 scaleY:1 rotate:radians];

    xoff += oldWidth / 2 - width / 2;
    yoff += oldHeight / 2 - height / 2;

    image = NULL;
    
    // Make margin changes
    if (trim) [self trimLayer];
}

- (IntRect)bounds:(NSAffineTransform*)tx
{
    NSRect r = NSMakeRect(0,0, width, height);
    NSBezierPath *tempPath = [NSBezierPath bezierPathWithRect:r];
    [tempPath transformUsingAffineTransform:tx];

    return NSRectMakeIntRect([tempPath bounds]);
}

- (void)scaleX:(float)xscale scaleY:(float)yscale rotate:(float)rotation
{
    [self image];

    CGImageRef image = pre_bitmap;

    NSAffineTransform *tx = [NSAffineTransform transform];

    [tx translateXBy:width/2 yBy:height/2];
    [tx rotateByRadians:-rotation];
    [tx scaleXBy:xscale yBy:yscale];
    [tx translateXBy:-(width/2) yBy:-(height/2)];

    IntRect bounds = [self bounds:tx];

    int w = bounds.size.width;
    int h = bounds.size.height;

    unsigned char *new_data = calloc(w*h*spp,1);
    CGContextRef ctx = CGBitmapContextCreate(new_data,w,h,8,w*spp, COLOR_SPACE, kCGImageAlphaPremultipliedLast);

    CGContextTranslateCTM(ctx,w/2,h/2);
    CGContextRotateCTM(ctx,-rotation);
    CGContextScaleCTM(ctx,xscale,yscale);
    CGContextTranslateCTM(ctx,-(width/2),-(height/2));

    CGContextDrawImage(ctx,CGRectMake(0,0,width,height),image);

    CGContextRelease(ctx);

    nsdata = [NSData dataWithBytesNoCopy:new_data length:w*h*spp];
    width=w;
    height=h;
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

- (float)opacity_float
{
    return opacity/255.0;
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
	return [nsdata bytes];
}

- (NSData *)layerData
{
    return nsdata;
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
	
	hasAlpha = !hasAlpha;
	[[document layersUtility] update:kLayersUpdateAll];
	[[[document undoManager] prepareWithInvocationTarget:self] toggleAlpha];
}

- (void)introduceAlpha
{
	hasAlpha = YES;
}

- (BOOL)canToggleAlpha
{
	int i;

    unsigned char *data = [nsdata bytes];

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

- (id)seaLayerUndo
{
	return seaLayerUndo;
}

- (NSImage *)thumbnail
{
    return [self image];
}

- (void)updateThumbnail
{
    image = NULL;
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
		
    unsigned char *data = [nsdata bytes];

	// If there is an alpha channel...
	if (hasAlpha) {
        premultiplyBitmap(spp, pmImageData, data, width*height*spp);
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

    int len = newWidth * newHeight * spp;
	newImageData = malloc(make_128(len));

    unsigned char *data = [nsdata bytes];

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
	
    nsdata = [NSData dataWithBytesNoCopy:newImageData length:len];
	width = newWidth; height = newHeight;
	xoff -= left; yoff -= top; 
	
    image = NULL;
}

- (void)setWidth:(int)newWidth height:(int)newHeight interpolation:(int)interpolation
{
    int len = newWidth*newHeight*spp;
    unsigned char *buffer = malloc(len);
    
    CHECK_MALLOC(buffer);
    
    memset(buffer,0,newWidth*newHeight*spp);

    CGContextRef ctx = CGBitmapContextCreate(buffer, newWidth, newHeight, 8, newWidth*spp, COLOR_SPACE, kCGImageAlphaPremultipliedLast);
    CGContextSetInterpolationQuality(ctx, interpolation);

    CGImageRef bitmap = [self bitmap];

    CGContextDrawImage(ctx, CGRectMake(0,0,newWidth,newHeight),bitmap);

    nsdata = [NSData dataWithBytesNoCopy:buffer length:len];

    width = newWidth; height = newHeight;

    unpremultiplyBitmap(spp, buffer, buffer, width*height);

    image = NULL;
}

- (CGImageRef)bitmap
{
    CGDataProviderRef dp = CGDataProviderCreateWithData(NULL,[nsdata bytes],width*height*spp,NULL);
    CGImageRef image = CGImageCreate(width,height,8,8*spp,width*spp,COLOR_SPACE,kCGImageAlphaLast,dp,nil,false,0);
    CGDataProviderRelease(dp);
    return image;
}

- (NSImage *)image
{
    if(image==NULL){
        CGImageRelease(pre_bitmap);
        CGImageRef img = [self bitmap];
        CGContextRef ctx = CGBitmapContextCreate(nil, width, height, 8, spp*width, COLOR_SPACE, kCGImageAlphaPremultipliedLast);
        CGContextDrawImage(ctx, CGRectMake(0,0,width,height), img);
        pre_bitmap = CGBitmapContextCreateImage(ctx);
        CGContextRelease(ctx);
        image = [[NSImage alloc] initWithCGImage:pre_bitmap size:NSZeroSize];
        CGImageRelease(img);
        [image setCacheMode:NSImageCacheAlways];
    }
    return image;
}

- (void)convertFromType:(int)srcType to:(int)destType
{
	// Don't do anything if there is nothing to do
	if (srcType == destType)
		return;
    
    image = NULL;

    CGImageRef bitmap = [self bitmap];
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:bitmap];
    CGImageRelease(bitmap);
		
	if (srcType == XCF_RGB_IMAGE && destType == XCF_GRAY_IMAGE) {
        spp=2;
    } else {
        spp=4;
    }
    
    unsigned char *newdata = convertImageRep(imageRep,spp);

    nsdata = [NSData dataWithBytesNoCopy:newdata length:width*height*spp];
}

- (void)drawLayer:(CGContextRef)context
{
    CGImageRef image = [self bitmap];

    CGContextSaveGState(context);
    CGContextSetBlendMode(context, mode);

    SeaLayer *active = [[document contents] activeLayer];

    bool shouldTransform = active==self || ([active linked] && linked);

    if([document currentToolId]==kPositionTool && shouldTransform) {
        PositionTool *positionTool = (PositionTool*)[document currentTool];
        CGAffineTransform tx = [[positionTool transform:self] cgtransform];
        CGContextConcatCTM(context, tx);
    } else {
        CGContextTranslateCTM(context,xoff,yoff);
    }

    CGContextTranslateCTM(context,0,height);
    CGContextScaleCTM(context,1,-1);

    CGContextSetAlpha(context,[self opacity_float]);
    [self image]; // force premultipled bitmap to be created if needed
    CGContextDrawImage(context,CGRectMake(0,0,width,height),pre_bitmap);
    CGImageRelease(image);
    CGContextRestoreGState(context);
}

- (void)drawChannelLayer:(CGContextRef)context withImage:(unsigned char *)data0
{
    int channel = [[document contents] selectedChannel];

    CGDataProviderRef dp = CGDataProviderCreateWithData(NULL,data0!=nil?data0:[nsdata bytes],width*height*spp,NULL);
    CGImageRef image = CGImageCreate(width,height,8,8*spp,width*spp,COLOR_SPACE,channel==kAlphaChannelView ? kCGImageAlphaLast : kCGImageAlphaNoneSkipLast,dp,nil,false,0);
    CGDataProviderRelease(dp);

    CGContextSaveGState(context);

    SeaLayer *active = [[document contents] activeLayer];

    bool shouldTransform = active==self || ([active linked] && linked);

    if([document currentToolId]==kPositionTool && shouldTransform) {
        PositionTool *positionTool = (PositionTool*)[document currentTool];
        CGAffineTransform tx = [[positionTool transform:self] cgtransform];
        CGContextConcatCTM(context, tx);
    } else {
        CGContextTranslateCTM(context,xoff,yoff);
    }

    CGRect r = CGRectMake(0,0,width,height);

    CGContextTranslateCTM(context,0,height);
    CGContextScaleCTM(context,1,-1);

    CGContextSetAlpha(context,1.0);

    if(channel==kAlphaChannelView) {
        CGContextSetFillColorWithColor(context, CGColorCreateGenericRGB(1,1,1,1));
        CGContextFillRect(context, r);
        CGContextSetBlendMode(context, kCGBlendModeDestinationIn);
    } else {
        CGContextSetBlendMode(context, kCGBlendModeNormal);
    }

    CGContextDrawImage(context,r,image);
    CGImageRelease(image);
    CGContextRestoreGState(context);
}


- (NSColor *) getPixelX:(int)x Y:(int)y
{
    x = x-xoff;
    y = y-yoff;
    
    if(x<0 || x>=width || y<0 || y>=height)
        return NULL;

    unsigned char *pixelData = [nsdata bytes] + (width*y+x) * spp;

    if(spp==2){
        return [NSColor colorWithRed:pixelData[0]/255.0 green:pixelData[0]/255.0 blue:pixelData[0]/255.0 alpha:pixelData[1]/255.0];
    } else {
        return [NSColor colorWithRed:pixelData[0]/255.0 green:pixelData[1]/255.0 blue:pixelData[2]/255.0 alpha:pixelData[3]/255.0];
    }
}

@end

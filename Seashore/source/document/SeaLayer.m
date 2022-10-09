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
    int height = width = mode = 0; // must have a min size or memory allocates don't work
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

// make a copy of a layer
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

    nsdata = [NSData dataWithBytes:[[layer layerData] bytes] length:[[layer layerData] length]];
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

- (IntRect)globalBounds {
    NSAffineTransform *position_tx = [NSAffineTransform transform];

    if ([self shouldTransform]) {
        PositionTool *positionTool = (PositionTool*)[document currentTool];
        position_tx = [positionTool transform];
    }

    NSRect r = IntRectMakeNSRect([self globalRect]);

    int w = r.size.width;
    int h = r.size.height;

    NSBezierPath *tempPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0,0,w,h)];
    NSAffineTransform *tx = [NSAffineTransform transform];
    [tx translateXBy:-(w/2) yBy:-(h/2)];
    [tempPath transformUsingAffineTransform:tx];
    [tempPath transformUsingAffineTransform:position_tx];
    tx = [NSAffineTransform transform];
    [tx translateXBy:(w/2) yBy:(h/2)];
    [tx translateXBy:r.origin.x yBy:r.origin.y];
    [tempPath transformUsingAffineTransform:tx];

    IntRect bounds = NSRectMakeIntRect([tempPath bounds]);
    return bounds;
}

- (IntRect)localRect
{
    return IntMakeRect(0,0, width, height);
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

    if(![nsdata length]) {
        return (Margins){0,0,0,0};
    }

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
    NSAffineTransform *tx = [NSAffineTransform transform];
    [tx scaleXBy:-1 yBy:1];

    [self applyTransform:tx];
}

- (void)flipVertically
{
    NSAffineTransform *tx = [NSAffineTransform transform];
    [tx scaleXBy:1 yBy:-1];

    [self applyTransform:tx];
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

- (IntSize)bounds:(NSAffineTransform*)tx
{
    NSRect r = NSMakeRect(0,0, width, height);
    NSBezierPath *tempPath = [NSBezierPath bezierPathWithRect:r];
    [tempPath transformUsingAffineTransform:tx];

    return NSRectMakeIntRect(NSIntegralRect([tempPath bounds])).size;
}

- (void)scaleX:(float)xscale scaleY:(float)yscale rotate:(float)rotation
{
    NSAffineTransform *tx = [NSAffineTransform transform];
    [tx rotateByRadians:-rotation];
    [tx scaleXBy:xscale yBy:yscale];

    [self applyTransform:tx];
}

- (void)applyTransform:(NSAffineTransform*)tx
{
    IntSize bounds = [self bounds:tx];

    int w = bounds.width;
    int h = bounds.height;

    if(w==0 || h==0) {
        nsdata = [NSData data];
        goto done;
    }

    unsigned char *new_data = calloc(w*h*spp,1);
    CHECK_MALLOC(new_data);
    
    CGContextRef ctx = CGBitmapContextCreate(new_data,w,h,8,w*spp, COLOR_SPACE, kCGImageAlphaPremultipliedLast);
    CGContextTranslateCTM(ctx,(w/2),(h/2));
    CGContextConcatCTM(ctx,[tx cgtransform]);
    CGContextTranslateCTM(ctx,-(width/2),-(height/2));
    [self drawContent:ctx];
    CGContextRelease(ctx);

    unpremultiplyBitmap(spp, new_data, new_data, w*h);
    nsdata = [NSData dataWithBytesNoCopy:new_data length:w*h*spp];

done:
    width=w;
    height=h;
}

- (bool)isComplexTransform
{
    CGAffineTransform s = [self layerTransform];
    return (s.a!=1 || s.b!=0 || s.c!=0 || s.d!=1);
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

- (bool)isRasterized
{
    return true;
}
- (void)markRasterized
{
}

- (bool)isTextLayer
{
    return false;
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

    if(![nsdata length])
        return false;

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
    if(thumbnail==NULL){
        NSImage *tmp = [self image];
        thumbnail = [NSImage imageWithSize:[image size] flipped:FALSE drawingHandler:^BOOL(NSRect dstRect) {
            float max_scale = MaxScale(CGContextGetCTM([[NSGraphicsContext currentContext] graphicsPort]));
            [[NSGraphicsContext currentContext] setShouldAntialias:FALSE];
            [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
            [tmp drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
            CGFloat dashes[] = {2/max_scale,4/max_scale};
            NSBezierPath *path = [NSBezierPath bezierPathWithRect:dstRect];
            [[NSColor controlTextColor] set];
            [path setLineDash:dashes count:2 phase:0];
            [path setLineWidth:2/max_scale];
            [path stroke];
            return TRUE;
        }];
    }
    return thumbnail;
}

- (void)updateThumbnail
{
    image = NULL;
    thumbnail = NULL;
}

- (NSData *)TIFFRepresentation
{
    return [[self image] TIFFRepresentation];
}

- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom
{
	unsigned char *newImageData;
	int i, j, k, destPos, srcPos, newWidth, newHeight;
	
	// Allocate an appropriate amount of memory for the new bitmap
	newWidth = width + left + right;
	newHeight = height + top + bottom;
    
    if(newWidth<=0 || newHeight<=0){
        nsdata = [NSData data];
        goto done;
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

done:
	width = newWidth; height = newHeight;
	xoff -= left; yoff -= top; 
	
    image = NULL;
}

- (CGImageRef)bitmap
{
    if(![nsdata length])
        return NULL;

    CGDataProviderRef dp = CGDataProviderCreateWithData(NULL,[nsdata bytes],width*height*spp,NULL);
    CGImageRef image = CGImageCreate(width,height,8,8*spp,width*spp,COLOR_SPACE,kCGImageAlphaLast,dp,nil,false,0);
    CGDataProviderRelease(dp);
    return image;
}

- (CGImageRef)copyBitmap:(IntRect)rect
{
    rect = IntConstrainRect([self localRect],rect);

    int w = rect.size.width;
    int h = rect.size.height;

    if(w==0 || h==0 || ![nsdata length])
        return NULL;

    int len = rect.size.width*rect.size.height*spp;
    unsigned char *p = malloc(len);
    CFDataRef copydata = CFDataCreateWithBytesNoCopy(NULL,p,len,NULL);

    unsigned char *data = [nsdata bytes];

    CGDataProviderRef dp = CGDataProviderCreateWithCFData(copydata);
    CGImageRef image = CGImageCreate(w,h,8,8*spp,w*spp,COLOR_SPACE,kCGImageAlphaLast,dp,nil,false,0);
    CGDataProviderRelease(dp);

    // copy data
    for(int y=0;y<h;y++) {
        memcpy(p+(w*y)*spp,data+((rect.origin.y+y)*width+rect.origin.x)*spp,w*spp);
    }

    return image;
}

- (NSImage *)image
{
    if(image==NULL){
        CGImageRef img = [self bitmap];
        image = [[NSImage alloc] initWithCGImage:img size:NSZeroSize];
        [image setCacheMode:NSImageCacheAlways];
        CGImageRelease(img);
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
    CGContextSaveGState(context);
    [self transformContext:context];
    CGContextSetBlendMode(context, mode);
    CGContextSetAlpha(context,[self opacity_float]);
    [self drawContent:context];
    CGContextRestoreGState(context);
}

- (BOOL)shouldTransform
{
    SeaLayer *active = [[document contents] activeLayer];

    return [document currentToolId]==kPositionTool && (active==self || ([active linked] && linked));
}

- (CGAffineTransform)layerTransform
{
    CGAffineTransform tx = CGAffineTransformIdentity;

    if([self shouldTransform]) {
        PositionTool *positionTool = (PositionTool*)[document currentTool];
        tx = [[positionTool transform] cgtransform];
    }

    return tx;
}

-(void)transformContext:(CGContextRef)context
{
    CGAffineTransform tx = [self layerTransform];
    CGContextTranslateCTM(context,xoff,yoff);

    CGContextTranslateCTM(context,(width/2),(height/2));
    CGContextConcatCTM(context,tx);
    CGContextTranslateCTM(context,-(width/2),-(height/2));

    CGContextTranslateCTM(context,0,height);
    CGContextScaleCTM(context,1,-1);
}

- (void)drawContent:(CGContextRef)context
{
    CGImageRef img = [self bitmap];
    CGContextDrawImage(context, CGRectMake(0,0,width,height), img);
    CGImageRelease(img);
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

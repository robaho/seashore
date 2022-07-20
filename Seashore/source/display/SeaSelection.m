#import "SeaSelection.h"
#import "SeaView.h"
#import "SeaDocument.h"
#import "SeaFlip.h"
#import "SeaHelpers.h"
#import "SeaOperations.h"
#import "SeaContent.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "SeaLayer.h"
#import "SeaWhiteboard.h"
#import "SeaFlip.h"
#import <SeaLibrary/ConnectedComponents.h>
#import <Accelerate/Accelerate.h>
#import <CoreImage/CoreImage.h>

@implementation SeaSelection

- (id)initWithDocument:(id)doc
{
	// Remember the document we are representing
	document = doc;
	
	// Sets the data members to appropriate initial values
	active = NO;
	mask = NULL;
    lastScale = -1;
	
	return self;
}

- (void)dealloc
{
	if (mask) free(mask);
    
    CGPathRelease(maskPath);
    CGImageRelease(maskImage);
}

- (BOOL)active
{
	return active;
}

- (unsigned char *)mask
{
	return mask;
}

- (IntRect)maskRect
{
    return maskRect;
}

- (BOOL)inSelection:(IntPoint)p
{
    if(!active || mask==NULL)
        return TRUE;
    if(!IntPointInRect(p, maskRect))
        return FALSE;
    int offset = (p.y - maskRect.origin.y)*maskRect.size.width + (p.x-maskRect.origin.x);
    return mask[offset]>0;

}

- (IntRect)localRect
{	
	SeaLayer *layer = [[document contents] activeLayer];
	IntRect localRect = IntOffsetRect(maskRect,-[layer xoff],-[layer yoff]);
    localRect = IntConstrainRect(localRect,IntMakeRect(0,0,[layer width],[layer height]));

	return localRect;
}

- (IntRect)globalRect
{
    SeaLayer *layer = [[document contents] activeLayer];
    return IntConstrainRect(maskRect,[layer globalRect]);
}

- (void)updateMaskImage
{
    CGImageRelease(maskImage);
    CGPathRelease(maskPath);

    maskImage=NULL;
    maskPath=NULL;
}

-(CGPathRef)maskPath
{
    if(maskPath==NULL && mask!=NULL) {
        CGPathRelease(maskPath);
        maskPath = [ConnectedComponents getPaths:mask width:maskRect.size.width height:maskRect.size.height];
    }
    return maskPath;
}

-(CGImageRef)maskImage
{
    if(maskImage==NULL && mask!=NULL) {
        int w = maskRect.size.width;
        int h = maskRect.size.height;
        CGContextRef ctx = CGBitmapContextCreate(mask, w, h, 8, w, grayCS, kCGImageAlphaOnly);
        maskImage = CGBitmapContextCreateImage(ctx);
        CGContextRelease(ctx);
    }
    return maskImage;
}

- (void)updateMaskFromPath:(NSBezierPath*)path mode:(int)mode {
    unsigned char *newMask, oldMaskPoint, newMaskPoint;
    IntRect newRect, oldRect;
    int tempMaskPoint, tempMaskProduct;
    int i, j;

    IntRect globalRect = NSRectMakeIntRect([path bounds]);

    if(!mask)
        mode = kDefaultMode;

    // Get the rectangles
    if(mode){
        oldRect = maskRect;
        newRect = globalRect;
        maskRect = IntSumRects(maskRect, newRect);
    } else {
        newRect = maskRect = globalRect;
    }
    
    active = NO;
    
    int mwidth = maskRect.size.width;
    int mheight = maskRect.size.height;
    
    newMask = malloc(mwidth*mheight);
    CHECK_MALLOC(newMask);
    memset(newMask,0,mwidth*mheight);
    
    if(mwidth>0 && mheight>0) {
        NSBitmapImageRep *maskRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&newMask pixelsWide:mwidth pixelsHigh:mheight bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:MyGraySpace bytesPerRow:mwidth bitsPerPixel:8];

        [NSGraphicsContext saveGraphicsState];
        NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:maskRep];
        [NSGraphicsContext setCurrentContext:ctx];
        NSAffineTransform *transform = [NSAffineTransform transform];
        
        [transform translateXBy:0 yBy:mheight];
        [transform scaleXBy:1 yBy:-1];
        
        [transform translateXBy:(-maskRect.origin.x) yBy:(-maskRect.origin.y)];
        [transform concat];

        [[NSColor whiteColor] setFill];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
    }
    
    if(mode){
        // copy old mask into new
        for (i = 0; i < maskRect.size.width; i++) {
            for (j = 0; j < maskRect.size.height; j++) {
                newMaskPoint = newMask[j * maskRect.size.width + i];

                // If we are in the rect of the old mask
                if(j >= oldRect.origin.y - maskRect.origin.y && j < oldRect.origin.y - maskRect.origin.y + oldRect.size.height
                   && i >= oldRect.origin.x - maskRect.origin.x && i < oldRect.origin.x - maskRect.origin.x + oldRect.size.width)
                    oldMaskPoint = mask[(j - oldRect.origin.y + maskRect.origin.y) * oldRect.size.width + (i - oldRect.origin.x + maskRect.origin.x)];
                else
                    oldMaskPoint = 0x00;
                
                // Do the math
                switch(mode){
                    case kAddMode:
                        tempMaskPoint = oldMaskPoint + newMaskPoint;
                        if(tempMaskPoint > 0xFF)
                            tempMaskPoint = 0xFF;
                        newMaskPoint = (unsigned char)tempMaskPoint;
                        break;
                    case kSubtractMode:
                        tempMaskPoint = oldMaskPoint - newMaskPoint;
                        if(tempMaskPoint < 0x00)
                            tempMaskPoint = 0x00;
                        newMaskPoint = (unsigned char)tempMaskPoint;
                        break;
                    case kMultiplyMode:
                        tempMaskPoint = oldMaskPoint * newMaskPoint;
                        tempMaskPoint /= 0xFF;
                        newMaskPoint = (unsigned char)tempMaskPoint;
                        break;
                    case kSubtractProductMode:
                        tempMaskProduct = oldMaskPoint * newMaskPoint;
                        tempMaskProduct /= 0xFF;
                        tempMaskPoint = oldMaskPoint + newMaskPoint;
                        if(tempMaskPoint > 0xFF)
                            tempMaskPoint = 0xFF;
                        tempMaskPoint -= tempMaskProduct;
                        if(tempMaskPoint < 0x00)
                            tempMaskPoint = 0x00;
                        newMaskPoint = (unsigned char)tempMaskPoint;
                        break;
                    default:
                        NSLog(@"Selection mode not supported.");
                        break;
                }
                newMask[j * maskRect.size.width + i] = newMaskPoint;
                if(newMaskPoint > 0x00)
                    active=YES;
            }
        }
    } else {
        if (maskRect.size.width > 0 && maskRect.size.height > 0)
            active = YES;
    }
    
    // Free previous mask information
    if (mask) { free(mask); mask = NULL; }

    if(active){
        mask = newMask;
        [self trimSelection];
        [self updateMaskImage];
    }else{
        free(newMask);
    }
    
    // Update the changes
    [[document helpers] selectionChanged];
}

- (void)selectRect:(IntRect)selectionRect mode:(int)mode
{
    [self selectRoundedRect:selectionRect radius:0 mode:mode];
}

- (void)selectEllipse:(IntRect)selectionRect mode:(int)mode
{
    NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(selectionRect.origin.x,selectionRect.origin.y,selectionRect.size.width, selectionRect.size.height)];
    [self updateMaskFromPath:path mode:mode];
}

- (void)selectRoundedRect:(IntRect)selectionRect radius:(int)radius mode:(int)mode
{
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(selectionRect.origin.x,selectionRect.origin.y,selectionRect.size.width, selectionRect.size.height) xRadius:radius yRadius:radius];
    [self updateMaskFromPath:path mode:mode];
}

- (void)selectPath:(NSBezierPath*)path mode:(int)mode
{
    IntRect rect = NSRectMakeIntRect([path bounds]);
    [self updateMaskFromPath:path mode:mode];
}

- (void)selectOverlay:(IntRect)localRect mode:(int)mode
{
	SeaLayer *layer = [[document contents] activeLayer];
	int width = [layer width];
    int height = [layer height];
	int i, j, spp = [[document contents] spp];

	unsigned char *overlay, *newMask, oldMaskPoint, newMaskPoint;
	int tempMask, tempMaskProduct;

    IntRect newRect = IntOffsetRect(localRect,[layer xoff],[layer yoff]);
    IntRect overlayRect = [layer globalRect];
    IntRect oldRect;

	if(!mask || !active){
		mode = kDefaultMode;
        maskRect = newRect;
	}else {
		oldRect = maskRect;
		maskRect = IntSumRects(maskRect,newRect);
	}

	if(!mode)
		active = YES;
	else
		active = NO;
	
	newMask = calloc(maskRect.size.width * maskRect.size.height,1);
	overlay = [[document whiteboard] overlay];
	for (i = maskRect.origin.x; i < maskRect.size.width + maskRect.origin.x; i++) {
		for (j = maskRect.origin.y; j < maskRect.size.height + maskRect.origin.y; j++) {
            IntPoint p = IntMakePoint(i,j);
            if(!IntPointInRect(p,overlayRect)) {
                continue;
            }

            int x = i - [layer xoff], y = j - [layer yoff];
            int maskOffset = (j - maskRect.origin.y) * maskRect.size.width + i - maskRect.origin.x;

			if(mode){
				// Find the mask of the new point
                if(IntPointInRect(p,newRect)) {
                    // overlay data is layer based, selection is global
					newMaskPoint = overlay[(y  * width + x) * spp + (spp - 1)];
                    overlay[(y  * width + x) * spp + (spp - 1)] = 0;
                } else
					newMaskPoint = 0x00;

				// Find the mask of the old point
                if(IntPointInRect(p,oldRect))
					oldMaskPoint = mask[((j - oldRect.origin.y )* oldRect.size.width + i - oldRect.origin.x )];
				else
					oldMaskPoint = 0x00;
				
				// Do the math
				switch(mode){
					case kAddMode:
						tempMask = oldMaskPoint + newMaskPoint;
						if(tempMask > 0xFF)
							tempMask = 0xFF;
						newMaskPoint = (unsigned char)tempMask;
					break;
					case kSubtractMode:
						tempMask = oldMaskPoint - newMaskPoint;
						if(tempMask < 0x00)
							tempMask = 0x00;
						newMaskPoint = (unsigned char)tempMask;
					break;
					case kMultiplyMode:
						tempMask = oldMaskPoint * newMaskPoint;
						tempMask /= 0xFF;
						newMaskPoint = (unsigned char)tempMask;
					break;
					case kSubtractProductMode:
						tempMaskProduct = oldMaskPoint * newMaskPoint;
						tempMaskProduct /= 0xFF;
						tempMask = oldMaskPoint + newMaskPoint;
						if(tempMask > 0xFF)
							tempMask = 0xFF;
						tempMask -= tempMaskProduct;	
						if(tempMask < 0x00)
							tempMask = 0x00;
						newMaskPoint = (unsigned char)tempMask;
					break;
					default:
						NSLog(@"Selection mode not supported.");
					break;
				}
				newMask[maskOffset] = newMaskPoint;
				if(newMaskPoint > 0x00)
					active=YES;
			}else{
                int offset = (y * width + x + 1) * spp - 1;
				newMask[maskOffset] = overlay[offset];
                overlay[offset] = 0;
			}
			
		}
	}
	
	// Free previous mask information 
	if (mask) { free(mask); mask = NULL; }

	if(active){
		mask = newMask;
		[self trimSelection];
	}else{
		free(newMask);
	}

	// Update the changes
    [self updateMaskImage];
	[[document helpers] selectionChanged];
}

- (void)selectOpaque
{
    [[document helpers] endLineDrawing];

	SeaLayer *layer = [[document contents] activeLayer];
	unsigned char *data = [layer data];
	int spp = [[document contents] spp], i;

	// Free previous mask information
	if (mask) { free(mask); mask = NULL; }

	// Activate the selection
	active = YES;

    maskRect = IntMakeRect([layer xoff],[layer yoff],[layer width],[layer height]);

	// Make the mask
	mask = malloc(maskRect.size.width * maskRect.size.height);
	for (i = 0; i < maskRect.size.width * maskRect.size.height; i++) {
		mask[i] = data[(i + 1) * spp - 1];
	}
	[self trimSelection];
	[self updateMaskImage];
	
	// Make the change
	[[document helpers] selectionChanged];
}

- (void)moveSelection:(IntPoint)newOrigin fromOrigin:(IntPoint)origin
{
    IntRect old = maskRect;
    maskRect = IntOffsetRect(maskRect,newOrigin.x-origin.x,newOrigin.y-origin.y);

    [[document helpers] selectionChanged:IntSumRects(old,maskRect)];
}

- (void)clearSelection
{
    active = NO;
    if (mask) { free(mask); mask = NULL; }
    maskRect = IntZeroRect;
    [[document helpers] selectionChanged];
}

- (void)invertSelection
{
    [[document helpers] endLineDrawing];

    int width = [(SeaContent*)[document contents] width];
    int height = [(SeaContent*)[document contents] height];

    bool done;

    IntRect old = maskRect;

	// Deal with simple inversions first
	if (!mask) {
		if (maskRect.origin.x == 0 && maskRect.origin.y == 0) {
			if (maskRect.size.width == width) {
				maskRect = IntMakeRect(0, maskRect.size.height, width, height - maskRect.size.height);
				done = YES;
			}
			else if (maskRect.size.height == height) {
				maskRect = IntMakeRect(maskRect.size.width, 0, width - maskRect.size.width, height);
				done = YES;
			}
		}
		else if (maskRect.origin.x + maskRect.size.width == width && maskRect.size.height == height) {
			maskRect = IntMakeRect(0, 0, maskRect.origin.x, height);
			done = YES;
		}
		else if (maskRect.origin.y + maskRect.size.height == height && maskRect.size.width == width) {
			maskRect = IntMakeRect(0, 0, width, maskRect.origin.y);
			done = YES;
		}
	}
	
	// Then if that didn't work we have a complex inversions
	if (!done) {
		unsigned char *newMask = malloc(width * height);
		memset(newMask, 0xFF, width * height);
		for (int j = 0; j < maskRect.size.height; j++) {
			for (int i = 0; i < maskRect.size.width; i++) {
				if (mask) {
					if ((maskRect.origin.y) + j >= 0 && (maskRect.origin.y) + j < height &&
						(maskRect.origin.x) + i >= 0 && (maskRect.origin.x) + i < width) {
						int src = j * maskRect.size.width + i;
						int dest = ((maskRect.origin.y) + j) * width + (maskRect.origin.x) + i;
						newMask[dest] = 0xFF - mask[src];
					}
				}
				else {
					newMask[((maskRect.origin.y) + j) * width + (maskRect.origin.x) + i] = 0x00;
				}
			}
		}
		maskRect = IntMakeRect(0, 0, width, height);
		free(mask);
		mask = newMask;
	}
	
	// Finally clean everything up
	if (maskRect.size.width > 0 && maskRect.size.height > 0) {
		active = YES;
		[self trimSelection];
	}
	else {
		active = NO;
	}
    [self updateMaskImage];
    [[document helpers] selectionChanged:IntSumRects(old,maskRect)];
}

- (void)flipSelection:(int)type
{
    [[document helpers] endLineDrawing];

	unsigned char tmp;
	int i, j, src, dest;

    IntRect rect = maskRect;
	
	// There's nothing to do if there's no mask
	if (mask) {
	
		if (type == kHorizontalFlip) {
			for (i = 0; i < rect.size.width / 2; i++) {
				for (j = 0; j < rect.size.height; j++) {
					src = j * rect.size.width + rect.size.width - i - 1;
					dest = j * rect.size.width + i;
					tmp = mask[dest];
					mask[dest] = mask[src];
					mask[src] = tmp;
				}
			}
		}
		else {
			for (i = 0; i < rect.size.width; i++) {
				for (j = 0; j < rect.size.height / 2; j++) {
					src = (rect.size.height - j - 1) * rect.size.width + i;
					dest = j * rect.size.width + i;
					tmp = mask[dest];
					mask[dest] = mask[src];
					mask[src] = tmp;
				}
			}
		}
		
		[self trimSelection];
		[self updateMaskImage];
        [[document helpers] selectionChanged:maskRect];

	}
}

- (int)localOffset
{
    IntRect gr = [self globalRect];
    IntRect mr = [self maskRect];

    int offset = (gr.origin.y - mr.origin.y) * maskRect.size.width + gr.origin.x - mr.origin.x;
    return offset;
}

- (unsigned char *)selectionData
{
	SeaLayer *layer = [[document contents] activeLayer];
	int spp = [[document contents] spp], width = [layer width];
	unsigned char *destPtr, *srcPtr;

	IntRect localRect = [self localRect];
    IntRect maskRect = [self maskRect];

    int maskOffset = [self localOffset];

	int i, j, selectedChannel, t1;
	
	// Get the selected channel
	selectedChannel = [[document contents] selectedChannel];
	
	// Copy the image data
	destPtr = malloc(make_128(localRect.size.width * localRect.size.height * spp));
    CHECK_MALLOC(destPtr);

    srcPtr = [layer data] + (width*localRect.origin.y+localRect.origin.x)*spp;
    
	for (j = 0; j < localRect.size.height; j++) {
		for (i = 0; i < localRect.size.width; i++) {
            unsigned maskVal = mask[maskOffset + j * maskRect.size.width + i];
            unsigned char *dptr = destPtr+(j * localRect.size.width + i)*spp;
			switch (selectedChannel) {
				case kAllChannels:
                    memcpy(dptr,srcPtr+(j * width + i)*spp,spp);
					dptr[spp-1] = int_mult(dptr[spp-1], maskVal, t1);
				break;
				case kPrimaryChannels:
                    memcpy(dptr,srcPtr+(j * width + i)*spp,spp);
                    dptr[spp-1] = maskVal;
				break;
				case kAlphaChannel:
                    memcpy(dptr,srcPtr+(j * width + i)*spp + spp - 1,spp-1);
                    dptr[spp-1] = maskVal;
				break;
			}
		}
	}

	return destPtr;
}

- (BOOL)selectionSizeMatch:(IntSize)inp_size
{
	if (inp_size.width == sel_size.width && inp_size.height == sel_size.height)
		return YES;
	else
		return NO;
}

- (IntPoint)selectionPoint
{
	return sel_point;
}

- (void)cutSelection
{
	[self copySelection];
	[self deleteSelection];
}

- (void)copySelection
{
	id pboard = [NSPasteboard generalPasteboard];
	int spp = [[document contents] spp], i;

    IntRect localRect = [self localRect];

	if (active) {
	
		// Get the selection data 
		unsigned char *data = [self selectionData];
		
		// Check for nothingness
		BOOL containsNothing = YES;
		for (i = 0; containsNothing && (i < localRect.size.width * localRect.size.height); i++) {
			if (data[(i + 1) * spp - 1] != 0x00)
				containsNothing = NO;
		}
		if (containsNothing) {
			free(data);
			NSRunAlertPanel(LOCALSTR(@"empty selection copy title", @"Selection empty"), LOCALSTR(@"empty selection copy body", @"The selection cannot be copied since it is empty."), LOCALSTR(@"ok", @"OK"), NULL, NULL);
			return;
		}
		
		// Declare the data being added to the pasteboard
		[pboard declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:NULL];

        premultiplyBitmap(spp,data,data, localRect.size.width*localRect.size.height);

		// Add it to the pasteboard
		NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data pixelsWide:localRect.size.width pixelsHigh:localRect.size.height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? MyRGBSpace : MyGraySpace bytesPerRow:localRect.size.width * spp bitsPerPixel:8 * spp];

		[pboard setData:[imageRep TIFFRepresentation] forType:NSTIFFPboardType];

        free(data);
		
		// Stores the point of the last copied selection and its size
		sel_point = maskRect.origin;
		sel_size = maskRect.size;
	}
}

- (void)deleteSelection
{
	IntRect localRect = [self localRect];

	CGColorRef color = [[[document contents] background] CGColor];

    SeaLayer *layer = [[document contents] activeLayer];

	if ([layer hasAlpha])
		[[document whiteboard] setOverlayBehaviour:kErasingBehaviour];
	[[document whiteboard] setOverlayOpacity:255];

    CGContextRef ctx = [[document whiteboard] overlayCtx];
    CGContextSetFillColorWithColor(ctx,color);
    CGContextFillRect(ctx,IntRectMakeNSRect(localRect));

    [[document helpers] overlayChanged:localRect];
	[[document helpers] applyOverlay];
}

- (void)adjustOffset:(IntPoint)offset
{
    maskRect = IntOffsetRect(maskRect,offset.x,offset.y);
}

- (void)scaleSelectionHorizontally:(float)xScale vertically:(float)yScale interpolation:(int)interpolation
{
	IntRect newRect;
	
	if (active) {
        IntRect rect = [self localRect];
	
		// Work out the new rectangle and allocate space for the new mask
		newRect = rect;
		newRect.origin.x *= xScale;
		newRect.origin.y *= yScale;
		newRect.size.width *= xScale;
		newRect.size.height *= yScale;
		[self scaleSelectionTo: newRect from: rect interpolation: interpolation usingMask: NULL];
	}
}

- (void)scaleSelectionTo:(IntRect)newRect from: (IntRect)oldRect interpolation:(int)interpolation usingMask: (unsigned char*)oldMask
{
	BOOL hFlip = NO;
	BOOL vFlip = NO;
	unsigned char *newMask;

    IntRect oldMaskRect = maskRect;

	if(active && newRect.size.width != 0 && newRect.size.height != 0){
		// Create the new mask (if required)
		if(newRect.size.width < 0){
			newRect.origin.x += newRect.size.width;
			newRect.size.width *= -1;
			hFlip = YES;
		}

		if(newRect.size.height < 0){
			newRect.origin.y += newRect.size.height;
			newRect.size.height *= -1;
			vFlip = YES;
		}
		if(!oldMask)
			oldMask = mask;
		
		if (oldMask) {

            newMask = calloc(newRect.size.width * newRect.size.height,1);

            vImage_Buffer src;
            src.data=oldMask;
            src.height=oldRect.size.height;
            src.width=oldRect.size.width;
            src.rowBytes=oldRect.size.width;

            vImage_Buffer dest;
            dest.data=newMask;
            dest.height=newRect.size.height;
            dest.width=newRect.size.width;
            dest.rowBytes=newRect.size.width;

            vImageScale_Planar8(&src, &dest, NULL, kvImageNoFlags);

            if (vFlip) {
                vImageVerticalReflect_Planar8(&dest, &dest,0);
            }

            if (hFlip) {
                vImageHorizontalReflect_Planar8(&dest, &dest,0);
            }

			free(mask);
			mask = newMask;
		}
					
        maskRect = newRect;
        [self updateMaskImage];
        [[document helpers] selectionChanged:IntSumRects(oldMaskRect,maskRect)];
	}
}

- (void)trimSelection
{
	int selectionLeft = -1, selectionRight = -1, selectionTop = -1, selectionBottom = -1;
	int newWidth, newHeight, i, j;
	unsigned char *newMask;
	BOOL fullyOpaque = YES;

    if(!mask)
        return;

    IntRect rect = maskRect;
    
    // Determine left selection margin (do not swap iteration order)
    for (i = 0; i < rect.size.width && selectionLeft == -1; i++) {
        for (j = 0; j < rect.size.height && selectionLeft == -1; j++) {
            if (mask[j * rect.size.width + i] != 0) {
                selectionLeft = i;
            }
        }
    }

    // Determine right selection margin (do not swap iteration order)
    for (i = rect.size.width - 1; i >= 0 && selectionRight == -1; i--) {
        for (j = 0; j < rect.size.height && selectionRight == -1; j++) {
            if (mask[j * rect.size.width + i] != 0) {
                selectionRight = rect.size.width - 1 - i;
            }
        }
    }

    // Determine top selection margin (do not swap iteration order)
    for (j = 0; j < rect.size.height && selectionTop == -1; j++) {
        for (i = 0; i < rect.size.width && selectionTop == -1; i++) {
            if (mask[j * rect.size.width + i] != 0) {
                selectionTop = j;
            }
        }
    }

    // Determine bottom selection margin (do not swap iteration order)
    for (j = rect.size.height - 1; j >= 0 && selectionBottom == -1; j--) {
        for (i = 0; i < rect.size.width && selectionBottom == -1; i++) {
            if (mask[j * rect.size.width + i] != 0) {
                selectionBottom = rect.size.height - 1 - j;
            }
        }
    }

    if(selectionLeft==-1 || selectionRight==-1 || selectionTop==-1 || selectionBottom==-1){
        // entire mask is 0 alpha don't trim anything
        return;
    }

    // Check the mask for fully opacity
    newWidth = rect.size.width - selectionLeft - selectionRight;
    newHeight = rect.size.height - selectionTop - selectionBottom;
    for (j = 0; j < newHeight && fullyOpaque; j++) {
        for (i = 0; i < newWidth && fullyOpaque; i++) {
            if (mask[(j + selectionTop) * rect.size.width + (i + selectionLeft)] != 255) {
                fullyOpaque = NO;
            }
        }
    }

    // If the revised mask is fully opaque
    if (fullyOpaque) {

        // Remove the mask and make the change
        newMask = malloc(newWidth * newHeight);
        memset(newMask, 0xFF, newWidth * newHeight);
        free(mask);
        mask = newMask;
    }
    else {

        // Calculate the new mask
        newMask = malloc(newWidth * newHeight);
        for (j = 0; j < newHeight; j++) {
            for (i = 0; i < newWidth; i++) {
                newMask[j * newWidth + i] = mask[(j + selectionTop) * rect.size.width + (i + selectionLeft)];
            }
        }

        // Finally make the change
        free(mask);
        mask = newMask;
    }

    maskRect = IntMakeRect(rect.origin.x + selectionLeft, rect.origin.y + selectionTop, newWidth, newHeight);
}

@end

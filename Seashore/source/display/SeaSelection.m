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
#import "Bitmap.h"
#import "SeaWhiteboard.h"
#import "SeaFlip.h"
#import <GIMPCore/GIMPCore.h>

@implementation SeaSelection

- (id)initWithDocument:(id)doc
{
	// Remember the document we are representing
	document = doc;
	
	// Sets the data members to appropriate initial values
	active = NO;
	mask = NULL;
	
	return self;
}

- (void)dealloc
{
	if (mask) free(mask);
	if (maskBitmap) { free(maskBitmap); [maskImage autorelease]; }
	[super dealloc];
}

- (BOOL)active
{
	return active;
}

- (BOOL)floating
{
	return [[[document contents] activeLayer] floating];
}

- (unsigned char *)mask
{
	return mask;
}

- (NSImage *)maskImage
{
	int i;
	unsigned char basePixel[3];
	id selectionColor;
	
	if (maskImage && selectionColorIndex != [[SeaController seaPrefs] selectionColorIndex]) {
		selectionColor = [[SeaController seaPrefs] selectionColor:0.4];
		basePixel[0] = roundf([selectionColor redComponent] * 255.0);
		basePixel[1] = roundf([selectionColor greenComponent] * 255.0);
		basePixel[2] = roundf([selectionColor blueComponent] * 255.0);
		for (i = 0; i < rect.size.width * rect.size.height; i++) {
			maskBitmap[i * 4] = basePixel[0];
			maskBitmap[i * 4 + 1] = basePixel[1];
			maskBitmap[i * 4 + 2] = basePixel[2];
		}
		premultiplyBitmap(4, maskBitmap, maskBitmap, rect.size.width * rect.size.height);
		selectionColorIndex = [[SeaController seaPrefs] selectionColorIndex];
	}
	[maskImage setFlipped:YES];
	
	return maskImage;
}

- (IntPoint)maskOffset
{
	return IntMakePoint(globalRect.origin.x - rect.origin.x, globalRect.origin.y - rect.origin.y);
}

- (IntSize)maskSize
{
	return IntMakeSize(rect.size.width, rect.size.height);
}

- (IntRect)trueLocalRect
{
	id layer = [[document contents] activeLayer];
	IntRect localRect = rect;
	
	localRect.origin.x -= [layer xoff];
	localRect.origin.y -= [layer yoff];
	
	return localRect;
}

- (IntRect)globalRect
{
	return globalRect;
}

- (IntRect)localRect
{	
	id layer = [[document contents] activeLayer];
	IntRect localRect = globalRect;
	
	localRect.origin.x -= [layer xoff];
	localRect.origin.y -= [layer yoff];
	
	return localRect;
}

- (void)updateMaskImage
{
	int i;
	unsigned char basePixel[3];
	id selectionColor;
	
	if (mask) {
		selectionColorIndex = [[SeaController seaPrefs] selectionColorIndex];
		selectionColor = [[SeaController seaPrefs] selectionColor:0.4];
		maskBitmap = malloc(rect.size.width * rect.size.height * 4);
		basePixel[0] = roundf([selectionColor redComponent] * 255.0);
		basePixel[1] = roundf([selectionColor greenComponent] * 255.0);
		basePixel[2] = roundf([selectionColor blueComponent] * 255.0);
		for (i = 0; i < rect.size.width * rect.size.height; i++) {
			maskBitmap[i * 4] = basePixel[0];
			maskBitmap[i * 4 + 1] = basePixel[1];
			maskBitmap[i * 4 + 2] = basePixel[2];
			maskBitmap[i * 4 + 3] = 0xFF - mask[i];
		}
		premultiplyBitmap(4, maskBitmap, maskBitmap, rect.size.width * rect.size.height);
		maskBitmapRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&maskBitmap pixelsWide:rect.size.width pixelsHigh:rect.size.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:rect.size.width * 4 bitsPerPixel:8 * 4];
		maskImage = [[NSImage alloc] init];
		[maskImage addRepresentation:maskBitmapRep];
		[maskBitmapRep autorelease];
	}
}

- (void)selectRect:(IntRect)selectionRect mode:(int)mode
{
	id layer = [[document contents] activeLayer];
	int width = [(SeaLayer *)layer width], height = [(SeaLayer *)layer height];
	unsigned char *newMask, oldMaskPoint, newMaskPoint;
	IntRect newRect, oldRect;
	int tempMaskPoint, tempMaskProduct;
	int i, j;

	if(!mask)
		mode = kDefaultMode;
	
	// Get the rectangles
	if(mode){
		oldRect = [self localRect];
		newRect = IntConstrainRect(selectionRect, IntMakeRect(0, 0, width, height));
		rect = IntSumRects(oldRect, newRect);
	} else {
		rect = IntConstrainRect(selectionRect, IntMakeRect(0, 0, width, height));
	}

	active = NO;
	
	// Draw the circle
	newMask = malloc(rect.size.width * rect.size.height);

	if(mode){
		memset(newMask, 0x00, rect.size.width * rect.size.height);
		for (i = 0; i < rect.size.width; i++) {
			for (j = 0; j < rect.size.height; j++) {
				// If we are in the rectangle of the new selection
				if(j >= newRect.origin.y - rect.origin.y && j < newRect.origin.y - rect.origin.y + newRect.size.height
				&& i >= newRect.origin.x - rect.origin.x && i < newRect.origin.x - rect.origin.x + newRect.size.width)
					newMaskPoint = 0xFF;
				else
					newMaskPoint = 0x00;

				// If we are in the rect of the old mask
				if(j >= oldRect.origin.y - rect.origin.y && j < oldRect.origin.y - rect.origin.y + oldRect.size.height
				&& i >= oldRect.origin.x - rect.origin.x && i < oldRect.origin.x - rect.origin.x + oldRect.size.width)
					oldMaskPoint = mask[(j - oldRect.origin.y + rect.origin.y) * oldRect.size.width + (i - oldRect.origin.x + rect.origin.x)];
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
				newMask[j * rect.size.width + i] = newMaskPoint;
				if(newMaskPoint > 0x00)
					active=YES;
			}
		}
	} else {
		memset(newMask, 0xFF, rect.size.width * rect.size.height);
		if (rect.size.width > 0 && rect.size.height > 0)
			active = YES;
	}
		
	// Free previous mask information 
	if (mask) { free(mask); mask = NULL; }
	if (maskBitmap) { free(maskBitmap); maskBitmap = NULL; [maskImage autorelease]; maskImage = NULL; }

	// Commit the new stuff
	rect.origin.x += [layer xoff];
	rect.origin.y += [layer yoff];
	globalRect = rect;
		
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

- (void)selectEllipse:(IntRect)selectionRect mode:(int)mode
{
	id layer = [[document contents] activeLayer];
	int width = [(SeaLayer *)layer width], height = [(SeaLayer *)layer height];
	unsigned char *newMask, *tempMask, oldMaskPoint, newMaskPoint;
	IntRect newRect, oldRect, tempRect;
	int tempMaskPoint, tempMaskProduct;
	int i, j;

	if(!mask)
		mode = kDefaultMode;

	// Get the rectangles
	if(mode){
		oldRect = [self localRect];
		newRect = selectionRect;
		rect = IntSumRects(oldRect, newRect);
	} else {
		rect = selectionRect;
	}

	active = NO;
	
	// Draw the circle
	newMask = malloc(rect.size.width * rect.size.height);
	memset(newMask, 0x00, rect.size.width * rect.size.height);
	GCDrawEllipse(newMask, rect.size.width, rect.size.height, IntMakeRect(selectionRect.origin.x-rect.origin.x, selectionRect.origin.y-rect.origin.y, selectionRect.size.width, selectionRect.size.height), YES);
	
	// Constrain to the layer
	if(rect.origin.x + rect.size.width > width || rect.origin.y + rect.size.height > height || rect.origin.x < 0 || rect.origin.y < 0){
		tempRect = IntConstrainRect(rect, IntMakeRect(0, 0, width, height));
		tempMask = malloc(tempRect.size.width * tempRect.size.height);
		memset(tempMask, 0x00, tempRect.size.width * tempRect.size.height);
	
		for (i = 0; i < tempRect.size.width; i++) {
			for (j = 0; j < tempRect.size.height; j++) {
				tempMask[(j  * tempRect.size.width + i)] =  newMask[(j - rect.origin.y + tempRect.origin.y) * rect.size.width + i - rect.origin.x + tempRect.origin.x];
			}
		}
		
		rect = tempRect;
		free(newMask);		
		newMask = tempMask;
	}

	if(mode){
		for (i = 0; i < rect.size.width; i++) {
			for (j = 0; j < rect.size.height; j++) {
				newMaskPoint = newMask[j * rect.size.width + i];
				
				// If we are in the rect of the old mask
				if(j >= oldRect.origin.y - rect.origin.y && j < oldRect.origin.y - rect.origin.y + oldRect.size.height
				&& i >= oldRect.origin.x - rect.origin.x && i < oldRect.origin.x - rect.origin.x + oldRect.size.width)
					oldMaskPoint = mask[(j - oldRect.origin.y + rect.origin.y) * oldRect.size.width + (i - oldRect.origin.x + rect.origin.x)];
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
				newMask[j * rect.size.width + i] = newMaskPoint;
				if(newMaskPoint > 0x00)
					active=YES;
			}
		}
	} else {
		if (rect.size.width > 0 && rect.size.height > 0)
			active = YES;
	}
		
	// Free previous mask information 
	if (mask) { free(mask); mask = NULL; }
	if (maskBitmap) { free(maskBitmap); maskBitmap = NULL; [maskImage autorelease]; maskImage = NULL; }

	// Commit the new stuff
	rect.origin.x += [layer xoff];
	rect.origin.y += [layer yoff];
	globalRect = rect;
	
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

- (void)selectRoundedRect:(IntRect)selectionRect radius:(int)radius mode:(int)mode
{
	id layer = [[document contents] activeLayer];
	int width = [(SeaLayer *)layer width], height = [(SeaLayer *)layer height];
	unsigned char *newMask, *tempMask, oldMaskPoint, newMaskPoint;
	IntRect newRect, oldRect, tempRect, trect;
	int tempMaskPoint, tempMaskProduct;
	int i, j;

	if(!mask)
		mode = kDefaultMode;

	// Get the rectangles
	if(mode){
		oldRect = [self localRect];
		newRect = selectionRect;
		rect = IntSumRects(oldRect, newRect);
	} else {
		newRect = rect = selectionRect;
	}

	active = NO;
	
	// Draw the circle
	newMask = malloc(rect.size.width * rect.size.height);
	memset(newMask, 0x00, rect.size.width * rect.size.height);

	if (newRect.size.width < 2 * radius && newRect.size.height < 2 * radius) {
		GCDrawEllipse(newMask, rect.size.width, rect.size.height, IntMakeRect(newRect.origin.x-rect.origin.x, newRect.origin.y-rect.origin.y, newRect.size.width, newRect.size.height), YES);
	}
	else if (newRect.size.height < 2 * radius) {
		trect = IntMakeRect(newRect.origin.x-rect.origin.x, newRect.origin.y-rect.origin.y, newRect.size.height, newRect.size.height);
		GCDrawEllipse(newMask, rect.size.width, rect.size.height, trect, YES);
		trect = IntMakeRect(newRect.origin.x + newRect.size.width - newRect.size.height - rect.origin.x, newRect.origin.y-rect.origin.y, newRect.size.height, newRect.size.height);
		GCDrawEllipse(newMask, rect.size.width, rect.size.height, trect, YES);
		for (i = newRect.origin.y - rect.origin.y; i < newRect.size.height + newRect.origin.y - rect.origin.y; i++) memset(newMask + i * rect.size.width + newRect.size.height / 2 + newRect.origin.x - rect.origin.x, 0xFF, newRect.size.width - newRect.size.height);
	}
	else if (newRect.size.width < 2 * radius) {
		trect = IntMakeRect(newRect.origin.x-rect.origin.x, newRect.origin.y-rect.origin.y, newRect.size.width, newRect.size.width);
		GCDrawEllipse(newMask, rect.size.width, rect.size.height, trect, YES);
		trect = IntMakeRect(newRect.origin.x-rect.origin.x, newRect.origin.y + newRect.size.height - newRect.size.width-rect.origin.y, newRect.size.width, newRect.size.width);
		GCDrawEllipse(newMask, rect.size.width, rect.size.height, trect, YES);
		for (i = newRect.size.width / 2 + newRect.origin.y - rect.origin.y; i < newRect.size.height - newRect.size.width / 2; i++) memset(newMask + i * rect.size.width + newRect.origin.x - rect.origin.x, 0xFF, newRect.size.width);
	}
	else {
		trect = IntMakeRect(newRect.origin.x-rect.origin.x, newRect.origin.y-rect.origin.y, 2 * radius, 2 * radius);
		GCDrawEllipse(newMask, rect.size.width, rect.size.height, trect, YES);
		trect = IntMakeRect(newRect.size.width - 2 * radius + newRect.origin.x - rect.origin.x, newRect.origin.y -rect.origin.y, 2 * radius, 2 * radius);
		GCDrawEllipse(newMask, rect.size.width, rect.size.height, trect, YES);
		trect = IntMakeRect(newRect.origin.x - rect.origin.x, newRect.size.height - 2 * radius + newRect.origin.y - rect.origin.y, 2 * radius, 2 * radius);
		GCDrawEllipse(newMask, rect.size.width, rect.size.height, trect, YES);
		trect = IntMakeRect(newRect.size.width - 2 * radius + newRect.origin.x -rect.origin.x, newRect.size.height - 2 * radius + newRect.origin.y - rect.origin.y, 2 * radius, 2 * radius);
		GCDrawEllipse(newMask, rect.size.width, rect.size.height, trect, YES);
		for (i = newRect.origin.y - rect.origin.y; i < newRect.size.height + newRect.origin.y - rect.origin.y; i++) memset(newMask + i * rect.size.width + radius + newRect.origin.x - rect.origin.x, 0xFF, newRect.size.width - 2 * radius);
		for (i = radius + newRect.origin.y - rect.origin.y; i < newRect.size.height - radius + newRect.origin.y - rect.origin.y; i++) {
			memset(newMask + i * rect.size.width + newRect.origin.x - rect.origin.x, 0xFF, radius);
			memset(newMask + i * rect.size.width + newRect.size.width - radius + newRect.origin.x - rect.origin.x, 0xFF, radius);
		}
	}
	
	// Constrain to the layer
	if(rect.origin.x + rect.size.width > width || rect.origin.y + rect.size.height > height || rect.origin.x < 0 || rect.origin.y < 0){
		tempRect = IntConstrainRect(rect, IntMakeRect(0, 0, width, height));
		tempMask = malloc(tempRect.size.width * tempRect.size.height);
		memset(tempMask, 0x00, tempRect.size.width * tempRect.size.height);
	
		for (i = 0; i < tempRect.size.width; i++) {
			for (j = 0; j < tempRect.size.height; j++) {
				tempMask[(j  * tempRect.size.width + i)] =  newMask[(j - rect.origin.y + tempRect.origin.y) * rect.size.width + i - rect.origin.x + tempRect.origin.x];
			}
		}
		
		rect = tempRect;
		free(newMask);		
		newMask = tempMask;
	}

	if(mode){
		for (i = 0; i < rect.size.width; i++) {
			for (j = 0; j < rect.size.height; j++) {
				newMaskPoint = newMask[j * rect.size.width + i];
				
				// If we are in the rect of the old mask
				if(j >= oldRect.origin.y - rect.origin.y && j < oldRect.origin.y - rect.origin.y + oldRect.size.height
				&& i >= oldRect.origin.x - rect.origin.x && i < oldRect.origin.x - rect.origin.x + oldRect.size.width)
					oldMaskPoint = mask[(j - oldRect.origin.y + rect.origin.y) * oldRect.size.width + (i - oldRect.origin.x + rect.origin.x)];
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
				newMask[j * rect.size.width + i] = newMaskPoint;
				if(newMaskPoint > 0x00)
					active=YES;
			}
		}
	} else {
		if (rect.size.width > 0 && rect.size.height > 0)
			active = YES;
	}
		
	// Free previous mask information 
	if (mask) { free(mask); mask = NULL; }
	if (maskBitmap) { free(maskBitmap); maskBitmap = NULL; [maskImage autorelease]; maskImage = NULL; }

	// Commit the new stuff
	rect.origin.x += [layer xoff];
	rect.origin.y += [layer yoff];
	globalRect = rect;
	
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

- (void)selectOverlay:(BOOL)destructively inRect:(IntRect)selectionRect mode:(int)mode
{
	id layer = [[document contents] activeLayer];
	int width = [(SeaLayer *)layer width], height = [(SeaLayer *)layer height];
	int i, j, spp = [[document contents] spp];
	unsigned char *overlay, *newMask, oldMaskPoint, newMaskPoint;
	IntRect newRect, oldRect;
	int tempMask, tempMaskProduct;
	
	// Get the rectangles
	newRect = IntConstrainRect(selectionRect, IntMakeRect(0, 0, width, height));
	if(!mask || !active){
		mode = kDefaultMode;		
		rect = newRect;
	}else {
		oldRect = [self localRect];
		rect = IntSumRects(oldRect, newRect);		
	}

	if(!mode)
		active = YES;
	else
		active = NO;
	
	newMask = malloc(rect.size.width * rect.size.height);
	memset(newMask, 0x00, rect.size.width * rect.size.height);
	overlay = [[document whiteboard] overlay];
	for (i = rect.origin.x; i < rect.size.width + rect.origin.x; i++) {
		for (j = rect.origin.y; j < rect.size.height + rect.origin.y; j++) {
			if(mode){
				// Find the mask of the new point
				if(i >= newRect.origin.x && j >= newRect.origin.y && i < newRect.size.width + newRect.origin.x && j < newRect.size.height + newRect.origin.y)
					newMaskPoint = overlay[(j  * width + i) * spp + (spp - 1)];
				else
					newMaskPoint = 0x00;

				// Find the mask of the old point
				if(i >= oldRect.origin.x && j >= oldRect.origin.y && i < oldRect.size.width + oldRect.origin.x && j < oldRect.size.height + oldRect.origin.y)
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
				newMask[(j - rect.origin.y) * rect.size.width + i - rect.origin.x] = newMaskPoint;
				if(newMaskPoint > 0x00)
					active=YES;
			}else{
				// Store the new mask
				newMask[(j - rect.origin.y) * rect.size.width + i - rect.origin.x] = overlay[(j  * width + i) * spp + (spp - 1)];
			}
			
			if (destructively)
				overlay[(j * width + i) * spp + (spp - 1)] = 0x00;
		}
	}
	
	// Free previous mask information 
	if (mask) { free(mask); mask = NULL; }
	if (maskBitmap) { free(maskBitmap); maskBitmap = NULL; [maskImage autorelease]; maskImage = NULL; }

	// Commit the new stuff
	rect.origin.x += [layer xoff];
	rect.origin.y += [layer yoff];
	globalRect = rect;
	
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

- (void)selectOpaque
{
	id layer = [[document contents] activeLayer];
	unsigned char *data = [(SeaLayer *)layer data];
	int spp = [[document contents] spp], i;

	// Free previous mask information
	if (mask) { free(mask); mask = NULL; }
	if (maskBitmap) { free(maskBitmap); maskBitmap = NULL; [maskImage autorelease]; maskImage = NULL; }
	
	// Adjust the rectangle
	rect = IntMakeRect([layer xoff], [layer yoff], [(SeaLayer *)layer width], [(SeaLayer *)layer height]);
	globalRect = rect;
	
	// Activate the selection
	active = YES;
	
	// Make the mask
	mask = malloc(rect.size.width * rect.size.height);
	for (i = 0; i < rect.size.width * rect.size.height; i++) {
		mask[i] = data[(i + 1) * spp - 1];
	}
	[self trimSelection];
	[self updateMaskImage];
	
	// Make the change
	[[document helpers] selectionChanged];
}

- (void)moveSelection:(IntPoint)newOrigin
{
	id layer = [[document contents] activeLayer];
	int width = [(SeaLayer *)layer width], height = [(SeaLayer *)layer height];
	
	// Adjust the selection
	rect.origin.x = newOrigin.x;
	rect.origin.y = newOrigin.y;
	globalRect = IntConstrainRect(rect, IntMakeRect(0, 0, width, height));
	rect.origin.x += [layer xoff];
	rect.origin.y += [layer yoff];
	globalRect.origin.x += [layer xoff];
	globalRect.origin.y += [layer yoff];
	
	// Make the change
	[[document helpers] selectionChanged];
}

- (void)readjustSelection
{
	id layer = [[document contents] activeLayer];
	IntRect layerRect;
	
	layerRect = IntMakeRect([layer xoff], [layer yoff], [(SeaLayer *)layer width], [(SeaLayer *)layer height]);
	globalRect = IntConstrainRect(rect, layerRect);
	if (globalRect.size.width == 0 || globalRect.size.height == 0) {
		active = NO;
		if (mask) { free(mask); mask = NULL; }
	}
}

- (void)clearSelection
{
	if (![self floating]) {
		active = NO;
		if (mask) { free(mask); mask = NULL; }
		if (maskBitmap) { free(maskBitmap); maskBitmap = NULL; [maskImage autorelease]; maskImage = NULL; }
		[[document helpers] selectionChanged];
	}
}

- (void)invertSelection
{
	id layer = [[document contents] activeLayer];
	int lwidth = [(SeaLayer *)layer width], lheight = [(SeaLayer *)layer height];
	int xoff = [layer xoff], yoff = [layer yoff];
	IntRect localRect = [self localRect];
	unsigned char *newMask;
	BOOL done = NO;
	int i, j, src, dest;
	
	// Deal with simple inversions first
	if (!mask) {
		if (localRect.origin.x == 0 && localRect.origin.y == 0) {
			if (localRect.size.width == lwidth) {
				rect = IntMakeRect(0, localRect.size.height, lwidth, lheight - localRect.size.height);
				done = YES;
			}
			else if (localRect.size.height == lheight) {
				rect = IntMakeRect(localRect.size.width, 0, lwidth - localRect.size.width, lheight);
				done = YES;
			}
		}
		else if (localRect.origin.x + localRect.size.width == lwidth && localRect.size.height == lheight) {
			rect = IntMakeRect(0, 0, localRect.origin.x, lheight);
			done = YES;
		}
		else if (localRect.origin.y + localRect.size.height == lheight && localRect.size.width == lwidth) {
			rect = IntMakeRect(0, 0, lwidth, localRect.origin.y);
			done = YES;
		}
	}
	
	// Then if that didn't work we have a complex inversions
	if (!done) {
		newMask = malloc(lwidth * lheight);
		memset(newMask, 0xFF, lwidth * lheight);
		for (j = 0; j < rect.size.height; j++) {
			for (i = 0; i < rect.size.width; i++) {
				if (mask) {
					if ((rect.origin.y - yoff) + j >= 0 && (rect.origin.y - yoff) + j < lheight && 
						(rect.origin.x - xoff) + i >= 0 && (rect.origin.x - xoff) + i < lwidth) {
						src = j * rect.size.width + i;
						dest = ((rect.origin.y - yoff) + j) * lwidth + (rect.origin.x - xoff) + i;
						newMask[dest] = 0xFF - mask[src];
					}
				}
				else {
					newMask[((rect.origin.y - yoff) + j) * lwidth + (rect.origin.x - xoff) + i] = 0x00;
				}
			}
		}
		rect = IntMakeRect(0, 0, lwidth, lheight);
		free(mask);
		mask = newMask;
	}
	
	// Finally clean everything up
	rect = IntConstrainRect(rect, IntMakeRect(0, 0, lwidth, lheight));
	rect.origin.x += [layer xoff];
	rect.origin.y += [layer yoff];
	globalRect = rect;
	if (rect.size.width > 0 && rect.size.height > 0) {
		active = YES;
		if (maskBitmap) { free(maskBitmap); maskBitmap = NULL; [maskImage autorelease]; maskImage = NULL; }
		[self trimSelection];
		[self updateMaskImage];
	}
	else {
		active = NO;
	}
	[[document helpers] selectionChanged];
}

- (void)flipSelection:(int)type
{
	unsigned char tmp;
	int i, j, src, dest;
	
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
		
		if (maskBitmap) { free(maskBitmap); maskBitmap = NULL; [maskImage autorelease]; maskImage = NULL; }
		[self trimSelection];
		[self updateMaskImage];
		[[document helpers] selectionChanged];

	}
}

- (unsigned char *)selectionData:(BOOL)premultiplied
{
	id layer = [[document contents] activeLayer];
	int spp = [[document contents] spp], width = [(SeaLayer *)layer width];
	unsigned char *destPtr, *srcPtr;
	IntRect localRect = [self localRect];
	IntPoint maskOffset = [self maskOffset];
	int i, j, k, selectedChannel, t1;
	
	// Get the selected channel
	selectedChannel = [[document contents] selectedChannel];
	
	// Copy the image data
	destPtr = malloc(make_128(globalRect.size.width * globalRect.size.height * spp));
	srcPtr = [(SeaLayer *)layer data];
	for (i = 0; i < globalRect.size.height; i++) {
		memcpy(&(destPtr[i * globalRect.size.width * spp]), &(srcPtr[((i + localRect.origin.y) * width + localRect.origin.x) * spp]), globalRect.size.width * spp); 
	}
	
	// Apply the mask
	for (j = 0; j < globalRect.size.height; j++) {
		for (i = 0; i < globalRect.size.width; i++) {
			switch (selectedChannel) {
				case kAllChannels:
					destPtr[(j * globalRect.size.width + i + 1) * spp - 1] = int_mult(destPtr[(j * globalRect.size.width + i + 1) * spp - 1], (mask) ? mask[(j + maskOffset.y) * rect.size.width + i + maskOffset.x] : 255, t1);
				break;
				case kPrimaryChannels:
					destPtr[(j * globalRect.size.width + i + 1) * spp - 1] = (mask) ? mask[(j + maskOffset.y) * rect.size.width + i + maskOffset.x] : 255;
				break;
				case kAlphaChannel:
					for (k = 0; k < spp - 1; k++)
						destPtr[(j * globalRect.size.width + i ) * spp + k] = destPtr[(j * globalRect.size.width + i + 1) * spp - 1];
					destPtr[(j * globalRect.size.width + i + 1) * spp - 1] = (mask) ? mask[(j + maskOffset.y) * rect.size.width + i + maskOffset.x] : 255;
				break;
			}
		}
	}
	
	// If we need to premultiply
	if (premultiplied)
		premultiplyBitmap(spp, destPtr, destPtr, globalRect.size.width * globalRect.size.height);
	
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
	NSBitmapImageRep *imageRep;
	unsigned char *data;
	BOOL containsNothing;
	
	if (active) {
	
		// Get the selection data 
		data = [self selectionData:YES];
		
		// Check for nothingness
		containsNothing = YES;
		for (i = 0; containsNothing && (i < globalRect.size.width * globalRect.size.height); i++) {
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
		
		// Add it to the pasteboard
		imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data pixelsWide:globalRect.size.width pixelsHigh:globalRect.size.height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:globalRect.size.width * spp bitsPerPixel:8 * spp];
		[pboard setData:[imageRep TIFFRepresentation] forType:NSTIFFPboardType]; 
		[imageRep autorelease];
		
		// Stores the point of the last copied selection and its size
		sel_point = globalRect.origin;
		sel_size = globalRect.size;
		
	}
}

- (void)deleteSelection
{
	id layer = [[document contents] activeLayer], color;
	int i, j, spp = [[document contents] spp], width = [(SeaLayer *)layer width];
	IntRect localRect = [self localRect];
	unsigned char *overlay = [[document whiteboard] overlay];
	unsigned char basePixel[4];
	
	// Get the background colour
	color = [[document contents] background];
	if (spp == 4) {
		basePixel[0] = (unsigned char)([color redComponent] * 255.0);
		basePixel[1] = (unsigned char)([color greenComponent] * 255.0);
		basePixel[2] = (unsigned char)([color blueComponent] * 255.0);
		basePixel[3] = 255;
	}
	else {
		basePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
		basePixel[1] = 255;
	}
	
	// Set the overlay to erasing
	if ([layer hasAlpha])
		[[document whiteboard] setOverlayBehaviour:kErasingBehaviour];
	[[document whiteboard] setOverlayOpacity:255];
		
	// Fill the overlay with the base pixel
	for (j = 0; j < localRect.size.height; j++) {
		for (i = 0; i < localRect.size.width; i++) {
			memcpy(&(overlay[((localRect.origin.y + j) * width + (localRect.origin.x + i)) * spp]), &basePixel, spp);
		}
	}
	
	// Apply the overlay
	[(SeaHelpers *)[document helpers] applyOverlay];
}

- (void)adjustOffset:(IntPoint)offset
{
	rect.origin.x += offset.x;
	rect.origin.y += offset.y;
	globalRect.origin.x += offset.x;
	globalRect.origin.y += offset.y;
}

- (void)scaleSelectionHorizontally:(float)xScale vertically:(float)yScale interpolation:(int)interpolation
{
	IntRect newRect;
	
	if (active) {
	
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
			unsigned char* flippedMask = malloc(oldRect.size.width * oldRect.size.height);
			memcpy(flippedMask, oldMask, oldRect.size.width * oldRect.size.height);
			if(hFlip)
				[(SeaFlip *)[[(SeaDocument *)gCurrentDocument operations] seaFlip] simpleFlipOf:flippedMask width:oldRect.size.width height:oldRect.size.height spp:1 type:kHorizontalFlip];
			if(vFlip)
				[(SeaFlip *)[[(SeaDocument *)gCurrentDocument operations] seaFlip] simpleFlipOf:flippedMask width:oldRect.size.width height:oldRect.size.height spp:1 type:kVerticalFlip];
			
			newMask = malloc(newRect.size.width * newRect.size.height);
			GCScalePixels(newMask, newRect.size.width, newRect.size.height, flippedMask, oldRect.size.width, oldRect.size.height, interpolation, 1);
			free(mask);
			free(flippedMask);
			mask = newMask;
		}
					
		// Substitute in the new stuff
		rect = newRect;
		[self readjustSelection];
		if (mask) {
			if (maskBitmap) { free(maskBitmap); maskBitmap = NULL; [maskImage autorelease]; maskImage = NULL; }
			[self updateMaskImage];
		}
		[[document docView] setNeedsDisplay: YES];
	}
}

- (void)trimSelection
{
	int selectionLeft = -1, selectionRight = -1, selectionTop = -1, selectionBottom = -1;
	int newWidth, newHeight, i, j;
	unsigned char *newMask;
	BOOL fullyOpaque = YES;
	
	// We only trim if the selction has a mask
	if (mask) {
		
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
			rect = IntMakeRect(rect.origin.x + selectionLeft, rect.origin.y + selectionTop, newWidth, newHeight);
			globalRect = rect;			
			newMask = malloc(newWidth * newHeight);
			memset(newMask, 0xFF, newWidth * newHeight);
			free(mask);
			mask = newMask;
		}
		else {
			
			// Now make the change if required
			if (selectionLeft != 0 || selectionRight != 0 || selectionTop != 0 || selectionBottom != 0) {
				
				// Calculate the new mask
				newMask = malloc(newWidth * newHeight);
				for (j = 0; j < newHeight; j++) {
					for (i = 0; i < newWidth; i++) {
						newMask[j * newWidth + i] = mask[(j + selectionTop) * rect.size.width + (i + selectionLeft)];
					}
				}
				
				// Finally make the change
				rect = IntMakeRect(rect.origin.x + selectionLeft, rect.origin.y + selectionTop, newWidth, newHeight);
				free(mask);
				mask = newMask;
				globalRect = rect;
				
			}
		
		}
	}

}

@end

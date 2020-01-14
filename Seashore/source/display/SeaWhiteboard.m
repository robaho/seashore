#import "SeaWhiteboard.h"
#import "StandardMerge.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaLayerUndo.h"
#import "SeaView.h"
#import "SeaSelection.h"
#import "Bitmap.h"
#import "ToolboxUtility.h"
#import "StatusUtility.h"
#import "SeaController.h"

extern IntPoint gScreenResolution;

dispatch_queue_t queue;
dispatch_group_t group;

@implementation SeaWhiteboard

- (id)initWithDocument:(id)doc
{
	int layerWidth, layerHeight;
	
	// Remember the document we are representing
	document = doc;
	
	// Initialize the compostior
	compositor = [[SeaCompositor alloc] init];
	
	// Record the width, height and use of greys
	width = [[document contents] width];
	height = [[document contents] height];
	layerWidth = [[[document contents] activeLayer] width];
	layerHeight = [[[document contents] activeLayer] height];
	
	// Record the samples per pixel used by the whiteboard
	spp = [[document contents] spp];
	
	// Set the view type to show all channels
	viewType = kAllChannelsView;
    proofProfile = NULL;
	
	// Allocate the whiteboard data
	data = malloc(make_128(width * height * spp));
	overlay = malloc(make_128(layerWidth * layerHeight * spp));
	memset(overlay, 0, layerWidth * layerHeight * spp);
	replace = malloc(make_128(layerWidth * layerHeight));
	memset(replace, 0, layerWidth * layerHeight);
	altData = NULL;
    
	return self;
}

- (SeaCompositor *)compositor{
	return compositor;
}

- (void)dealloc
{	
	if (data) free(data);
	if (overlay) free(overlay);
	if (replace) free(replace);
	if (altData) free(altData);
}

- (void)setOverlayBehaviour:(int)value
{
	overlayBehaviour = value;
}

- (void)setOverlayOpacity:(int)value
{
	overlayOpacity = value;
}

- (IntRect)applyOverlay
{
	SeaLayer *layer;
	int leftOffset, rightOffset, topOffset, bottomOffset;
	int i, j, k, srcLoc, selectedChannel;
	int xoff, yoff;
	unsigned char *srcPtr, *mask;
	int lwidth, lheight, selectOpacity, t1;
	IntRect rect, selectRect;
	BOOL overlayOkay, overlayReplacing;
	IntPoint point, maskOffset, trueMaskOffset;
	IntSize maskSize;
	
	// Fill out the local variables
	selectRect = [[document selection] localRect];
	selectedChannel = [[document contents] selectedChannel];
	layer = [[document contents] activeLayer];
	srcPtr = [layer data];
	lwidth = [layer width];
	lheight = [layer height];
	xoff = [layer xoff];
	yoff = [layer yoff];
	mask = [(SeaSelection*)[document selection] mask];
	maskOffset = [[document selection] maskOffset];
	trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
	maskSize = [[document selection] maskSize];
	overlayReplacing = (overlayBehaviour == kReplacingBehaviour);
	
	// Calculate offsets
	leftOffset = lwidth + 1;
	rightOffset = -1;
	bottomOffset = -1;
	topOffset = lheight + 1;
	for (j = 0; j < lheight; j++) {
		for (i = 0; i < lwidth; i++) {	
			if (overlayReplacing) {
				if (replace[j * lwidth + i] != 0) {	
					if (rightOffset < i + 1) rightOffset = i + 1;
					if (topOffset > j) topOffset = j;
					if (leftOffset > i) leftOffset = i;
					if (bottomOffset < j + 1) bottomOffset = j + 1;
				}
				else {
					overlay[(j * lwidth + i + 1) * spp - 1] = 0;
				}
			}
			else {
				if (overlay[(j * lwidth + i + 1) * spp - 1] != 0) {
					if (rightOffset < i + 1) rightOffset = i + 1;
					if (topOffset > j) topOffset = j;
					if (leftOffset > i) leftOffset = i;
					if (bottomOffset < j + 1) bottomOffset = j + 1;
				}
			}
		}
	}
	
	// If we didn't find any pixels, all of the offsets will be in their original
	// state, but we only need to test one ...
	if (leftOffset < 0) return IntMakeRect(0, 0, 0, 0);
	
	// Create the rectangle
	rect = IntMakeRect(leftOffset, topOffset, rightOffset - leftOffset, bottomOffset - topOffset);
	
	// Allow the undo
	[[layer seaLayerUndo] takeSnapshot:rect automatic:YES];
	
	// Go through each column and row
	for (j = rect.origin.y; j < rect.origin.y + rect.size.height; j++) {
		for (i = rect.origin.x; i < rect.origin.x + rect.size.width; i++) {
			
			// Determine the source location
			srcLoc = (j * lwidth + i) * spp;
			
			// Check if we should apply the overlay for this pixel
			overlayOkay = NO;
			switch (overlayBehaviour) {
				case kReplacingBehaviour:
				case kMaskingBehaviour:
					selectOpacity = replace[j * lwidth + i];
				break;
				default:
					selectOpacity = overlayOpacity;
				break;
			}
			if ([[document selection] active]) {
				point.x = i;
				point.y = j;
				if (IntPointInRect(point, selectRect)) {
					overlayOkay = YES;
					if (mask)
						selectOpacity = int_mult(selectOpacity, mask[(trueMaskOffset.y + point.y) * maskSize.width + (trueMaskOffset.x + point.x)], t1);
				}
			}
			else {
				overlayOkay = YES;
			}
			
			// Don't do anything if there's no point
			if (selectOpacity == 0)
				overlayOkay = NO;
			
			// Apply the overlay
			if (overlayOkay) {
				if (selectedChannel == kAllChannels) {
					
					// For the general case
					switch (overlayBehaviour) {
						case kErasingBehaviour:
							eraseMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
						case kReplacingBehaviour:
							replaceMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
						default:
							specialMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
					}
					
				}
				else if (selectedChannel == kPrimaryChannels) {
				
					// For the primary channels
					switch (overlayBehaviour) {
						case kReplacingBehaviour:
							replacePrimaryMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
						default:
							primaryMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity, NO);
						break;
					}
					
				}
				else if (selectedChannel == kAlphaChannel) {
					
					// For the alpha channels
					switch (overlayBehaviour) {
						case kReplacingBehaviour:
							replaceAlphaMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
						default:
							alphaMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
					}
					
				}
			}
			
			// Clear the overlay
			for (k = 0; k < spp; k++)
				overlay[srcLoc + k] = 0;
			replace[j * lwidth + i] = 0;
			
		}
	}
	
	// Put the rectangle in the document's co-ordinates
	rect.origin.x += xoff;
	rect.origin.y += yoff;
	
	// Reset the overlay's opacity and behaviour
	overlayOpacity = 0;
	overlayBehaviour = kNormalBehaviour;
	
	return rect;
}

- (void)clearOverlay
{
	id layer = [[document contents] activeLayer];

	memset(overlay, 0, [(SeaLayer *)layer width] * [(SeaLayer *)layer height] * spp);
	memset(replace, 0, [(SeaLayer *)layer width] * [(SeaLayer *)layer height]);
	overlayOpacity = 0;
	overlayBehaviour = kNormalBehaviour;
}

- (unsigned char *)overlay
{
	return overlay;
}

- (unsigned char *)replace
{
	return replace;
}

- (BOOL)whiteboardIsLayerSpecific
{
	return viewType == kPrimaryChannelsView || viewType == kAlphaChannelView;
}

- (void)readjust
{	
	// Resize the memory allocated to the data 
	width = [[document contents] width];
	height = [[document contents] height];
	
	// Change the samples per pixel if required
	if (spp != [[document contents] spp]) {
		spp = [[document contents] spp];
		viewType = kAllChannelsView;
	}
	
	// Revise the data
	if (data) free(data);
	data = malloc(make_128(width * height * spp));
    cachedImage = NULL;
    
	// Adjust the alternate data as necessary
	[self readjustAltData:NO];
	
	// Update the overlay
	if (overlay) free(overlay);
	overlay = malloc(make_128([[[document contents] activeLayer] width] * [[[document contents] activeLayer] height] * spp));
	memset(overlay, 0, [[[document contents] activeLayer] width] * [[[document contents] activeLayer] height] * spp);
	if (replace) free(replace);
	replace = malloc(make_128([[[document contents] activeLayer] width] * [[[document contents] activeLayer] height]));
	memset(replace, 0, [[[document contents] activeLayer] width] * [[[document contents] activeLayer] height]);

	// Update ourselves
	[self update];
}

- (void)readjustLayer
{
	// Adjust the alternate data as necessary
	[self readjustAltData:NO];
	
	// Update the overlay
	if (overlay) free(overlay);
	overlay = malloc(make_128([[[document contents] activeLayer] width] * [[[document contents] activeLayer] height] * spp));
	memset(overlay, 0, [[[document contents] activeLayer] width] * [[[document contents] activeLayer] height] * spp);
	if (replace) free(replace);
	replace = malloc(make_128([[[document contents] activeLayer] width] * [[[document contents] activeLayer] height]));
	memset(replace, 0, [[[document contents] activeLayer] width] * [[[document contents] activeLayer] height]);
	
	// Update ourselves
	[self update];
}

- (void)readjustAltData:(BOOL)update
{
	id contents = [document contents];
	int selectedChannel = [contents selectedChannel];
	BOOL trueView = [contents trueView];
	id layer;
	int xwidth, xheight;
	
	// Free existing data
	viewType = kAllChannelsView;
	if (altData) free(altData);
	altData = NULL;
    cachedImage = NULL;
    
    layer = [contents activeLayer];
	
	// Create room for alternative data if necessary
	if (!trueView && selectedChannel == kPrimaryChannels) {
		viewType = kPrimaryChannelsView;
		xwidth = [(SeaLayer *)layer width];
		xheight = [(SeaLayer *)layer height];
		altData = malloc(make_128(xwidth * xheight * (spp - 1)));
	}
	else if (!trueView && selectedChannel == kAlphaChannel) {
		viewType = kAlphaChannelView;
		xwidth = [(SeaLayer *)layer width];
		xheight = [(SeaLayer *)layer height];
		altData = malloc(make_128(xwidth * xheight));
	}
	
	// Update ourselves (if advised to)
	if (update)
		[self update];
}

- (SeaColorProfile*)proofProfile
{
	return proofProfile;
}

- (void)toggleSoftProof:(SeaColorProfile*)profile
{
    proofProfile = profile;
    [[document docView] setNeedsDisplay:YES];
	[[document toolboxUtility] update:NO];
    [[document statusUtility] update];
}

- (void)forcedChannelUpdate:(IntRect)updateRect
{
	SeaLayer *layer;
	int layerWidth, layerHeight, lxoff, lyoff;
	unsigned char *layerData, tempSpace[4], tempSpace2[4], *mask;
	int i, j, k, temp, t, selectOpacity, nextOpacity;
	IntRect selectRect, minorUpdateRect;
	IntSize maskSize = IntMakeSize(0, 0);
	IntPoint point, maskOffset = IntMakePoint(0, 0);
	BOOL useSelection;
	
	// Prepare variables for later use
	mask = NULL;
	selectRect = IntMakeRect(0, 0, 0, 0);
	useSelection = [[document selection] active];
    layer = [[document contents] activeLayer];
	if (useSelection) {
        selectRect = [[document selection] localRect];
		mask = [[document selection] mask];
		maskOffset = [[document selection] maskOffset];
		maskSize = [[document selection] maskSize];
	}
	selectOpacity = 255;
	layerWidth = [layer width];
	layerHeight = [layer height];
	lxoff = [layer xoff];
	lyoff = [layer yoff];
	layerData = [layer data];
		
    minorUpdateRect = updateRect;
    minorUpdateRect = IntOffsetRect(minorUpdateRect, -lxoff,  -lyoff);
    minorUpdateRect = IntConstrainRect(minorUpdateRect, IntMakeRect(0, 0, layerWidth, layerHeight));

	// Go through pixel-by-pixel working out the channel update
	for (j = minorUpdateRect.origin.y; j < minorUpdateRect.origin.y + minorUpdateRect.size.height; j++) {
		for (i = minorUpdateRect.origin.x; i < minorUpdateRect.origin.x + minorUpdateRect.size.width; i++) {
			temp = j * layerWidth + i;
			
			// Determine what we are compositing to
			if (viewType == kPrimaryChannelsView) {
				for (k = 0; k < spp - 1; k++)
					tempSpace[k] = layerData[temp * spp + k];
				tempSpace[spp - 1] =  0xFF;
			}
			else {
				tempSpace[0] = layerData[(temp + 1) * spp - 1];
				tempSpace[1] =  0xFF;
			}
			
			// Make changes necessary if a selection is active
			if (useSelection) {
				point.x = i;
				point.y = j;
				if (IntPointInRect(point, selectRect)) {
					if (mask)
						selectOpacity = mask[(point.y - selectRect.origin.y + maskOffset.y) * maskSize.width + (point.x - selectRect.origin.x + maskOffset.x)];
				}
			}
			
            // Insert the overlay
            point.x = i;
            point.y = j;
            if (IntPointInRect(point, selectRect) || !useSelection) {
                if (selectOpacity > 0) {
                    if (viewType == kPrimaryChannelsView) {
                        memcpy(&tempSpace2, &(overlay[temp * spp]), spp);
                        if (overlayOpacity < 255)
                            tempSpace2[spp - 1] = int_mult(tempSpace2[spp - 1], overlayOpacity, t);
                    }
                    else {
                        tempSpace2[0] = overlay[temp * spp];
                        if (overlayOpacity == 255)
                            tempSpace2[1] = overlay[(temp + 1) * spp - 1];
                        else
                            tempSpace2[1] = int_mult(overlay[(temp + 1) * spp - 1], overlayOpacity, t);
                    }
                    if (overlayBehaviour == kReplacingBehaviour) {
                        nextOpacity = int_mult(replace[temp], selectOpacity, t);
                        replaceMerge((viewType == kPrimaryChannelsView) ? spp : 2, tempSpace, 0, tempSpace2, 0, nextOpacity);
                    }
                    else if (overlayBehaviour ==  kMaskingBehaviour) {
                        nextOpacity = int_mult(replace[temp], selectOpacity, t);
                        normalMerge((viewType == kPrimaryChannelsView) ? spp : 2, tempSpace, 0, tempSpace2, 0, nextOpacity);
                    }
                    else
                        normalMerge((viewType == kPrimaryChannelsView) ? spp : 2, tempSpace, 0, tempSpace2, 0, selectOpacity);
                }
            }
			
			// Finally update the channel
			if (viewType == kPrimaryChannelsView) {
				for (k = 0; k < spp - 1; k++)
					altData[temp * (spp - 1) + k] = tempSpace[k];
			}
			else {
				altData[j * layerWidth + i] = tempSpace[0];
			}
			
		}
	}
}

-(void)forcedUpdate:(BOOL)useUpdateRect updateRect:(IntRect)updateRect
{
    int HEIGHT=64;
    IntRect majorUpdateRect;
    
    // Determine the major update rect
    if (useUpdateRect) {
        majorUpdateRect = IntConstrainRect(updateRect, IntMakeRect(0, 0, width, height));
    }
    else {
        majorUpdateRect = IntMakeRect(0, 0, width, height);
    }
    
    if(queue==NULL){
        queue = dispatch_queue_create("SeaWhiteboard", DISPATCH_QUEUE_CONCURRENT);
        group = dispatch_group_create();
    }
    
    int numCPU = (int)sysconf(_SC_NPROCESSORS_ONLN);
    int height = majorUpdateRect.size.height;
    int perCPU = height / numCPU;

    if(group==nil || height < HEIGHT | perCPU < 16){
        [self forcedUpdateWithRect:majorUpdateRect];
    } else {
        IntRect rect = IntMakeRect(majorUpdateRect.origin.x,majorUpdateRect.origin.y,majorUpdateRect.size.width,perCPU);
        while(height>0){
            dispatch_group_async(group,queue,^{[self forcedUpdateWithRect:rect];});
            height-=perCPU;
            rect.origin.y += perCPU;
            if(height<perCPU && height>0){
                rect.size.height=height;
            }
        }
        dispatch_group_wait(group,DISPATCH_TIME_FOREVER);
    }
}

- (void)forcedUpdateWithRect:(IntRect)majorUpdateRect
{
	int i, count = 0, layerCount = [[document contents] layerCount];
	CompositorOptions options;

	// Handle non-channel updates here
	if (majorUpdateRect.size.width > 0 && majorUpdateRect.size.height > 0) {
		
		// Clear the whiteboard
		for (i = 0; i < majorUpdateRect.size.height; i++)
			memset(data + ((majorUpdateRect.origin.y + i) * width + majorUpdateRect.origin.x) * spp, 0, majorUpdateRect.size.width * spp);
			
		// Determine how many layers are visible
		for (i = 0; count < 2 && i < layerCount; i++) {
			if ([[[document contents] layer:i] visible])
				count++;
		}
		
		// Set the composting options
		options.spp = spp;
		options.forceNormal = (count == 1);
		options.rect = majorUpdateRect;
		options.destRect = IntMakeRect(0, 0, width, height);
		options.overlayOpacity = overlayOpacity;
		options.overlayBehaviour = overlayBehaviour;
		options.useSelection = NO;
		
        // Go through compositing each visible layer
        for (i = layerCount - 1; i >= 0; i--) {
            if ([[[document contents] layer:i] visible]) {
                options.insertOverlay = (i == [[document contents] activeLayerIndex]);
                options.useSelection = (i == [[document contents] activeLayerIndex]) && [[document selection] active];
                [compositor compositeLayer:[[document contents] layer:i] withOptions:options];
            }
        }
	}
	
	// Handle channel updates here
	if (viewType == kPrimaryChannelsView || viewType == kAlphaChannelView) {
        [self forcedChannelUpdate:majorUpdateRect];
	}
}

- (void)update
{
//    NSLog(@"updating all");
    [self forcedUpdate:NO updateRect:IntZeroRect];
    cachedImage=NULL;
	[[document docView] setNeedsDisplay:YES];
}

- (void)update:(IntRect)rect
{
//    NSLog(@"updating rect %@",NSStringFromRect(IntRectMakeNSRect(rect)));
    [self forcedUpdate:YES updateRect:rect];
    cachedImage=NULL;
    [[document docView] setNeedsDisplayInDocumentRect:rect];
}

- (IntRect)imageRect
{
	SeaLayer *layer;
	
	if (viewType == kPrimaryChannelsView || viewType == kAlphaChannelView) {
        layer = [[document contents] activeLayer];
		return IntMakeRect([layer xoff], [layer yoff], [layer width], [layer height]);
	}
	else {
		return IntMakeRect(0, 0, width, height);
	}
}

- (CIImage *)image
{
    if(cachedImage){
        return cachedImage;
    }
    
	NSBitmapImageRep *imageRep;
	SeaContent *contents = [document contents];
    SeaLayer *layer;
	int xwidth, xheight;
    
	if (altData) {
        layer = [contents activeLayer];
		if (viewType == kPrimaryChannelsView) {
			xwidth = [layer width];
			xheight = [layer height];
            imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&altData pixelsWide:xwidth pixelsHigh:xheight bitsPerSample:8 samplesPerPixel:spp - 1 hasAlpha:NO isPlanar:NO colorSpaceName:(spp == 4) ? MyRGBSpace : MyGraySpace bytesPerRow:xwidth * (spp - 1) bitsPerPixel:8 * (spp - 1)];
		}
        else { // if (viewType == kAlphaChannelView) {
			xwidth = [layer width];
			xheight = [layer height];
			imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&altData pixelsWide:xwidth pixelsHigh:xheight bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:MyGraySpace bytesPerRow:xwidth * 1 bitsPerPixel:8];
		}
	}
	else {
        xwidth = width;
        xheight = height;
        imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? MyRGBSpace : MyGraySpace bitmapFormat:0 bytesPerRow:width * spp bitsPerPixel:8 * spp];
	}
    
    if (proofProfile && viewType!=kAlphaChannelView && proofProfile!=NULL && proofProfile.cs!=NULL) {
        imageRep = [imageRep bitmapImageRepByConvertingToColorSpace:proofProfile.cs renderingIntent:NSColorRenderingIntentDefault];
    }
    
    CIImage *image = [[CIImage alloc] initWithBitmapImageRep:imageRep];
    CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
    transform = CGAffineTransformTranslate(transform,0, -xheight);
    image = [image imageByApplyingTransform:transform];
    
    cachedImage = image;
    
    return image;
}

- (NSImage *)printableImage
{
	NSBitmapImageRep *imageRep;
	
	NSImage *image = [[NSImage alloc] init];
    imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? MyRGBSpace : MyGraySpace bitmapFormat:NSBitmapFormatAlphaNonpremultiplied                                                     bytesPerRow:width * spp bitsPerPixel:8 * spp];
    
    [imageRep setSize:NSMakeSize(width * (72.0/[[document contents] xres]), height * (72.0/[[document contents] yres]))];

	[image addRepresentation:imageRep];
	
	return image;
}

- (unsigned char *)data
{
	return data;
}

- (unsigned char *)altData
{
	return altData;
}

@end

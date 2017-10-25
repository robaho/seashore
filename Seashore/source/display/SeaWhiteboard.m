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
#import "SeaController.h"
#import "UtilitiesManager.h"

extern BOOL useAltiVec;

extern IntPoint gScreenResolution;

@implementation SeaWhiteboard

- (id)initWithDocument:(id)doc
{
	CMProfileRef destProf;
	int layerWidth, layerHeight;
	NSString *pluginPath;
	NSBundle *bundle;
	
	// Remember the document we are representing
	document = doc;
	
	// Initialize the compostior
	compositor = NULL;
	if (useAltiVec) {
		pluginPath = [NSString stringWithFormat:@"%@/CompositorAV.bundle", [gMainBundle builtInPlugInsPath]];
		if ([gFileManager fileExistsAtPath:pluginPath]) {
			bundle = [NSBundle bundleWithPath:pluginPath];
			if (bundle && [bundle principalClass]) {
				compositor = [[bundle principalClass] alloc];
			}
		}
	}
	if (compositor == NULL)	compositor = [SeaCompositor alloc];
	[compositor initWithDocument:document];
	
	// Record the width, height and use of greys
	width = [(SeaContent *)[document contents] width];
	height = [(SeaContent *)[document contents] height];
	layerWidth = [(SeaLayer *)[[document contents] activeLayer] width];
	layerHeight = [(SeaLayer *)[[document contents] activeLayer] height];
	
	// Record the samples per pixel used by the whiteboard
	spp = [[document contents] spp];
	
	// Set the view type to show all channels
	viewType = kAllChannelsView;
	CMYKPreview = NO;
	
	// Allocate the whiteboard data
	data = malloc(make_128(width * height * spp));
	overlay = malloc(make_128(layerWidth * layerHeight * spp));
	memset(overlay, 0, layerWidth * layerHeight * spp);
	replace = malloc(make_128(layerWidth * layerHeight));
	memset(replace, 0, layerWidth * layerHeight);
	altData = NULL;
	
	// Create the colour world
	OpenDisplayProfile(&displayProf);
	cgDisplayProf = CGColorSpaceCreateWithPlatformColorSpace(displayProf);
	CMGetDefaultProfileBySpace(cmCMYKData, &destProf);
	NCWNewColorWorld(&cw, displayProf, destProf);
	
	// Set the locking thread to NULL
	lockingThread = NULL;
	
	return self;
}

- (SeaCompositor *)compositor{
	return compositor;
}

- (void)dealloc
{	
	// Free the room we took for everything else
	if (displayProf) CloseDisplayProfile(displayProf);
	if (cgDisplayProf) CGColorSpaceRelease(cgDisplayProf);
	if (compositor) [compositor autorelease];
	if (image) [image autorelease];
	if (cw) CWDisposeColorWorld(cw);
	if (data) free(data);
	if (overlay) free(overlay);
	if (replace) free(replace);
	if (altData) free(altData);
	[super dealloc];
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
	id layer;
	int leftOffset, rightOffset, topOffset, bottomOffset;
	int i, j, k, srcLoc, selectedChannel;
	int xoff, yoff;
	unsigned char *srcPtr, *mask;
	int lwidth, lheight, selectOpacity, t1;
	IntRect rect, selectRect;
	BOOL overlayOkay, overlayReplacing;
	IntPoint point, maskOffset, trueMaskOffset;
	IntSize maskSize;
	BOOL floating;
	
	// Fill out the local variables
	selectRect = [[document selection] localRect];
	selectedChannel = [[document contents] selectedChannel];
	layer = [[document contents] activeLayer];
	floating = [layer floating];
	srcPtr = [(SeaLayer *)layer data];
	lwidth = [(SeaLayer *)layer width];
	lheight = [(SeaLayer *)layer height];
	xoff = [layer xoff];
	yoff = [layer yoff];
	mask = [[document selection] mask];
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
					if (mask && !floating)
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
				if (selectedChannel == kAllChannels && !floating) {
					
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
				else if (selectedChannel == kPrimaryChannels || floating) {
				
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
	width = [(SeaContent *)[document contents] width];
	height = [(SeaContent *)[document contents] height];
	
	// Change the samples per pixel if required
	if (spp != [[document contents] spp]) {
		spp = [[document contents] spp];
		viewType = kAllChannelsView;
		CMYKPreview = NO;
	}
	
	// Revise the data
	if (data) free(data);
	data = malloc(make_128(width * height * spp));

	// Adjust the alternate data as necessary
	[self readjustAltData:NO];
	
	// Update the overlay
	if (overlay) free(overlay);
	overlay = malloc(make_128([(SeaLayer *)[[document contents] activeLayer] width] * [(SeaLayer *)[[document contents] activeLayer] height] * spp));
	memset(overlay, 0, [(SeaLayer *)[[document contents] activeLayer] width] * [(SeaLayer *)[[document contents] activeLayer] height] * spp);
	if (replace) free(replace);
	replace = malloc(make_128([(SeaLayer *)[[document contents] activeLayer] width] * [(SeaLayer *)[[document contents] activeLayer] height]));
	memset(replace, 0, [(SeaLayer *)[[document contents] activeLayer] width] * [(SeaLayer *)[[document contents] activeLayer] height]);

	// Update ourselves
	[self update];
}

- (void)readjustLayer
{
	// Adjust the alternate data as necessary
	[self readjustAltData:NO];
	
	// Update the overlay
	if (overlay) free(overlay);
	overlay = malloc(make_128([(SeaLayer *)[[document contents] activeLayer] width] * [(SeaLayer *)[[document contents] activeLayer] height] * spp));
	memset(overlay, 0, [(SeaLayer *)[[document contents] activeLayer] width] * [(SeaLayer *)[[document contents] activeLayer] height] * spp);
	if (replace) free(replace);
	replace = malloc(make_128([(SeaLayer *)[[document contents] activeLayer] width] * [(SeaLayer *)[[document contents] activeLayer] height]));
	memset(replace, 0, [(SeaLayer *)[[document contents] activeLayer] width] * [(SeaLayer *)[[document contents] activeLayer] height]);
	
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
	
	// Change layer if appropriate
	if ([[document selection] floating]) {
		layer = [contents layer:[contents activeLayerIndex] + 1];
	}
	else {
		layer = [contents activeLayer];
	}
	
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
	else if (CMYKPreview && spp == 4) {
		viewType = kCMYKPreviewView;
		xwidth = [(SeaContent *)contents width];
		xheight = [(SeaContent *)contents height];
		altData = malloc(make_128(xwidth * xheight * 4));
	}
	
	// Update ourselves (if advised to)
	if (update)
		[self update];
}

- (BOOL)CMYKPreview
{
	return CMYKPreview;
}

- (BOOL)canToggleCMYKPreview
{
	return spp == 4;
}

- (void)toggleCMYKPreview
{
	// Do nothing if we can't do anything
	if (![self canToggleCMYKPreview])
		return;
		
	// Otherwise make the change
	CMYKPreview = !CMYKPreview;
	[self readjustAltData:YES];
	[(ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document] update:NO];
}

- (NSColor *)matchColor:(NSColor *)color
{
	CMColor cmColor;
	NSColor *result;
	
	// Determine the RGB color
	cmColor.rgb.red = ([color redComponent] * 65535.0);
	cmColor.rgb.green = ([color greenComponent] * 65535.0);
	cmColor.rgb.blue = ([color blueComponent] * 65535.0);
	
	// Match color
	CWMatchColors(cw, &cmColor, 1);
	
	// Calculate result
	result = [NSColor colorWithDeviceCyan:(float)cmColor.cmyk.cyan / 65536.0 magenta:(float)cmColor.cmyk.magenta / 65536.0 yellow:(float)cmColor.cmyk.yellow / 65536.0 black:(float)cmColor.cmyk.black / 65536.0 alpha:[color alphaComponent]];
	
	return result;
}

- (void)forcedChannelUpdate
{
	id layer, flayer;
	int layerWidth, layerHeight, lxoff, lyoff;
	unsigned char *layerData, tempSpace[4], tempSpace2[4], *mask, *floatingData;
	int i, j, k, temp, tx, ty, t, selectOpacity, nextOpacity;
	IntRect selectRect, minorUpdateRect;
	IntSize maskSize = IntMakeSize(0, 0);
	IntPoint point, maskOffset = IntMakePoint(0, 0);
	BOOL useSelection, floating;
	
	// Prepare variables for later use
	mask = NULL;
	selectRect = IntMakeRect(0, 0, 0, 0);
	useSelection = [[document selection] active];
	floating = [[document selection] floating];
	floatingData = [(SeaLayer *)[[document contents] activeLayer] data];
	if (useSelection && floating) {
		layer = [[document contents] layer:[[document contents] activeLayerIndex] + 1];
	}
	else {
		layer = [[document contents] activeLayer];
	}
	if (useSelection) {
		if (floating) {
			flayer = [[document contents] activeLayer];
			selectRect = IntMakeRect([(SeaLayer *)flayer xoff] - [(SeaLayer *)layer xoff], [(SeaLayer *)flayer yoff] - [(SeaLayer *)layer yoff], [(SeaLayer *)flayer width], [(SeaLayer *)flayer height]);
		}
		else {
			selectRect = [[document selection] globalRect];
		}
		mask = [[document selection] mask];
		maskOffset = [[document selection] maskOffset];
		maskSize = [[document selection] maskSize];
	}
	selectOpacity = 255;
	layerWidth = [(SeaLayer *)layer width];
	layerHeight = [(SeaLayer *)layer height];
	lxoff = [(SeaLayer *)layer xoff];
	lyoff = [(SeaLayer *)layer yoff];
	layerData = [(SeaLayer *)layer data];
	
	// Determine the minor update rect
	if (useUpdateRect) {
		minorUpdateRect = updateRect;
		IntOffsetRect(&minorUpdateRect, -[layer xoff],  -[layer yoff]);
		minorUpdateRect = IntConstrainRect(minorUpdateRect, IntMakeRect(0, 0, layerWidth, layerHeight));
	}
	else {
		minorUpdateRect = IntMakeRect(0, 0, layerWidth, layerHeight);
	}
	
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
					if (floating) {
						tx = i - selectRect.origin.x;
						ty = j - selectRect.origin.y;
						if (viewType == kPrimaryChannelsView) {
							memcpy(&tempSpace2, &(floatingData[(ty * selectRect.size.width + tx) * spp]), spp);
						}
						else {
							tempSpace2[0] = floatingData[(ty * selectRect.size.width + tx) * spp];
							tempSpace2[1] = floatingData[(ty * selectRect.size.width + tx + 1) * spp - 1];
						}
						normalMerge((viewType == kPrimaryChannelsView) ? spp : 2, tempSpace, 0, tempSpace2, 0, 255);
					}
					if (mask)
						selectOpacity = mask[(point.y - selectRect.origin.y - maskOffset.y) * maskSize.width + (point.x - selectRect.origin.x - maskOffset.x)];
				}
			}
			
			// Check for floating layer
			if (useSelection && floating) {
			
				// Insert the overlay
				point.x = i;
				point.y = j;
				if (IntPointInRect(point, selectRect)) {
					tx = i - selectRect.origin.x;
					ty = j - selectRect.origin.y;
					if (selectOpacity > 0) {
						if (viewType == kPrimaryChannelsView) {
							memcpy(&tempSpace2, &(overlay[(ty * selectRect.size.width + tx) * spp]), spp);
							if (overlayOpacity < 255)
								tempSpace2[spp - 1] = int_mult(tempSpace2[spp - 1], overlayOpacity, t);
						}
						else {
							tempSpace2[0] = overlay[(ty * selectRect.size.width + tx) * spp];
							if (overlayOpacity == 255)
								tempSpace2[1] = overlay[(ty * selectRect.size.width + tx + 1) * spp - 1];
							else
								tempSpace2[1] = int_mult(overlay[(ty * selectRect.size.width + tx + 1) * spp - 1], overlayOpacity, t);
						}
						if (overlayBehaviour == kReplacingBehaviour) {
							nextOpacity = int_mult(replace[ty * selectRect.size.width + tx], selectOpacity, t); 
							replaceMerge((viewType == kPrimaryChannelsView) ? spp : 2, tempSpace, 0, tempSpace2, 0, nextOpacity);
						}
						else if (overlayBehaviour ==  kMaskingBehaviour) {
							nextOpacity = int_mult(replace[ty * selectRect.size.width + tx], selectOpacity, t); 
							normalMerge((viewType == kPrimaryChannelsView) ? spp : 2, tempSpace, 0, tempSpace2, 0, nextOpacity);
						}
						else {							
							normalMerge((viewType == kPrimaryChannelsView) ? spp : 2, tempSpace, 0, tempSpace2, 0, selectOpacity);
						}
					}
				}
				
			}
			else {
				
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

- (void)forcedCMYKUpdate:(IntRect)majorUpdateRect
{
	unsigned char *tempData;
	CMBitmap srcBitmap, destBitmap;
	int i;

	// Define the source
	if (useUpdateRect) {
		for (i = 0; i < majorUpdateRect.size.height; i++) {
		
			// Define the source
			tempData = malloc(majorUpdateRect.size.width * 3);
			stripAlphaToWhite(4, tempData, data + ((majorUpdateRect.origin.y + i) * width + majorUpdateRect.origin.x) * 4, majorUpdateRect.size.width);
			srcBitmap.image = (char *)tempData;
			srcBitmap.width = majorUpdateRect.size.width;
			srcBitmap.height = 1;
			srcBitmap.rowBytes = majorUpdateRect.size.width * 3;
			srcBitmap.pixelSize = 8 * 3;
			srcBitmap.space = cmRGB24Space;
		
			// Define the destination
			destBitmap = srcBitmap;
			destBitmap.image = (char *)altData + ((majorUpdateRect.origin.y + i) * width + majorUpdateRect.origin.x) * 4;
			destBitmap.rowBytes = majorUpdateRect.size.width * 4;
			destBitmap.pixelSize = 8 * 4;
			destBitmap.space = cmCMYK32Space;
			
			// Execute the conversion
			CWMatchBitmap(cw, &srcBitmap, NULL, 0, &destBitmap);
			
			// Clean up after ourselves
			free(tempData);
			
		}
	}
	else {
	
		// Define the source
		tempData = malloc(width * height * 3);
		stripAlphaToWhite(4, tempData, data, width * height);
		srcBitmap.image = (char *)tempData;
		srcBitmap.width = width;
		srcBitmap.height = height;
		srcBitmap.rowBytes = width * 3;
		srcBitmap.pixelSize = 8 * 3;
		srcBitmap.space = cmRGB24Space;
	
		// Define the destination
		destBitmap.image = (char *)altData;
		destBitmap.width = width;
		destBitmap.height = height;
		destBitmap.rowBytes = width * 4;
		destBitmap.pixelSize = 8 * 4;
		destBitmap.space = cmCMYK32Space;
		
		// Execute the conversion
		CWMatchBitmap(cw, &srcBitmap, NULL, 0, &destBitmap);

		// Clean up after ourselves
		free(tempData);

	}
}

- (void)forcedUpdate
{
	int i, count = 0, layerCount = [[document contents] layerCount];
	IntRect majorUpdateRect;
	CompositorOptions options;
	BOOL floating;

	// Determine the major update rect
	if (useUpdateRect) {
		majorUpdateRect = IntConstrainRect(updateRect, IntMakeRect(0, 0, width, height));
	}
	else {
		majorUpdateRect = IntMakeRect(0, 0, width, height);
	}
	
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
		
		if ([[document selection] floating]) {
	
			// Go through compositing each visible layer
			for (i = layerCount - 1; i >= 0; i--) {
				if (i >= 1) floating = [[[document contents] layer:i - 1] floating];
				else floating = NO;
				if ([[[document contents] layer:i] visible]) {
					options.insertOverlay = floating;
					if (floating)
						[compositor compositeLayer:[[document contents] layer:i] withFloat:[[document contents] layer:i - 1] andOptions:options];
					else
						[compositor compositeLayer:[[document contents] layer:i] withOptions:options];
				}
				if (floating) i--;
			}
			
		}
		else {

			// Go through compositing each visible layer
			for (i = layerCount - 1; i >= 0; i--) {
				if ([[[document contents] layer:i] visible]) {
					options.insertOverlay = (i == [[document contents] activeLayerIndex]);
					options.useSelection = (i == [[document contents] activeLayerIndex]) && [[document selection] active];
					[compositor compositeLayer:[[document contents] layer:i] withOptions:options];
				}
			}
			
		}
		
	}
	
	// Handle channel updates here
	if (viewType == kPrimaryChannelsView || viewType == kAlphaChannelView) {
		[self forcedChannelUpdate];
	}
	
	// If the user has requested a CMYK preview take the extra steps necessary
	if (viewType == kCMYKPreviewView) {
		[self forcedCMYKUpdate:majorUpdateRect];
	}
}

- (void)update
{
	useUpdateRect = NO;
	[self forcedUpdate];
	[[document docView] setNeedsDisplay:YES];
}

- (void)update:(IntRect)rect inThread:(BOOL)thread
{
	NSRect displayUpdateRect = IntRectMakeNSRect(rect);
	float zoom = [[document docView] zoom];
	int xres = [[document contents] xres], yres = [[document contents] yres];
	
	if (gScreenResolution.x != 0 && xres != gScreenResolution.x) {
		displayUpdateRect.origin.x /= ((float)xres / gScreenResolution.x);
		displayUpdateRect.size.width /= ((float)xres / gScreenResolution.x);
	}
	if (gScreenResolution.y != 0 && yres != gScreenResolution.y) {
		displayUpdateRect.origin.y /= ((float)yres / gScreenResolution.y);
		displayUpdateRect.size.height /= ((float)yres / gScreenResolution.y);
	}
	displayUpdateRect.origin.x *= zoom;
	displayUpdateRect.size.width *= zoom;
	displayUpdateRect.origin.y *= zoom;
	displayUpdateRect.size.height *= zoom;
	
	// Free us from hairlines
	displayUpdateRect.origin.x = floor(displayUpdateRect.origin.x);
	displayUpdateRect.origin.y = floor(displayUpdateRect.origin.y);
	displayUpdateRect.size.width = ceil(displayUpdateRect.size.width) + 1.0;
	displayUpdateRect.size.height = ceil(displayUpdateRect.size.height) + 1.0;
	
	// Now do the rest of the update
	useUpdateRect = YES;
	updateRect = rect;
	[self forcedUpdate];
	if (thread) {
		threadUpdateRect = displayUpdateRect;
		[[document docView] lockFocus];
		[NSBezierPath clipRect:threadUpdateRect];
		[[document docView] drawRect:threadUpdateRect];
		//[[NSGraphicsContext currentContext] flushGraphics];
		[[document docView] setNeedsDisplayInRect:displayUpdateRect];
		[[document docView] unlockFocus];
	}
	else {
		[[document docView] setNeedsDisplayInRect:displayUpdateRect];
	}
}

- (void)updateColorWorld
{
	CMProfileRef destProf;
	
	if (cw) CWDisposeColorWorld(cw);
	if (displayProf) CloseDisplayProfile(displayProf);
	if (cgDisplayProf) CGColorSpaceRelease(cgDisplayProf);
	OpenDisplayProfile(&displayProf);
	cgDisplayProf = CGColorSpaceCreateWithPlatformColorSpace(displayProf);
	CMGetDefaultProfileBySpace(cmCMYKData, &destProf);
	NCWNewColorWorld(&cw, displayProf, destProf);
	if ([self CMYKPreview])
		[self update];
}

- (IntRect)imageRect
{
	id layer;
	
	if (viewType == kPrimaryChannelsView || viewType == kAlphaChannelView) {
		if ([[document selection] floating])
			layer = [[document contents] layer:[[document contents] activeLayerIndex] + 1];
		else
			layer = [[document contents] activeLayer];
		return IntMakeRect([layer xoff], [layer yoff], [(SeaLayer *)layer width], [(SeaLayer *)layer height]);
	}
	else {
		return IntMakeRect(0, 0, width, height);
	}
}

- (NSImage *)image
{
	NSBitmapImageRep *imageRep;
	NSBitmapImageRep *altImageRep = NULL;
	id contents = [document contents];
	int xwidth, xheight;
	id layer;
	
	if (image) [image autorelease];
	image = [[NSImage alloc] init];
	
	if (altData) {
		if ([[document selection] floating]) {
			layer = [contents layer:[contents activeLayerIndex] + 1];
		}
		else {
			layer = [contents activeLayer];
		}
		if (viewType == kPrimaryChannelsView) {
			xwidth = [(SeaLayer *)layer width];
			xheight = [(SeaLayer *)layer height];
			altImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&altData pixelsWide:xwidth pixelsHigh:xheight bitsPerSample:8 samplesPerPixel:spp - 1 hasAlpha:NO isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:xwidth * (spp - 1) bitsPerPixel:8 * (spp - 1)];
		}
		else if (viewType == kAlphaChannelView) {
			xwidth = [(SeaLayer *)layer width];
			xheight = [(SeaLayer *)layer height];
			altImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&altData pixelsWide:xwidth pixelsHigh:xheight bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceWhiteColorSpace bytesPerRow:xwidth * 1 bitsPerPixel:8];
		}
		else if (viewType == kCMYKPreviewView) {
			xwidth = [(SeaContent *)contents width];
			xheight = [(SeaContent *)contents height];
			altImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&altData pixelsWide:xwidth pixelsHigh:xheight bitsPerSample:8 samplesPerPixel:4 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceCMYKColorSpace bytesPerRow:xwidth * 4 bitsPerPixel:8 * 4];
		}
		[image addRepresentation:altImageRep];
	}
	else {
		imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * spp bitsPerPixel:8 * spp];
		[image addRepresentation:imageRep];
	}
	
	return image;
}

- (NSImage *)printableImage
{
	NSBitmapImageRep *imageRep;
	
	if (image) [image autorelease];
	image = [[NSImage alloc] init];
	imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * spp bitsPerPixel:8 * spp];
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

- (CGColorSpaceRef)displayProf
{
	return cgDisplayProf;
}

@end

#import "SeaScale.h"
#import "SeaContent.h"
#import "SeaDocument.h"
#import "SeaLayer.h"
#import "SeaLayerUndo.h"
#import "SeaView.h"
#import "SeaWhiteboard.h"
#import "SeaHelpers.h"
#import "SeaSelection.h"
#import "Units.h"

@implementation ScaleUndoRecord
- (ScaleUndoRecord*)init
{
    self = [super init];
    records = [NSMutableArray array];
    return self;
}
@end
@implementation ScaleSnapshotUndoRecord
@end

@implementation SeaScale

- (id)init
{
	return self;
}

- (void)run:(BOOL)global
{
	id contents = [document contents];
	id layer = NULL;
	id menuItem;
	int value;
	NSString *string;
	float xres, yres;
	
	// Determine the working index
	if (global)
		workingIndex = kAllLayers;
	else
		workingIndex = [contents activeLayerIndex];
		
	// Set the selection label correctly
	if (workingIndex == kAllLayers) {
		[selectionLabel setStringValue:LOCALSTR(@"whole document", @"Whole Document")];
	}
	else {
		layer = [contents layer:workingIndex];
        [selectionLabel setStringValue:[NSString stringWithFormat:@"%@", [layer name]]];
	}
	
	// Set paper name
	if ([[document printInfo] respondsToSelector:@selector(localizedPaperName)]) {
		menuItem = [presetsMenu itemAtIndex:[presetsMenu indexOfItemWithTag:2]];
		string = [NSString stringWithFormat:@"%@ (%@)", LOCALSTR(@"paper size", @"Paper size"), [[document printInfo] localizedPaperName]];
		[menuItem setTitle:string];
	}
	
	// Get the resolutions
	xres = [contents xres];
	yres = [contents yres];
	units = [document measureStyle];
	[widthPopdown selectItemAtIndex:units];
	[heightUnits setTitle:UnitsString(units)];
	
	// Set the initial scale values
	[xScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", 100.0]];
	[yScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", 100.0]];
	
	// Set the initial width and height values
	if (workingIndex == kAllLayers) {
		[widthValue setStringValue:StringFromPixels([(SeaContent *)contents width], units, xres)];
		[heightValue setStringValue:StringFromPixels([(SeaContent *)contents height], units, yres)];
	}
	else {
		[widthValue setStringValue:StringFromPixels([(SeaLayer *)layer width], units, xres)];
		[heightValue setStringValue:StringFromPixels([(SeaLayer *)layer height], units, yres)];
	}
	
	// Set the options appropriately
	[keepProportions setState:NSOnState];
	
	// Set the interpolation style
	if ([gUserDefaults objectForKey:@"interpolation"] == NULL) {
		value = 3;
	}
	else {
		value = [gUserDefaults integerForKey:@"interpolation"];
		if (value < 0 || value >= [interpolationPopup numberOfItems])
            value = 3;
	}
    [interpolationPopup selectItemAtIndex:value];
	
	// Show the sheet
	[NSApp beginSheet:sheet modalForWindow:[document window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)apply:(id)sender
{
	id contents = [document contents];
	int newWidth, newHeight;
	float xres, yres;
	
	// Get the resolutions
	xres = [contents xres];
	yres = [contents yres];
	
    
    [sheet makeFirstResponder:sender];
    [NSApp endSheet:[sender window]];
    [sheet orderOut:self];
    
	// End the sheet
	[gUserDefaults setInteger:[interpolationPopup indexOfSelectedItem] forKey:@"interpolation"];

	// Parse width and height	
	newWidth = PixelsFromFloat([widthValue floatValue],units,xres);
	newHeight = PixelsFromFloat([heightValue floatValue],units,yres);
	
	// Don't do if values are unreasonable or unchanged
	if (newWidth < kMinImageSize || newWidth > kMaxImageSize) { NSBeep(); return; }
	if (newHeight < kMinImageSize || newHeight > kMaxImageSize) { NSBeep(); return; }
	if (workingIndex == kAllLayers) {
		if (newWidth == [(SeaContent *)contents width] && newHeight == [(SeaContent *)contents height]) { return; }
	}
	else {
		if (newWidth == [(SeaContent *)[contents activeLayer] width] && newHeight == [(SeaContent *)[contents activeLayer] height]) { return; }
	}
    
    NSImageInterpolation interpolation = [interpolationPopup selectedTag];
	
	// Make the changes
	[self scaleToWidth:newWidth height:newHeight interpolation:interpolation index:workingIndex];
}

- (IBAction)cancel:(id)sender
{
	[NSApp endSheet:sheet];
	[sheet orderOut:self];
}

- (void)scaleToWidth:(int)width height:(int)height xorg:(int)xorg yorg:(int)yorg moving:(BOOL)isMoving interpolation:(int)interpolation index:(int)index undoRecord:(ScaleUndoRecord *)undoRecord
{
    SeaContent *contents = [document contents];
    SeaLayer *curLayer;

	int whichLayer, oldWidth, oldHeight;
	int layerCount = [contents layerCount];
	float xScale, yScale;
	int x, y;
	
    // Correct the index if necessary
	if (index == kActiveLayer)
		index = [[document contents] activeLayerIndex];
	
	// Work out the old height and width
	if (index == kAllLayers) {
		oldWidth = [(SeaContent *)contents width];
		oldHeight = [(SeaContent *)contents height];
	}
	else {
		oldWidth = [(SeaLayer *)[contents layer:index] width];
		oldHeight = [(SeaLayer *)[contents layer:index] height];
	}
	
	// Prepare an undo record
	if (undoRecord) {
		undoRecord->unscaledWidth = oldWidth;
		undoRecord->unscaledHeight = oldHeight;
		undoRecord->scaledWidth = width;
		undoRecord->scaledHeight = height;
		undoRecord->scaledXOrg = xorg;
		undoRecord->scaledYOrg = yorg;
		undoRecord->isMoving = isMoving;
		undoRecord->index = index;
		undoRecord->interpolation = interpolation;
		undoRecord->isScaled = YES;
	}

	// Change the document's size if required
	if (index == kAllLayers)
		[[document contents] setWidth:width height:height];

	// Determine the scaling rate
	xScale = ((float)width / (float)oldWidth);
	yScale = ((float)height / (float)oldHeight);
	[[document selection] scaleSelectionHorizontally:xScale vertically:yScale interpolation:interpolation];

	// Go through each layer
	for (whichLayer = 0; whichLayer < layerCount; whichLayer++) {
	
		// Check if the layer is needs to be scaled
		if (index == kAllLayers || index == whichLayer) {
			
			// Get the layer
			curLayer = [[document contents] layer:whichLayer];
			
			// Take a manual snapshot (recording the snapshot index)
			if (undoRecord) {
                ScaleSnapshotUndoRecord *r = [[ScaleSnapshotUndoRecord alloc] init];
				r->snapshot = [[curLayer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, [curLayer width], [curLayer height]) automatic:NO];
                r->rect = [curLayer globalRect];
                [undoRecord->records addObject:r];
			}
						
			// Change the layer's size
			[curLayer scaleX:xScale scaleY:yScale rotate:0];
			if (index == kAllLayers){
				[curLayer setOffsets:IntMakePoint([curLayer xoff] * xScale, [curLayer yoff] * yScale)];
			}else if(isMoving) {
				[curLayer setOffsets:IntMakePoint(xorg, yorg)];
			}else {
				x = [curLayer xoff] + ((float)oldWidth - (float)oldWidth * xScale) / 2.0;
				y = [curLayer yoff] + ((float)oldHeight - (float)oldHeight * yScale) / 2.0;
				[curLayer setOffsets:IntMakePoint(x, y)];
			}
		}
	}
	
	if (index != kAllLayers) {
		curLayer = [[document contents] layer:index];
	}
}


- (void)scaleToWidth:(int)width height:(int)height interpolation:(int)interpolation index:(int)index
{
    ScaleUndoRecord *undoRecord = [[ScaleUndoRecord alloc] init];

    @synchronized (document.mutex) {
        [self scaleToWidth:width height:height xorg: 0 yorg: 0 moving: NO interpolation:interpolation index:index undoRecord:undoRecord];
    }

	[[[document undoManager] prepareWithInvocationTarget:self] undoScale:undoRecord];

	// Clear selection
	[[document selection] clearSelection];
	
	// Do appropriate updating
	if (index == kAllLayers)
		[[document helpers] boundariesAndContentChanged];
	else
		[[document helpers] layerBoundariesChanged:index];
}

- (void)scaleToWidth:(int)width height:(int)height xorg:(int)xorg yorg:(int)yorg interpolation:(int)interpolation index:(int)index
{
    ScaleUndoRecord *undoRecord = [[ScaleUndoRecord alloc] init];
	
    @synchronized (document.mutex) {
        [self scaleToWidth:width height:height xorg: xorg yorg: yorg moving: YES interpolation:interpolation index:index undoRecord:undoRecord];
    }
	
	[[[document undoManager] prepareWithInvocationTarget:self] undoScale:undoRecord];

	// Clear selection
	[[document selection] clearSelection];
	
	// Do appropriate updating
	if (index == kAllLayers){
		[[document helpers] boundariesAndContentChanged];
	}else{
		[[document helpers] layerBoundariesChanged:index];
	}
}

- (void)undoScale:(ScaleUndoRecord*)undoRecord
{
    SeaContent *contents = [document contents];
    SeaLayer *curLayer;

	int whichLayer;
	int layerCount = [contents layerCount];
	int changeX, changeY;

    @synchronized (document.mutex) {

        // We have different responses depending on whether the image is scaled or not
        if (undoRecord->isScaled) {

            if (undoRecord->index == kAllLayers) {

                // Change the document's size
                [[document contents] setWidth:undoRecord->unscaledWidth height:undoRecord->unscaledHeight];

                // Go through each layer
                for (whichLayer = 0; whichLayer < layerCount; whichLayer++) {

                    // Determine the current layer
                    curLayer = [[document contents] layer:whichLayer];

                    ScaleSnapshotUndoRecord *r = undoRecord->records[whichLayer];

                    // Change the layer's size
                    changeX = r->rect.size.width - [curLayer width];
                    changeY = r->rect.size.height - [curLayer height];
                    [curLayer setMarginLeft:0 top:0 right:changeX bottom:changeY];
                    [curLayer setOffsets:r->rect.origin];
                    [[curLayer seaLayerUndo] restoreSnapshot:r->snapshot automatic:NO];

                }
                // Now the image is no longer scaled
                undoRecord->isScaled = NO;

            }
            else {

                // Determine the current layer
                curLayer = [[document contents] layer:undoRecord->index];

                ScaleSnapshotUndoRecord *r = undoRecord->records[0];

                // Change the layer's size
                changeX = r->rect.size.width - [curLayer width];
                changeY = r->rect.size.height - [curLayer height];
                [curLayer setMarginLeft:0 top:0 right:changeX bottom:changeY];
                [curLayer setOffsets:r->rect.origin];
                [[curLayer seaLayerUndo] restoreSnapshot:r->snapshot automatic:NO];

                // Now the image is no longer scaled
                undoRecord->isScaled = NO;
            }

        }
        else {

            // Otherwise just reverse the process with the information we stored on the original scaling
            [self scaleToWidth:undoRecord->scaledWidth height:undoRecord->scaledHeight xorg: undoRecord->scaledXOrg yorg: undoRecord->scaledYOrg moving: undoRecord->isMoving interpolation:undoRecord->interpolation index:undoRecord->index undoRecord:NULL];
            undoRecord->isScaled = YES;
        }
    }
	[[[document undoManager] prepareWithInvocationTarget:self] undoScale:undoRecord];
	
	// Clear selection
	[[document selection] clearSelection];
	
	// Do appropriate updating
	if (undoRecord->index == kAllLayers)
		[[document helpers] boundariesAndContentChanged];
	else
		[[document helpers] layerBoundariesChanged:undoRecord->index];
	
	if (undoRecord->index != kAllLayers) {
		curLayer = [[document contents] layer:undoRecord->index];
	}
}

- (IBAction)toggleKeepProportions:(id)sender
{
	float scaleValue = [xScaleValue floatValue];
	id contents = [document contents], layer;
	
	if ([keepProportions state]) {
		
		// Make the scale values the same
		[xScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", scaleValue]];
		[yScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", scaleValue]];
		
		// Determine the width and height values
		if (workingIndex == kAllLayers) {
			[widthValue setIntValue:[(SeaContent *)contents width] * (scaleValue / 100.0)];
			[heightValue setIntValue:[(SeaContent *)contents height] * (scaleValue / 100.0)];
		}
		else {
			layer = [contents layer:workingIndex];
			[widthValue setIntValue:[(SeaLayer *)layer width] * (scaleValue / 100.0)];
			[heightValue setIntValue:[(SeaContent *)layer height] * (scaleValue / 100.0)];
		}
	}
}

- (IBAction)valueChanged:(id)sender
{
	BOOL keepProp = [keepProportions state];
	id contents = [document contents];
	id focusObject;
	float xres, yres;
	
	// Get the resolutions
	xres = [contents xres];
	yres = [contents yres];
	
	// Work out the focus object
	if (workingIndex == kAllLayers)
		focusObject = contents;
	else
		focusObject = [contents layer:workingIndex];
	
	// Handle a horizontal scale change
	if ([sender tag] == 0) {
		[xScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", [xScaleValue floatValue]]];
		if (keepProp) [yScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", [xScaleValue floatValue]]];
		[widthValue setStringValue:StringFromPixels([(SeaContent *)focusObject width] * ([xScaleValue floatValue] / 100.0), units, xres)];
		if (keepProp) [heightValue setStringValue:StringFromPixels([(SeaContent *)focusObject height] * ([yScaleValue floatValue] / 100.0), units, yres)];
		return;
	}
	
	// Handle a vertical scale change
	if ([sender tag] == 1) {
		[yScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", [yScaleValue floatValue]]];
		if (keepProp) [xScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", [yScaleValue floatValue]]];
		[heightValue setStringValue:StringFromPixels([(SeaContent *)focusObject height] * ([yScaleValue floatValue] / 100.0), units, yres)];
		if (keepProp) [widthValue setStringValue:StringFromPixels([(SeaContent *)focusObject width] * ([xScaleValue floatValue] / 100.0), units, xres)];
		return;
	}
	
	
	// Handle a width change
	if ([sender tag] == 2) {
		[xScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", PixelsFromFloat([widthValue floatValue],units, xres) / (float)[(SeaContent *)focusObject width] * 100.0]];
		if (keepProp) {
			[yScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", [xScaleValue floatValue]]];
			[heightValue setStringValue:StringFromPixels([(SeaContent *)focusObject height] * ([yScaleValue floatValue] / 100.0),units, yres)];
		}
		return;
	}
	
	// Handle a height change
	if ([sender tag] == 3) {
		[yScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", PixelsFromFloat([heightValue floatValue],units, yres) / (float)[(SeaContent *)focusObject height] * 100.0]];
		if (keepProp) {
			[xScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", [yScaleValue floatValue]]];
			[widthValue setStringValue:StringFromPixels([(SeaContent *)focusObject width] * ([xScaleValue floatValue] / 100.0),units, xres)];
		}
		return;
	}
}

- (IBAction)unitsChanged:(id)sender
{
	// BOOL keepProp = [keepProportions state];
	id contents = [document contents];
	id focusObject;
	float xres, yres;
	
	// Get the resolutions
	xres = [contents xres];
	yres = [contents yres];
	
	// Work out the focus object
	if (workingIndex == kAllLayers)
		focusObject = contents;
	else
		focusObject = [contents layer:workingIndex];
	
	// Handle a unit change
	units = [sender indexOfSelectedItem];
	[widthValue setStringValue:StringFromPixels([(SeaContent *)focusObject width] * ([xScaleValue floatValue] / 100.0), units, xres)];
	[heightValue setStringValue:StringFromPixels([(SeaContent *)focusObject height] * ([yScaleValue floatValue] / 100.0), units, yres)];
	[heightUnits setTitle:UnitsString(units)];
}

- (IBAction)changeToPreset:(id)sender
{
	NSPasteboard *pboard;
	NSString *availableType;
	NSImage *image;
	NSSize paperSize;
	IntSize size = IntMakeSize(0, 0);
	float xres, yres;
	int pchoice;
	id focusObject;
	id contents = [document contents];
	
	// Get the preset's size
	if (workingIndex == kAllLayers)
		focusObject = contents;
	else
		focusObject = [contents layer:workingIndex];
	xres = [contents xres];
	yres = [contents yres];
	switch ([[presetsMenu selectedItem] tag]) {
		case 0:
			pboard = [NSPasteboard generalPasteboard];
			availableType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NULL]];
			if (availableType) {
				image = [[NSImage alloc] initWithData:[pboard dataForType:availableType]];
				size = NSSizeMakeIntSize([image size]);
			}
			else {
				NSBeep();
				return;
			}
		break;
		case 1:
			size = NSSizeMakeIntSize([[NSScreen mainScreen] frame].size);
		break;
		case 2:
			paperSize = [[document printInfo] paperSize];
			paperSize.height -= [[document printInfo] topMargin] + [[document printInfo] bottomMargin];
			paperSize.width -= [[document printInfo] leftMargin] + [[document printInfo] rightMargin];
			size = NSSizeMakeIntSize(paperSize);
			size.width = (float)size.width * (xres / 72.0);
			size.height = (float)size.height * (yres / 72.0);
		break;
	}
	
	// Deal with keep proportions checkbox
	if ([keepProportions state]) {
		if ((float)size.width / (float)[(SeaContent *)focusObject width] < (float)size.height / (float)[(SeaContent *)focusObject height])
			pchoice = 1;
		else
			pchoice = 2;
	}
	else {
		pchoice = 0;
	}
	
	// Make the change
	switch (units) {
		case kPixelUnits:
			switch (pchoice) {
				case 0:
					[widthValue setIntValue:size.width];
					[self valueChanged:widthValue];
					[heightValue setIntValue:size.height];
					[self valueChanged:heightValue];
				break;
				case 1:
					[widthValue setIntValue:size.width];
					[self valueChanged:widthValue];
				break;
				case 2:
					[heightValue setIntValue:size.height];
					[self valueChanged:heightValue];
				break;
			}
		break;
		case kInchUnits:
			switch (pchoice) {
				case 0:
					[widthValue setStringValue:[NSString stringWithFormat:@"%.2f", (float)size.width / xres]];
					[self valueChanged:widthValue];
					[heightValue setStringValue:[NSString stringWithFormat:@"%.2f", (float)size.height / yres]];
					[self valueChanged:heightValue];
				break;
				case 1:
					[widthValue setStringValue:[NSString stringWithFormat:@"%.2f", (float)size.width / xres]];
					[self valueChanged:widthValue];
				break;
				case 2:
					[heightValue setStringValue:[NSString stringWithFormat:@"%.2f", (float)size.height / yres]];
					[self valueChanged:heightValue];
				break;
			}
		break;
		case kMillimeterUnits:
			switch (pchoice) {
				case 0:
					[widthValue setStringValue:[NSString stringWithFormat:@"%.0f", (float)size.width / xres * 25.4]];
					[self valueChanged:widthValue];
					[heightValue setStringValue:[NSString stringWithFormat:@"%.0f", (float)size.height / yres * 25.4]];
					[self valueChanged:heightValue];
				break;
				case 1:
					[widthValue setStringValue:[NSString stringWithFormat:@"%.0f", (float)size.width / xres * 25.4]];
					[self valueChanged:widthValue];
				break;
				case 2:
				[heightValue setStringValue:[NSString stringWithFormat:@"%.0f", (float)size.height / yres * 25.4]];
					[self valueChanged:heightValue];
				break;
			}
		break;
	}
}
@end

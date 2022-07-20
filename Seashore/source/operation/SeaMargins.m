#import "SeaMargins.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaWhiteboard.h"
#import "SeaView.h"
#import "SeaLayer.h"
#import "SeaLayerUndo.h"
#import "SeaHelpers.h"
#import "SeaScale.h"
#import "SeaSelection.h"
#import "Units.h"

@interface MarginUndoRecord : NSObject
{
    @public
    int index;
    int left;
    int top;
    int right;
    int bottom;
    BOOL isChanged;
    LayerSnapshot* snapshots[4];
}
@end

@implementation MarginUndoRecord
@end

@implementation SeaMargins

- (id)init
{
	return self;
}

- (void)dealloc
{
}

- (void)determineContentBorders
{
}

- (void)show
{
	units = [document measureStyle];
	
	float xres = [[document contents] xres];
	float yres = [[document contents] yres];
	
	[heightLabel setStringValue:UnitsString(units)];
	[widthPopdown selectItemAtIndex:units];
    [leftLabel setStringValue:UnitsString(units)];
    [topLabel setStringValue:UnitsString(units)];

    [widthValue setStringValue:StringFromPixels([[document contents] width], units, xres)];
    [heightValue setStringValue:StringFromPixels([[document contents] height],units, yres)];

    [leftValue setStringValue:StringFromPixels(0, units, xres)];
    [topValue setStringValue:StringFromPixels(0, units, yres)];

	[NSApp beginSheet:sheet modalForWindow:[document window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)apply:(id)sender
{
    [sheet makeFirstResponder:sender];
	[NSApp endSheet:sheet];
	[sheet orderOut:self];

    int oldWidth = [[document contents] width];
    int oldHeight = [[document contents] height];

	// Find the resolution
	float xres = [[document contents] xres];
	float yres = [[document contents] yres];
	
	// Calculate the margin changes in pixels
	int width = PixelsFromFloat([widthValue floatValue], units, xres);
    int height = PixelsFromFloat([heightValue floatValue], units, yres);

    int left = PixelsFromFloat([leftValue floatValue], units, xres);
    int top = PixelsFromFloat([topValue floatValue], units, yres);

    if(width > kMaxImageSize || height > kMaxImageSize) {
        NSBeep();
        return;
    }

    [[document helpers] endLineDrawing];

    if([contentRelative state]) {
        IntRect r = [self contentRect];
        int left = r.origin.x;
        int top = r.origin.y;
        int right = oldWidth-r.size.width-left;
        int bottom = oldHeight-r.size.height-top;
        [self setMarginLeft:-left top:-top right:-right bottom:-bottom index:kAllLayers];
    } else if([adjustLayerBoundaries state]) {
        int diffx = (width-oldWidth)/2;
        int diffy = (height-oldHeight)/2;
        [self setMarginLeft:diffx top:diffy right:diffx bottom:diffy index:kAllLayers];
    } else {
        [self setMarginLeft:left top:top right:(width-oldWidth)-left bottom:(height-oldHeight)-top index:kAllLayers];
    }
}

- (IntRect)contentRect
{
    IntRect r = IntZeroRect;
    for(int i=0;i<[[document contents] layerCount];i++){
        SeaLayer *layer = [[document contents] layer:i];
        Margins m = [layer contentMargins];
        IntRect r0 = IntMakeRect([layer xoff]+m.left,[layer yoff]+m.top,[layer width]-(m.right+m.left),[layer height]-(m.top+m.bottom));
        if(IntRectIsEmpty(r)) {
            r = r0;
        } else {
            r = IntSumRects(r,r0);
        }
    }
    return r;
}

- (IBAction)cancel:(id)sender
{
	[NSApp endSheet:sheet];
	[sheet orderOut:self];
}

- (IBAction)condenseLayer:(id)sender
{
    Margins m = [[[document contents] activeLayer] contentMargins];
	int index = [[document contents] activeLayerIndex];

	[self setMarginLeft:-m.left top:-m.top right:-m.right bottom:-m.bottom index:index];
}

- (IBAction)condenseToSelection:(id)sender
{
	int index = [[document contents] activeLayerIndex];

	SeaLayer *activeLayer = [[document contents] activeLayer];
	IntRect selRect = [[document selection] globalRect];

	int top = [activeLayer height] - selRect.origin.y - selRect.size.height;
	int right = [activeLayer width] - selRect.origin.x - selRect.size.width;
	
	[self setMarginLeft:-selRect.origin.x top:-selRect.origin.y right:-right bottom:-top index:index];
}

- (IBAction)expandLayer:(id)sender
{
	id layer;
	int width, height;
	
	layer = [[document contents] activeLayer];
	width = [(SeaContent *)[document contents] width];
	height = [(SeaContent *)[document contents] height];
	[self setMarginLeft:[layer xoff] top:[layer yoff] right:width - ([layer xoff] + [(SeaLayer *)layer width]) bottom:height - ([layer yoff] + [(SeaLayer *)layer height]) index:kActiveLayer];
}

- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom index:(int)index undoRecord:(MarginUndoRecord *)undoRecord
{
    id contents = [document contents];
    SeaLayer *layer = NULL;

	int i;
	
	// Correct the index if necessary
	if (index == kActiveLayer)
		index = [[document contents] activeLayerIndex];
		
	// Get the layer if appropriate
	if (index != kAllLayers)
		layer = [contents layer:index];
	
	// Take the snapshots if necessary
	if (undoRecord) {
		undoRecord->left = left;
		undoRecord->top = top;
		undoRecord->right = right;
		undoRecord->bottom = bottom;
		if (index != kAllLayers) {
			for (i = 0; i < 4; i++)
				undoRecord->snapshots[i] = NULL;
			if (left < 0)
				undoRecord->snapshots[0] = [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, -left, [layer height]) automatic:NO];
			if (top < 0)
				undoRecord->snapshots[1] = [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, [layer width],  -top) automatic:NO];
			if (right < 0)
				undoRecord->snapshots[2] = [[layer seaLayerUndo] takeSnapshot:IntMakeRect([layer width] + right, 0, -right, [layer height]) automatic:NO];
			if (bottom < 0)
				undoRecord->snapshots[3] = [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, [layer height] + bottom, [layer width], -bottom) automatic:NO];
		}
	}
	
	// Adjust the margins
	if (index == kAllLayers) {
		[[document contents] setMarginLeft:left top:top right:right bottom:bottom];
	}
	else {
		[layer setMarginLeft:left top:top right:right bottom:bottom];
	}
	
	// Update the undo record
	if (undoRecord) {
		undoRecord->index = index;
		undoRecord->isChanged = YES;
	}
}

- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom index:(int)index
{	
    MarginUndoRecord* undoRecord = [[MarginUndoRecord alloc] init];
	
	// Don't do anything if no changes are needed
	if (left == 0 && top == 0 && right == 0 && bottom == 0)
		return;
	
	// Do the adjustment
	[self setMarginLeft:left top:top right:right bottom:bottom index:index undoRecord:undoRecord];

	[[[document undoManager] prepareWithInvocationTarget:self] undoMargins:undoRecord];

	// Do appropriate updating
	if (index == kAllLayers)
		[[document helpers] boundariesAndContentChanged];
	else
		[[document helpers] layerBoundariesChanged:index];
}

- (void)undoMargins:(MarginUndoRecord*)undoRecord
{
	id layer, contents = [document contents];
	int i;
	
	// We have different responses depending on whether the change is current or not
	if (undoRecord->isChanged) {
		if (undoRecord->index == kAllLayers) {
			[contents setMarginLeft:-undoRecord->left top:-undoRecord->top right:-undoRecord->right bottom:-undoRecord->bottom];
		}
		else {
			layer = [contents layer:undoRecord->index];
			[layer setMarginLeft:-undoRecord->left top:-undoRecord->top right:-undoRecord->right bottom:-undoRecord->bottom];
			for (i = 0; i < 4; i++) {
				if (undoRecord->snapshots[i] != NULL) {
					[[layer seaLayerUndo] restoreSnapshot:undoRecord->snapshots[i] automatic: NO];
				}
			}
		}
		undoRecord->isChanged = NO;
	}
	else {
		[self setMarginLeft:undoRecord->left top:undoRecord->top right:undoRecord->right bottom:undoRecord->bottom index:undoRecord->index undoRecord:NULL];
		undoRecord->isChanged = YES;
	}
	
	[[[document undoManager] prepareWithInvocationTarget:self] undoMargins:undoRecord];
	
	// Do appropriate updating
	if (undoRecord->index == kAllLayers)
		[[document helpers] boundariesAndContentChanged];
	else
		[[document helpers] layerBoundariesChanged:undoRecord->index];
}

- (IBAction)marginsChanged:(id)sender
{
    int oldWidth = [[document contents] width];
    int oldHeight = [[document contents] height];

    bool relative = [contentRelative state];

    [widthValue setEnabled:!relative];
    [heightValue setEnabled:!relative];
    [adjustLayerBoundaries setEnabled:!relative];

    bool offsets_enabled = !relative && ![adjustLayerBoundaries state];

    [leftValue setEnabled:offsets_enabled];
    [topValue setEnabled:offsets_enabled];

    float xres = [[document contents] xres];
    float yres = [[document contents] yres];

    int width = PixelsFromFloat([widthValue floatValue], units, xres);
    int height = PixelsFromFloat([heightValue floatValue], units, yres);

    if(relative) {
        IntRect r = [self contentRect];
        [widthValue setStringValue:StringFromPixels(r.size.width, units, xres)];
        [heightValue setStringValue:StringFromPixels(r.size.height, units, yres)];
        [leftValue setStringValue:StringFromPixels(-r.origin.x, units, xres)];
        [topValue setStringValue:StringFromPixels(-r.origin.y, units, yres)];
    } else if([adjustLayerBoundaries state]) {
        int diffx = (width-oldWidth)/2;
        int diffy = (height-oldHeight)/2;
        [leftValue setStringValue:StringFromPixels(diffx, units, xres)];
        [topValue setStringValue:StringFromPixels(diffy, units, yres)];
    } else {
        // use entered values
    }
}


- (IBAction)unitsChanged:(id)sender
{
	float xres = [[document contents] xres];
	float yres = [[document contents] yres];
	
    // Determine the new width and height
    int width = PixelsFromFloat([widthValue floatValue], units, xres);
    int height = PixelsFromFloat([heightValue floatValue], units, yres);
    int left = PixelsFromFloat([leftValue floatValue], units, xres);
    int top = PixelsFromFloat([topValue floatValue], units, yres);

	units = [sender indexOfSelectedItem];

	[heightLabel setStringValue :UnitsString(units)];
    [leftLabel setStringValue :UnitsString(units)];
    [topLabel setStringValue :UnitsString(units)];

    [widthValue setStringValue:StringFromPixels(width, units, xres)];
    [heightValue setStringValue:StringFromPixels(height, units, yres)];
    [leftValue setStringValue:StringFromPixels(left, units, xres)];
    [topValue setStringValue:StringFromPixels(top, units, yres)];
}

@end

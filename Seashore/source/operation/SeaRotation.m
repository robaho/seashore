#import "PositionTool.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaWhiteboard.h"
#import "SeaView.h"
#import "SeaHelpers.h"
#import "SeaTools.h"
#import "SeaSelection.h"
#import "SeaLayerUndo.h"
#import "SeaRotation.h"

@implementation RotationUndoRecord
@end

@implementation SeaRotation

- (id)init
{
	return self;
}

- (void)run
{
	id contents = [document contents];
	id layer = NULL;

	// Fill out the selection label
	layer = [contents layer:[contents activeLayerIndex]];
    [selectionLabel setStringValue:[NSString stringWithFormat:@"%@", [layer name]]];
	
	// Set the initial values
	[rotateValue setStringValue:@"0"];

	// Show the sheet
	[NSApp beginSheet:sheet modalForWindow:[document window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)apply:(id)sender
{
	id contents = [document contents];

	// End the sheet
    [sheet makeFirstResponder:sender];
	[NSApp endSheet:sheet];
	[sheet orderOut:self];

	// Rotate the image
	if ([rotateValue floatValue] != 0) {
		[self rotate:[rotateValue floatValue] withTrim:FALSE];
	}
}

- (IBAction)cancel:(id)sender
{
	// End the sheet
	[NSApp endSheet:sheet];
	[sheet orderOut:self];
}

static inline float mod_float(float value, float divisor)
{
	float result;
	
	if (value < 0.0) result = value * -1.0;
	else result = value;
	while (result - 360.0 >= 0.0) {
		result -= 360.0;
	}
	
	return result;
}

- (void)rotate:(float)degrees withTrim:(BOOL)trim
{
	id contents = [document contents];
	id activeLayer = [contents activeLayer];

    RotationUndoRecord* undoRecord = [[RotationUndoRecord alloc] init];

    if(degrees>0)
        degrees = mod_float(degrees, 360);
    else
        degrees = 360 - mod_float(degrees,360);
	if (degrees == 0.0)
		return;

	// Record the undo details
	undoRecord->index =  [contents activeLayerIndex];
	undoRecord->rotation = degrees;
	undoRecord->snapshot = [[activeLayer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, [(SeaLayer *)activeLayer width], [(SeaLayer *)activeLayer height]) automatic:NO];
	undoRecord->rect = IntMakeRect([activeLayer xoff], [activeLayer yoff], [(SeaLayer *)activeLayer width], [(SeaLayer *)activeLayer height]);
	undoRecord->isRotated = YES;
	undoRecord->withTrim = trim;
	[[[document undoManager] prepareWithInvocationTarget:self] undoRotation:undoRecord];
	[activeLayer setRotation:degrees interpolation:NSImageInterpolationHigh withTrim:trim];
	[[document selection] clearSelection];
	if (!trim && ![activeLayer hasAlpha]) {
		undoRecord->disableAlpha = YES;
		[activeLayer toggleAlpha];
	}
	else {
		undoRecord->disableAlpha = NO;
	}
	[[document helpers] layerBoundariesChanged:kActiveLayer];
}

- (void)undoRotation:(RotationUndoRecord*)undoRecord
{
	id contents = [document contents];
	SeaLayer *layer;
	
	// Prepare for redo
	[[[document undoManager] prepareWithInvocationTarget:self] undoRotation:undoRecord];
	
	// Behave differently depending on whether things are already rotated
	if (undoRecord->isRotated) {
		// If already rotated...
		layer = [contents layer:undoRecord->index];
		[layer setOffsets:IntMakePoint(undoRecord->rect.origin.x, undoRecord->rect.origin.y)];
		[layer setMarginLeft:0 top:0 right:undoRecord->rect.size.width - [layer width] bottom:undoRecord->rect.size.height - [layer height]];
		[[layer seaLayerUndo] restoreSnapshot:undoRecord->snapshot automatic:NO];
		if (undoRecord->withTrim) [[document selection] selectOpaque];
		else [[document selection] clearSelection];
		if (undoRecord->disableAlpha) [layer toggleAlpha];
		[[document helpers] layerBoundariesChanged:kActiveLayer];
        undoRecord->isRotated=NO;
	}
	else {
		// If not rotated...
		layer = [contents layer:undoRecord->index];
		[layer setRotation:undoRecord->rotation interpolation:NSImageInterpolationHigh withTrim:undoRecord->withTrim];
		if (undoRecord->withTrim) [[document selection] selectOpaque];
		else [[document selection] clearSelection];
		[[document helpers] layerBoundariesChanged:kActiveLayer];
		undoRecord->isRotated = YES;
	}
}


@end

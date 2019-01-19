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

@implementation SeaRotation

- (id)init
{
	undoMax = kNumberOfRotationRecordsPerMalloc;
	undoRecords = malloc(undoMax * sizeof(RotationUndoRecord));
	undoCount = 0;
	
	return self;
}

- (void)dealloc
{
	free(undoRecords);
}

- (void)run
{
	id contents = [document contents];
	id layer = NULL;

	// Fill out the selection label
	layer = [contents layer:[contents activeLayerIndex]];
	if ([layer floating])
		[selectionLabel setStringValue:LOCALSTR(@"floating", @"Floating Selection")];
	else
		[selectionLabel setStringValue:[NSString stringWithFormat:@"%@", [layer name]]];
	
	// Set the initial values
	[rotateValue setStringValue:@"0"];

	// Show the sheet
	[NSApp beginSheet:sheet modalForWindow:[document window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)apply:(id)sender
{
	id contents = [document contents];
	id layer = NULL;
	
	// End the sheet
	[NSApp stopModal];
	[NSApp endSheet:sheet];
	[sheet orderOut:self];

	// Rotate the image
	if ([rotateValue floatValue] != 0) {
		layer = [contents layer:[contents activeLayerIndex]];
		[self rotate:[rotateValue floatValue] withTrim:[layer floating]];
	}
}

- (IBAction)cancel:(id)sender
{
	// End the sheet
	[NSApp stopModal];
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
	RotationUndoRecord undoRecord;
	
	// Only rotate
	if (degrees > 0) degrees = 360 - mod_float(degrees, 360);
	else degrees = mod_float(degrees, 360);
	if (degrees == 0.0)
		return;

	// Record the undo details
	undoRecord.index =  [contents activeLayerIndex];
	undoRecord.rotation = degrees;
	undoRecord.undoIndex = [[activeLayer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, [(SeaLayer *)activeLayer width], [(SeaLayer *)activeLayer height]) automatic:NO];
	undoRecord.rect = IntMakeRect([activeLayer xoff], [activeLayer yoff], [(SeaLayer *)activeLayer width], [(SeaLayer *)activeLayer height]);
	undoRecord.isRotated = YES;
	undoRecord.withTrim = trim;
	[[[document undoManager] prepareWithInvocationTarget:self] undoRotation:undoCount];
	[activeLayer setRotation:degrees interpolation:NSImageInterpolationHigh withTrim:trim];
	if ([activeLayer floating] && trim) [[document selection] selectOpaque];
	else [[document selection] clearSelection];
	if (!trim && ![activeLayer hasAlpha]) {
		undoRecord.disableAlpha = YES;
		[activeLayer toggleAlpha];
	}
	else {
		undoRecord.disableAlpha = NO;
	}
	[[document helpers] layerBoundariesChanged:kActiveLayer];

	// Allow the undo
	if (undoCount + 1 > undoMax) {
		undoMax += kNumberOfRotationRecordsPerMalloc;
		undoRecords = realloc(undoRecords, undoMax * sizeof(RotationUndoRecord));
	}
	undoRecords[undoCount] = undoRecord;
	undoCount++;
}

- (void)undoRotation:(int)undoIndex
{
	id contents = [document contents];
	RotationUndoRecord undoRecord;
	id layer;
	
	// Prepare for redo
	[[[document undoManager] prepareWithInvocationTarget:self] undoRotation:undoIndex];
	
	// Get the undo record
	undoRecord = undoRecords[undoIndex];
	
	// Behave differently depending on whether things are already rotated
	if (undoRecord.isRotated) {
	
		// If already rotated...
		layer = [contents layer:undoRecord.index];
		[layer setOffsets:IntMakePoint(undoRecord.rect.origin.x, undoRecord.rect.origin.y)];
		[layer setMarginLeft:0 top:0 right:undoRecord.rect.size.width - [(SeaLayer *)layer width] bottom:undoRecord.rect.size.height - [(SeaLayer *)layer height]];
		[[layer seaLayerUndo] restoreSnapshot:undoRecord.undoIndex automatic:NO];
		if (undoRecord.withTrim) [[document selection] selectOpaque];
		else [[document selection] clearSelection];
		if (undoRecord.disableAlpha) [layer toggleAlpha];
		[[document helpers] layerBoundariesChanged:kActiveLayer];
		undoRecords[undoIndex].isRotated = NO;
		
	}
	else {
	
		// If not rotated...
		layer = [contents layer:undoRecord.index];
		[layer setRotation:undoRecord.rotation interpolation:NSImageInterpolationHigh withTrim:undoRecord.withTrim];
		if (undoRecord.withTrim) [[document selection] selectOpaque];
		else [[document selection] clearSelection];
		[[document helpers] layerBoundariesChanged:kActiveLayer];
		undoRecords[undoIndex].isRotated = YES;
		
	}
}


@end

#import "SeaAlignment.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaHelpers.h"

@implementation SeaAlignment

- (IBAction)alignLeft:(id)sender
{
	id contents = [document contents];
	id layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	// Get the required offset
	offset = [layer xoff];
	
	// Make the changes
	layerCount = [contents layerCount];
	for (i = 0; i < layerCount; i++) {
		layer = [contents layer:i];
		if ([layer linked]) {
			oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
			[[[document undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
			[layer setOffsets:IntMakePoint(offset, oldOffsets.y)];
			[[document helpers] layerOffsetsChanged:i from:oldOffsets];
		}
	}
}

- (IBAction)alignRight:(id)sender
{
	id contents = [document contents];
	id layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	// Get the required offset
	offset = [layer xoff] + [(SeaLayer *)layer width];
	
	// Make the changes
	layerCount = [contents layerCount];
	for (i = 0; i < layerCount; i++) {
		layer = [contents layer:i];
		if ([layer linked]) {
			oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
			[[[document undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
			[layer setOffsets:IntMakePoint(offset - [(SeaLayer *)layer width], oldOffsets.y)];
			[[document helpers] layerOffsetsChanged:i from:oldOffsets];
		}
	}
}

- (IBAction)alignHorizontalCenters:(id)sender
{
	id contents = [document contents];
	id layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	// Get the required offset
	offset = [layer xoff] + [(SeaLayer *)layer width] / 2;
	
	// Make the changes
	layerCount = [contents layerCount];
	for (i = 0; i < layerCount; i++) {
		layer = [contents layer:i];
		if ([layer linked]) {
			oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
			[[[document undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
			[layer setOffsets:IntMakePoint(offset - [(SeaLayer *)layer width] / 2, oldOffsets.y)];
			[[document helpers] layerOffsetsChanged:i from:oldOffsets];
		}
	}

}

- (IBAction)alignTop:(id)sender
{
	id contents = [document contents];
	id layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	// Get the required offset
	offset = [layer yoff];
	
	// Make the changes
	layerCount = [contents layerCount];
	for (i = 0; i < layerCount; i++) {
		layer = [contents layer:i];
		if ([layer linked]) {
			oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
			[[[document undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
			[layer setOffsets:IntMakePoint(oldOffsets.x, offset)];
			[[document helpers] layerOffsetsChanged:i from:oldOffsets];
		}
	}
}

- (IBAction)alignBottom:(id)sender
{
	id contents = [document contents];
	id layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	// Get the required offset
	offset = [layer yoff] + [(SeaLayer *)layer height];
	
	// Make the changes
	layerCount = [contents layerCount];
	for (i = 0; i < layerCount; i++) {
		layer = [contents layer:i];
		if ([layer linked]) {
			oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
			[[[document undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
			[layer setOffsets:IntMakePoint(oldOffsets.x, offset - [(SeaLayer *)layer height])];
			[[document helpers] layerOffsetsChanged:i from:oldOffsets];
		}
	}
}

- (IBAction)alignVerticalCenters:(id)sender
{
	id contents = [document contents];
	id layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	// Get the required offset
	offset = [layer yoff] + [(SeaLayer *)layer height] / 2;
	
	// Make the changes
	layerCount = [contents layerCount];
	for (i = 0; i < layerCount; i++) {
		layer = [contents layer:i];
		if ([layer linked]) {
			oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
			[[[document undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
			[layer setOffsets:IntMakePoint(oldOffsets.x, offset - [(SeaLayer *)layer height] / 2)];
			[[document helpers] layerOffsetsChanged:i from:oldOffsets];
		}
	}
}

- (void)centerLayerHorizontally:(id)sender
{
	id contents = [document contents];
	id layer = [contents activeLayer];
	IntPoint oldOffsets;
	int i, layerCount, shift;
	IntRect rect;
	
	// Check if layer is linked
	if (![layer linked]) {
		
		// Allow the undo
		oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
		[[[document undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:[contents activeLayerIndex]];
		
		// Make the change
		[layer setOffsets:IntMakePoint(([(SeaContent *)contents width] - [(SeaLayer *)layer width]) / 2, oldOffsets.y)];
		
		// Do the update
		[[document helpers] layerOffsetsChanged:[contents activeLayerIndex] from:oldOffsets];
	
	}
	else {
	
		// Start with an initial bounding rectangle
		rect.origin.x = [layer xoff];
		rect.origin.y = [layer yoff];
		rect.size.width = [(SeaLayer *)layer width];
		rect.size.height = [(SeaLayer *)layer height];
		
		// Determine the bounding rectangle
		layerCount = [contents layerCount];
		for (i = 0; i < layerCount; i++) {
			layer = [contents layer:i];
			if ([layer linked]) {
				rect.origin.x = MIN([layer xoff], rect.origin.x);
				rect.origin.y = MIN([layer yoff], rect.origin.y);
				rect.size.width = MAX([layer xoff] + [(SeaLayer *)layer width] - rect.origin.x, rect.size.width);
				rect.size.height = MAX([layer yoff] + [(SeaLayer *)layer height] - rect.origin.y, rect.size.height); 
			}
		}
		
		// Calculate the required shift
		shift = ([(SeaContent *)contents width] / 2 - rect.size.width / 2) - rect.origin.x;
		
		// Make the changes
		layerCount = [contents layerCount];
		for (i = 0; i < layerCount; i++) {
			layer = [contents layer:i];
			if ([layer linked]) {
				oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
				[[[document undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
				[layer setOffsets:IntMakePoint(oldOffsets.x + shift, oldOffsets.y)];
				[[document helpers] layerOffsetsChanged:i from:oldOffsets];
			}
		}
		
	}
}

- (void)centerLayerVertically:(id)sender
{
	id contents = [document contents];
	id layer = [contents activeLayer];
	IntPoint oldOffsets;
	int i, layerCount, shift;
	IntRect rect;
	
	// Check if layer is linked
	if (![layer linked]) {
	
		// Allow the undo
		oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
		[[[document undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:[contents activeLayerIndex]];
		
		// Make the change
		[layer setOffsets:IntMakePoint(oldOffsets.x, ([(SeaContent *)contents height] - [(SeaLayer *)layer height]) / 2)];
		
		// Do the update
		[[document helpers] layerOffsetsChanged:[contents activeLayerIndex] from:oldOffsets];
		
	}
	else {
	
		// Start with an initial bounding rectangle
		rect.origin.x = [layer xoff];
		rect.origin.y = [layer yoff];
		rect.size.width = [(SeaLayer *)layer width];
		rect.size.height = [(SeaLayer *)layer height];
		
		// Determine the bounding rectangle
		layerCount = [contents layerCount];
		for (i = 0; i < layerCount; i++) {
			layer = [contents layer:i];
			if ([layer linked]) {
				rect.origin.x = MIN([layer xoff], rect.origin.x);
				rect.origin.y = MIN([layer yoff], rect.origin.y);
				rect.size.width = MAX([layer xoff] + [(SeaLayer *)layer width] - rect.origin.x, rect.size.width);
				rect.size.height = MAX([layer yoff] + [(SeaLayer *)layer height] - rect.origin.y, rect.size.height); 
			}
		}
		
		// Calculate the required shift
		shift = ([(SeaContent *)contents height] / 2 - rect.size.height / 2) - rect.origin.y;
		
		// Make the changes
		layerCount = [contents layerCount];
		for (i = 0; i < layerCount; i++) {
			layer = [contents layer:i];
			if ([layer linked]) {
				oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
				[[[document undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
				[layer setOffsets:IntMakePoint(oldOffsets.x, oldOffsets.y + shift)];
				[[document helpers] layerOffsetsChanged:i from:oldOffsets];
			}
		}
		
	}
}

- (void)undoOffsets:(IntPoint)offsets layer:(int)index
{
	id contents = [document contents];
	id layer = [contents layer:index];
	IntPoint oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
	
	// Allow the redo
	[[[document undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:index];
	
	// Make the change
	[layer setOffsets:offsets];
	
	// Do the update
	[[document helpers] layerOffsetsChanged:index from:oldOffsets];
}

@end

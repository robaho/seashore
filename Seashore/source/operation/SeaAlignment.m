#import "SeaAlignment.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaHelpers.h"

@implementation SeaAlignment

- (IBAction)alignLeft:(id)sender
{
    [[document helpers] endLineDrawing];

	SeaContent *contents = [document contents];
	SeaLayer *layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	offset = [layer xoff];
	
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
    [[document helpers] endLineDrawing];

	SeaContent *contents = [document contents];
	SeaLayer *layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	offset = [layer xoff] + [layer width];
	
	layerCount = [contents layerCount];
	for (i = 0; i < layerCount; i++) {
		layer = [contents layer:i];
		if ([layer linked]) {
			oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
			[[[document undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
			[layer setOffsets:IntMakePoint(offset - [layer width], oldOffsets.y)];
			[[document helpers] layerOffsetsChanged:i from:oldOffsets];
		}
	}
}

- (IBAction)alignHorizontalCenters:(id)sender
{
    [[document helpers] endLineDrawing];

	SeaContent *contents = [document contents];
	SeaLayer *layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	offset = [layer xoff] + [layer width] / 2;
	
	layerCount = [contents layerCount];
	for (i = 0; i < layerCount; i++) {
		layer = [contents layer:i];
		if ([layer linked]) {
			oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
			[[[document undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
			[layer setOffsets:IntMakePoint(offset - [layer width] / 2, oldOffsets.y)];
			[[document helpers] layerOffsetsChanged:i from:oldOffsets];
		}
	}

}

- (IBAction)alignTop:(id)sender
{
    [[document helpers] endLineDrawing];

    SeaContent *contents = [document contents];
	SeaLayer *layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	offset = [layer yoff];
	
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
    [[document helpers] endLineDrawing];

    SeaContent *contents = [document contents];
	SeaLayer *layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	offset = [layer yoff] + [(SeaLayer *)layer height];
	
	layerCount = [contents layerCount];
	for (i = 0; i < layerCount; i++) {
		layer = [contents layer:i];
		if ([layer linked]) {
			oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
			[[[document undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
			[layer setOffsets:IntMakePoint(oldOffsets.x, offset - [layer height])];
			[[document helpers] layerOffsetsChanged:i from:oldOffsets];
		}
	}
}

- (IBAction)alignVerticalCenters:(id)sender
{
    [[document helpers] endLineDrawing];

	SeaContent *contents = [document contents];
	SeaLayer *layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	offset = [layer yoff] + [(SeaLayer *)layer height] / 2;
	
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
    [[document helpers] endLineDrawing];

	SeaContent *contents = [document contents];
	SeaLayer *layer = [contents activeLayer];
	IntPoint oldOffsets;
	int i, layerCount, shift;
	IntRect rect;
	
	if (![layer linked]) {
		
		oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
		[[[document undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:[contents activeLayerIndex]];
		
		[layer setOffsets:IntMakePoint(([contents width] - [layer width]) / 2, oldOffsets.y)];
		
		[[document helpers] layerOffsetsChanged:[contents activeLayerIndex] from:oldOffsets];
	
	}
	else {
        rect = [layer globalRect];
	
		// Determine the bounding rectangle
		layerCount = [contents layerCount];
		for (i = 0; i < layerCount; i++) {
			layer = [contents layer:i];
			if ([layer linked]) {
                rect = IntSumRects(rect,[layer globalRect]);
			}
		}
		
		shift = ([contents width] / 2 - rect.size.width / 2) - rect.origin.x;
		
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
    [[document helpers] endLineDrawing];

	SeaContent *contents = [document contents];
	SeaLayer *layer = [contents activeLayer];
	IntPoint oldOffsets;
	int i, layerCount, shift;
	IntRect rect;
	
	if (![layer linked]) {
	
		oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
		[[[document undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:[contents activeLayerIndex]];
		
		[layer setOffsets:IntMakePoint(oldOffsets.x, ([contents height] - [layer height]) / 2)];
		
		[[document helpers] layerOffsetsChanged:[contents activeLayerIndex] from:oldOffsets];
		
	}
	else {

        rect = [layer globalRect];

		// Determine the bounding rectangle
		layerCount = [contents layerCount];
		for (i = 0; i < layerCount; i++) {
			layer = [contents layer:i];
			if ([layer linked]) {
                rect = IntSumRects(rect,[layer globalRect]);
			}
		}
		
		shift = ([contents height] / 2 - rect.size.height / 2) - rect.origin.y;
		
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
	
	[[[document undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:index];
	[layer setOffsets:offsets];
	[[document helpers] layerOffsetsChanged:index from:oldOffsets];
}

@end

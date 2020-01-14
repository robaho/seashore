#import "SeaHelpers.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaController.h"
#import "ToolboxUtility.h"
#import "PegasusUtility.h"
#import "SeaWhiteboard.h"
#import "SeaPrefs.h"
#import "SeaView.h"
#import "SeaSelection.h"
#import "SeaTools.h"
#import "StatusUtility.h"
#import "LayerDataSource.h"

@implementation SeaHelpers

- (void)selectionChanged
{
	[[document docView] setNeedsDisplay:YES]; 
	[[document infoUtility] update];
}

- (void)selectionChanged:(IntRect)rect
{
    SeaLayer *layer = [[document contents] activeLayer];
    [[document docView] setNeedsDisplayInDocumentRect:IntOffsetRect(rect,[layer xoff],[layer yoff])];
    [[document infoUtility] update];
}

- (void)endLineDrawing
{
	id curTool = [document currentTool];

	// We only need to act if the document is locked
	if ([document locked] && [[document window] attachedSheet] == NULL) {
		
		// Apply the changes
		[[document whiteboard] applyOverlay];
		
		// Notify ourselves of the change
		[self layerContentsChanged:kActiveLayer];
		
		// End line drawing once
		if ([curTool respondsToSelector:@selector(endLineDrawing)])
			[curTool endLineDrawing];		
		
		// End line drawing twice
		[[document docView] endLineDrawing];
		
		// Unlock the document
		[document unlock];
		
	}
	
	// Special case for the effect tool
	if ([[document toolboxUtility] tool] == kEffectTool) {
		[curTool reset];
	}
}

- (void)channelChanged
{
	if ([[document contents] spp] != 2)
		[[document toolboxUtility] update:NO];
	[[document whiteboard] readjustAltData:YES];
	[[document statusUtility] update];
}

- (void)resolutionChanged
{
	[[document docView] readjust:YES];
	[[document statusUtility] update];
}

- (void)zoomChanged
{
	[[document optionsUtility] update];
	[[document statusUtility] update];
}

- (void)boundariesAndContentChanged:(BOOL)scaling
{
	id contents = [document contents];
	int i;
	
	[[document whiteboard] readjust];
	[[document docView] readjust:scaling];
	for (i = 0; i < [contents layerCount]; i++) {
		[[contents layer:i] updateThumbnail];
	}
	[[document pegasusUtility] update:kPegasusUpdateLayerView];
	[[document statusUtility] update];
	[[document docView] setNeedsDisplay:YES]; 

}

- (void)activeLayerWillChange
{
	[self endLineDrawing];
}

- (void)activeLayerChanged:(int)eventType
{
	id whiteboard = [document whiteboard];
	id docView = [document docView];
	
	[[document selection] readjustSelection];
    
	if (![[[document contents] activeLayer] hasAlpha] && [[document contents] selectedChannel] == kAlphaChannel) {
		[[document contents] setSelectedChannel:kAllChannels];
		[[document helpers] channelChanged];
	}
    
	switch (eventType) {
		case kLayerSwitched:
		case kLayerAdded:
		case kLayerDeleted:
			[whiteboard readjustLayer];
		break;
	}
    
    [document maybeShowLayerWarning];

	[(LayerDataSource *)[document dataSource] update];
	[[document pegasusUtility] update:kPegasusUpdateAll];
    
    // Show the banner
    if([[[document contents] activeLayer] floating]) {
        [[document warnings] showFloatBanner];
    } else {
        [[document warnings] hideFloatBanner];
    }
}

- (void)documentWillFlatten
{
	[self activeLayerWillChange];
}

- (void)documentFlattened
{
	[self activeLayerChanged:kLayerAdded];
}

- (void)typeChanged
{
	[[document toolboxUtility] update:NO];
	[[document whiteboard] readjust];
	[self layerContentsChanged:kAllLayers];
	[[document statusUtility] update];
}

- (void)applyOverlay
{
	IntRect rect = [[document whiteboard] applyOverlay];
	SeaLayer *layer = [[document contents] activeLayer];
	[layer updateThumbnail];
	[[document whiteboard] update:rect];
	[[document pegasusUtility] update:kPegasusUpdateLayerView];
}

- (void)overlayChanged:(IntRect)rect
{
	id contents = [document contents];
	
	rect.origin.x += [[contents activeLayer] xoff];
	rect.origin.y += [[contents activeLayer] yoff];
	[[document whiteboard] update:rect];
}

- (void)layerAttributesChanged:(int)index hold:(BOOL)hold
{
	id contents = [document contents], layer;
	IntRect rect;
	
	if (index == kActiveLayer)
		index = [contents activeLayerIndex];
	
	switch (index) {
		case kAllLayers:
		case kLinkedLayers:
			[[document whiteboard] update];
		break;
		default:
			layer = [contents layer:index];
			rect = IntMakeRect([layer xoff], [layer yoff], [(SeaLayer *)layer width], [(SeaLayer *)layer height]);
			[[document whiteboard] update:rect];
		break;
	}
	
	if (!hold)
		[[document pegasusUtility] update:kPegasusUpdateAll];
}

- (void)layerBoundariesChanged:(int)index
{
	id contents = [document contents], layer;
	IntRect rect;
	int i;
	
	if (index == kActiveLayer)
		index = [contents activeLayerIndex];
	
	switch (index) {
		case kAllLayers:
			for (i = 0; i < [contents layerCount]; i++) {
				[[contents layer:i] updateThumbnail];
			}
		break;
		case kLinkedLayers:
			for (i = 0; i < [contents layerCount]; i++) {
				if ([[contents layer:i] linked])
					[[contents layer:i] updateThumbnail];
			}
		break;
		default:
			layer = [contents layer:index];
			rect = IntMakeRect([layer xoff], [layer yoff], [(SeaLayer *)layer width], [(SeaLayer *)layer height]);
			[layer updateThumbnail];
		break;
	}
	
	[[document selection] readjustSelection];
	[[document whiteboard] readjustLayer];
	[[document pegasusUtility] update:kPegasusUpdateAll];
	[[document docView] setNeedsDisplay:YES]; 

}

- (void)layerContentsChanged:(int)index
{
	id contents = [document contents], layer;
	IntRect rect;
	int i;
	
	if (index == kActiveLayer)
		index = [contents activeLayerIndex];
	
	switch (index) {
		case kAllLayers:
			for (i = 0; i < [contents layerCount]; i++) {
				[[contents layer:i] updateThumbnail];
			}
			[[document whiteboard] update];
		break;
		case kLinkedLayers:
			for (i = 0; i < [contents layerCount]; i++) {
				if ([[contents layer:i] linked])
					[[contents layer:i] updateThumbnail];
			}
			[[document whiteboard] update];
		break;
		default:
			layer = [contents layer:index];
			rect = IntMakeRect([layer xoff], [layer yoff], [(SeaLayer *)layer width], [(SeaLayer *)layer height]);
			[layer updateThumbnail];
			[(SeaWhiteboard *)[document whiteboard] update:rect];
		break;
	}
	
	[[document pegasusUtility] update:kPegasusUpdateLayerView];
}

- (void)layerOffsetsChanged:(int)index from:(IntPoint)oldOffsets
{
    id contents = [document contents];
    SeaLayer *layer;
    int xoff, yoff;

	if (index == kActiveLayer)
		index = [contents activeLayerIndex];
	
	switch (index) {
		case kAllLayers:
            [[document whiteboard] update];
            layer = [contents activeLayer];
            xoff = [layer xoff];
            yoff = [layer yoff];
        break;
		case kLinkedLayers:
			[[document whiteboard] update];
			layer = [contents activeLayer];
			xoff = [layer xoff];
			yoff = [layer yoff];
		break;
		default:
			layer = [contents layer:index];
            xoff = [layer xoff];
            yoff = [layer yoff];
            IntRect oldRect = IntMakeRect(oldOffsets.x,oldOffsets.y,[layer width],[layer height]);
            [[document whiteboard] update:IntSumRects(oldRect,[layer localRect])];
		break;
	}
	
	if ([[document selection] active]) {
		[[document selection] adjustOffset:IntMakePoint(xoff - oldOffsets.x, yoff - oldOffsets.y)];
	}
}

- (void)layerOffsetsChanged:(IntPoint)oldOffsets rect:(IntRect)dirty
{
    SeaLayer *layer = [[document contents] activeLayer];
    IntPoint newOffsets = [layer localRect].origin;
    [[document whiteboard] update:dirty];
    
    if ([[document selection] active]) {
        [[document selection] adjustOffset:IntMakePoint(newOffsets.x - oldOffsets.x, newOffsets.y - oldOffsets.y)];
    }
}


- (void)layerLevelChanged:(int)index
{
    id contents = [document contents];
    SeaLayer *layer;
	
	if (index == kActiveLayer)
		index = [contents activeLayerIndex];
	
	switch (index) {
		case kAllLayers:
		case kLinkedLayers:
			[[document whiteboard] update];
		break;
		default:
			layer = [contents layer:index];
			[[document whiteboard] update:[layer localRect]];
		break;
	}
	[(LayerDataSource *)[document dataSource] update];
	[[document pegasusUtility] update:kPegasusUpdateAll];
}

- (void)layerSnapshotRestored:(int)index rect:(IntRect)rect
{
	id layer;
	
	layer = [[document contents] layer:index];
	rect.origin.x += [layer xoff];
	rect.origin.y += [layer yoff];
	[(SeaWhiteboard *)[document whiteboard] update:rect];
	[layer updateThumbnail];
	[[document pegasusUtility] update:kPegasusUpdateLayerView];
}

- (void)layerTitleChanged
{
	[(LayerDataSource *)[document dataSource] update];
	[[document pegasusUtility] update:kPegasusUpdateLayerView];
}

@end

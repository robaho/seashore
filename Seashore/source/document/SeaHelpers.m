#import "SeaHelpers.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
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
	[[[SeaController utilitiesManager] infoUtilityFor:document] update];
}

- (void)endLineDrawing
{
	id curTool = [[document tools] currentTool];

	// We only need to act if the document is locked
	if ([document locked] && [[document window] attachedSheet] == NULL) {
		
		// Apply the changes
		[(SeaWhiteboard *)[document whiteboard] applyOverlay];
		
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
	if ([[[SeaController utilitiesManager] toolboxUtilityFor:document] tool] == kEffectTool) {
		[curTool reset];
	}
}

- (void)channelChanged
{
	if ([[document contents] spp] != 2)
		[(ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document] update:NO];
	[[document whiteboard] readjustAltData:YES];
	[(StatusUtility *)[[SeaController utilitiesManager] statusUtilityFor:document] update];
}

- (void)resolutionChanged
{
	[[document docView] readjust:YES];
	[[[SeaController utilitiesManager] statusUtilityFor:document] update];
}

- (void)zoomChanged
{
	[[[SeaController utilitiesManager] optionsUtilityFor:document] update];
	[[[SeaController utilitiesManager] statusUtilityFor:document] updateZoom];
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
	[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateLayerView];
	[(StatusUtility *)[[SeaController utilitiesManager] statusUtilityFor:document] update];
	[[document docView] setNeedsDisplay:YES]; 

}

- (void)activeLayerWillChange
{
	[self endLineDrawing];
}

- (void)activeLayerChanged:(int)eventType rect:(IntRect *)rect
{
	id whiteboard = [document whiteboard];
	id docView = [document docView];
	
	[[document selection] readjustSelection];
	if (![[[document contents] activeLayer] hasAlpha] && ![[document selection] floating] && [[document contents] selectedChannel] == kAlphaChannel) {
		[[document contents] setSelectedChannel:kAllChannels];
		[[document helpers] channelChanged];
	}
	switch (eventType) {
		case kLayerSwitched:
		case kTransparentLayerAdded:
			[whiteboard readjustLayer];
			if ([whiteboard whiteboardIsLayerSpecific]) {
				[whiteboard readjustAltData:YES];
			}
			else if ([[SeaController seaPrefs] layerBounds]) {
				[docView setNeedsDisplay:YES];
			}
		break;
		case kLayerAdded:
		case kLayerDeleted:
			[whiteboard readjustLayer];
			[whiteboard readjustAltData:YES];
		break;
	}
	[(LayerDataSource *)[document dataSource] update];
	[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateAll];
}

- (void)documentWillFlatten
{
	[self activeLayerWillChange];
}

- (void)documentFlattened
{
	[self activeLayerChanged:kLayerAdded rect:NULL];
}

- (void)typeChanged
{
	[(ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document] update:NO];
	[[document whiteboard] readjust];
	[self layerContentsChanged:kAllLayers];
	[[[SeaController utilitiesManager] statusUtilityFor:document] update];
	[[[SeaController utilitiesManager] statusUtilityFor:document] updateQuickColor];
}

- (void)applyOverlay
{
	id contents = [document contents], layer;
	IntRect rect;
	
	rect = [(SeaWhiteboard *)[document whiteboard] applyOverlay];
	layer = [contents activeLayer];
	[layer updateThumbnail];
	[(SeaWhiteboard *)[document whiteboard] update:rect inThread:NO];
	[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateLayerView];
}

- (void)overlayChanged:(IntRect)rect inThread:(BOOL)thread
{
	id contents = [document contents];
	
	rect.origin.x += [[contents activeLayer] xoff];
	rect.origin.y += [[contents activeLayer] yoff];
	[(SeaWhiteboard *)[document whiteboard] update:rect inThread:thread];
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
			[(SeaWhiteboard *)[document whiteboard] update:rect inThread:NO];
		break;
	}
	
	if (!hold)
		[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateAll];
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
	[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateAll];
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
			[(SeaWhiteboard *)[document whiteboard] update:rect inThread:NO];
		break;
	}
	
	[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateLayerView];
}

- (void)layerOffsetsChanged:(int)index from:(IntPoint)oldOffsets
{
	id contents = [document contents], layer;
	IntRect rectA, rectB, rectC;
	int xoff, yoff;

	if (index == kActiveLayer)
		index = [contents activeLayerIndex];
	
	switch (index) {
		case kAllLayers:
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
			rectA.origin.x = MIN(xoff, oldOffsets.x);
			rectA.origin.y = MIN(yoff, oldOffsets.y);
			rectA.size.width = MAX(xoff, oldOffsets.x) - MIN(xoff, oldOffsets.x) + [(SeaLayer *)layer width];
			rectA.size.height = MAX(yoff, oldOffsets.y) - MIN(yoff, oldOffsets.y) + [(SeaLayer *)layer height];
			rectB = IntMakeRect(oldOffsets.x, oldOffsets.y, [(SeaLayer *)layer width], [(SeaLayer *)layer height]);
			rectC = IntMakeRect(xoff, yoff, [(SeaLayer *)layer width], [(SeaLayer *)layer height]);
			if (rectA.size.width * rectA.size.height < rectB.size.width * rectB.size.height + rectC.size.width * rectC.size.height) {
				[(SeaWhiteboard *)[document whiteboard] update:rectA inThread:NO];
			}
			else {
				[(SeaWhiteboard *)[document whiteboard] update:rectB inThread:NO];
				[(SeaWhiteboard *)[document whiteboard] update:rectC inThread:NO];
			}
		break;
	}
	
	if ([[document selection] active]) {
		[[document selection] adjustOffset:IntMakePoint(xoff - oldOffsets.x, yoff - oldOffsets.y)];
	}
}

- (void)layerLevelChanged:(int)index
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
			[(SeaWhiteboard *)[document whiteboard] update:rect inThread:NO];
		break;
	}
	[(LayerDataSource *)[document dataSource] update];
	[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateAll];
}

- (void)layerSnapshotRestored:(int)index rect:(IntRect)rect
{
	id layer;
	
	layer = [[document contents] layer:index];
	rect.origin.x += [layer xoff];
	rect.origin.y += [layer yoff];
	[(SeaWhiteboard *)[document whiteboard] update:rect inThread:NO];
	[layer updateThumbnail];
	[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateLayerView];
}

- (void)layerTitleChanged
{
	[(LayerDataSource *)[document dataSource] update];
	[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateLayerView];
}

@end

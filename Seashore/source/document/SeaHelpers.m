#import "SeaHelpers.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaController.h"
#import "ToolboxUtility.h"
#import "LayersUtility.h"
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
    [[document whiteboard] update];
	[[document docView] setNeedsDisplay:YES]; 
	[[document infoUtility] update];
    [[document histogram] update];
}

- (void)selectionChanged:(IntRect)documentRect
{
    [[document docView] setNeedsDisplayInDocumentRect:documentRect:16];
    [[document infoUtility] update];
    [[document histogram] update];
}

- (void)endLineDrawing
{
	id curTool = [document currentTool];

    [curTool endLineDrawing];

    // End line drawing twice
    [[document docView] endLineDrawing];
}

- (void)channelChanged
{
    [[document toolboxUtility] update:NO];
    [[document docView] setNeedsDisplay:YES];
	[[document statusUtility] update];
}

- (void)resolutionChanged
{
    [[document scrollView] updateRulers];
	[[document docView] readjust];
	[[document statusUtility] update];
}

- (void)zoomChanged
{
    [[document scrollView] updateRulers];
	[[document optionsUtility] update];
	[[document statusUtility] update];
    AbstractTool *tool = [[document tools] getTool:kZoomTool];
    [[tool getOptions] update:self];
}

- (void)boundariesAndContentChanged
{
	SeaContent *contents = [document contents];
	int i;
	
	[[document whiteboard] readjust];
	[[document docView] readjust];
	for (i = 0; i < [contents layerCount]; i++) {
		[[contents layer:i] updateThumbnail];
	}
	[[document layersUtility] update:kLayersUpdateCurrent];
	[[document statusUtility] update];
    [[document toolboxUtility] update:FALSE];
	[[document docView] setNeedsDisplay:YES];

}

- (void)activeLayerWillChange
{
	[self endLineDrawing];
}

- (void)activeLayerChanged:(int)eventType
{
	if (![[[document contents] activeLayer] hasAlpha] && [[document contents] selectedChannel] == kAlphaChannel) {
		[[document contents] setSelectedChannel:kAllChannels];
		[[document helpers] channelChanged];
	}
    
	switch (eventType) {
		case kLayerSwitched:
		case kLayerAdded:
		case kLayerDeleted:
			[[document whiteboard] readjustLayer];
		break;
	}
    
    [document maybeShowLayerWarning];

	[(LayerDataSource *)[document dataSource] update];
	[[document layersUtility] update:kLayersUpdateAll];
    [[document toolboxUtility] update:FALSE];
    [[document infoUtility] update];
    [[document statusUtility] update];
    [[document docView] setNeedsDisplay:TRUE];
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
	[self layerContentsChanged:kAllLayers];
    [[document whiteboard] readjust];
	[[document statusUtility] update];
}

- (void)applyOverlay
{
	[[document whiteboard] applyOverlay];
    [self layerContentsChanged:kActiveLayer];
}

- (void)overlayChanged:(IntRect)layerRect
{
    [[document whiteboard] overlayModified:layerRect];
}

- (void)layerAttributesChanged:(int)index hold:(BOOL)hold
{
    SeaContent *contents = [document contents];
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
			[[document whiteboard] update:[layer globalBounds]];
		break;
	}
	
	if (!hold)
		[[document layersUtility] update:kLayersUpdateAll];
    [[document toolboxUtility] update:FALSE];
}

- (void)layerBoundariesChanged:(int)index
{
    SeaContent *contents = [document contents];
    SeaLayer *layer;
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
			[layer updateThumbnail];
		break;
	}
	
	[[document whiteboard] readjustLayer];
	[[document layersUtility] update:kLayersUpdateAll];
	[[document docView] setNeedsDisplay:YES];
    [[document toolboxUtility] update:FALSE];
}

- (void)layerContentsChanged:(int)index
{
    SeaContent *contents = [document contents];
    SeaLayer *layer;
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
			[layer updateThumbnail];
		break;
	}
	
	[[document layersUtility] update:kLayersUpdateCurrent];
}

- (void)layerOffsetsChanged:(int)index from:(IntPoint)oldOffsets
{
    SeaContent *contents = [document contents];

    if (index == kActiveLayer) {
		index = [contents activeLayerIndex];
        if(index==-1) {
            return;
        }
    }
	
	switch (index) {
		case kAllLayers:
            [[document whiteboard] update];
        break;
		case kLinkedLayers:
			[[document whiteboard] update];
		break;
        default: {
			SeaLayer *layer = [contents layer:index];
            IntRect oldRect = IntMakeRect(oldOffsets.x,oldOffsets.y,[layer width],[layer height]);
            [[document whiteboard] update:IntSumRects(oldRect,[layer globalRect])];
        }
		break;
	}
}

- (void)layerOffsetsChanged:(IntRect)dirty
{
    [[document whiteboard] update:dirty];
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
			[[document whiteboard] update:[layer globalBounds]];
		break;
	}
	[(LayerDataSource *)[document dataSource] update];
	[[document layersUtility] update:kLayersUpdateAll];
}

- (void)layerSnapshotRestored:(int)index rect:(IntRect)rect
{
	id layer;
	
	layer = [[document contents] layer:index];
	rect.origin.x += [layer xoff];
	rect.origin.y += [layer yoff];
	[[document whiteboard] update:rect];
	[layer updateThumbnail];
	[[document layersUtility] update:kLayersUpdateCurrent];
}

- (void)layerTitleChanged
{
	[(LayerDataSource *)[document dataSource] update];
	[[document layersUtility] update:kLayersUpdateCurrent];
}

@end

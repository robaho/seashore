#import "Globals.h"

/*!
	@enum 		kLayer...
	@constant	kLayerSwitched
				Indicates that the user simply selected another layer.
	@constant	kTransparentLayerAdded
				Indicates that the user added another trasnparent layer.
	@constant	kLayerAdded
				Indicates that the user added another non-transparent layer.
	@constant	kLayerDeleted
				Indicates that the user deleted a layer.
*/
enum {
	kLayerSwitched,
	kTransparentLayerAdded,
	kLayerAdded,
	kLayerDeleted
};

/*!
	@class		SeaHelpers
	@abstract	Provides methods that handle all updating necessary for a
				particular change.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaHelpers : NSObject {
	
	// The document associated with this object
    IBOutlet id document;
	
}

/*!
	@method		selectionChanged
	@discussion	Called after a selection is made or cancelled.
*/
- (void)selectionChanged;

/*!
	@method		endLineDrawing
	@discussion	Ends the drawing of a line if required. Should be called before
				a tool or layer change.
*/
- (void)endLineDrawing;

/*!
	@method		channelChanged
	@discussion	Called after the document's selected channel is changed.
*/
- (void)channelChanged;

/*!
	@method		resolutionChanged
	@discussion	Called after the document's resolution is changed but not the
				document's contents.
*/
- (void)resolutionChanged;

/*!
	@method		zoomChanged
	@discussion	Called after the document window's zoom is changed.
*/
- (void)zoomChanged;

/*!
	@method		boundariesAndContentChanged:
	@discussion	Called after the document's boundaries and content are changed.
				After calling this there is no need to subsequently call
				layerContentsChanged:.
	@param		scaling
				YES if the change is due to scaling, NO otherwise.
*/
- (void)boundariesAndContentChanged:(BOOL)scaling;

/*!
	@method		activeLayerWillChange
	@discussion	Called before the document's active layer is changed.
*/
- (void)activeLayerWillChange;

/*!
	@method		activeLayerChanged:rect:
	@discussion	Called after the document's active layer is changed.
	@param		eventType
				The layer event type associated with the change (see  constants
				in the header).
	@param		rect
				The rectangle specifying the deleted layer's boundaries for
				kLayerDeleted events or the added layer's boundaries for
				kLayerAdded events or NULL. This is used to allow more effective
				updating.
*/
- (void)activeLayerChanged:(int)eventType rect:(IntRect *)rect;

/*!
	@method		documentWillFlatten
	@discussion	Called before the document is flattened or unflattened.
*/
- (void)documentWillFlatten;

/*!
	@method		documentFlattened
	@discussion	Called after the document is flattened or unflattened.
*/
- (void)documentFlattened;

/*!
	@method		typeChanged
	@discussion	Called after the document type is changed.
*/
- (void)typeChanged;

/*!
	@method		applyOverlay
	@discussion	Called to apply the overlay to the active layer (handles
				updating and undos).
*/
- (void)applyOverlay;

/*!
	@method		overlayChanged:
	@discussion	Called after the overlay is changed.
	@param		rect
				The rectangle containing the changed region in the overlay's
				co-ordinates.
	@param		thread
				YES if drawing should be done in thread, NO otherwise.
*/
- (void)overlayChanged:(IntRect)rect inThread:(BOOL)thread;

/*!
	@method		layerAttributesChanged:hold:
	@discussion	Called after a specifed layer's attributes have been changed.
				Attributes affect the compositing of the layer onto the image
				but not the contents of the layer.
	@param		index
				The index of the layer changed or kActiveLayer to indicate the
				active layer or kAllLayers to indicate all layers.
	@param		hold
				YES if the Pegasus utility should not be updated, NO otherwise.
*/
- (void)layerAttributesChanged:(int)index hold:(BOOL)hold;

/*!
	@method		layerBoundariesChanged:
	@discussion	Called after a specified layer's boundaries have been changed.
	@param		index
				The index of the layer changed or kActiveLayer to indicate the
				active layer or kAllLayers to indicate all layers.
*/
- (void)layerBoundariesChanged:(int)index;

/*!
	@method		layerContentsChanged:
	@discussion	Called after a specifed layer's contents has been changed.
	@param		index
				The index of the layer changed or kActiveLayer to indicate the
				active layer or kAllLayers to indicate all layers.
*/
- (void)layerContentsChanged:(int)index;

/*!
	@method		layerLevelChanged:
	@discussion	Called after a specified layer's level is changed.
	@param		index
				The index of the layer changed or kActiveLayer to indicate the
				active layer or kAllLayers to indicate all layers.
*/
- (void)layerLevelChanged:(int)index;

/*!
	@method		layerOffsetsChanged:from:
	@discussion	Called after a specified layer's offsets are changed.
	@param		index
				The index of the layer changed, kActiveLayer to indicate the
				active layer, kAllLayers to indicate all layers or kLinkedLayers
				to indicate all linked layers.
	@param		oldOffsets
				The old offsets of the layer. This parameter is ignored if index
				is kAllLayers or kLinkedLayers.
*/
- (void)layerOffsetsChanged:(int)index from:(IntPoint)oldOffsets;

/*!
	@method		layerSnapshotRestored:rect:
	@discussion	Called after a snapshot of a layer is restored.
	@param		index
				The index of the layer being restoed.
	@param		rect
				The rectangle in which the snapshot is being restored in the
				layer's co-ordinates.
*/
- (void)layerSnapshotRestored:(int)index rect:(IntRect)rect;

/*!
	@method		layerTitleChanged
	@discussion	Called after one or more of the layers have their titles
				changed.
*/
- (void)layerTitleChanged;

@end

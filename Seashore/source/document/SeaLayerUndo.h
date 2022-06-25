#import "Seashore.h"

/*!
	@class		SeaLayerUndo
	@abstract	Makes changes to the associated layer's pixels undoable.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface LayerSnapshot : NSObject
{
@public
    IntRect rect;
    unsigned char *data;
}
@end

@class SeaDocument;
@class SeaLayer;

@interface SeaLayerUndo : NSObject {
	
	// The document associated with this oject
	__weak SeaDocument *document;
	
	// The layer associated with this oject
	__weak SeaLayer *layer;
}

/*!
	@method		initWithDocument:forLayer:
	@discussion	Initializes an instance of this class for use by the given layer
				of the given document.
	@param		doc
				The document with which to initialize the instance.
	@param		ilayer
				The layer with which to initialize the instance.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithDocument:(id)doc forLayer:(id)ilayer;

- (LayerSnapshot*)takeSnapshot:(IntRect)rect automatic:(BOOL)automatic;

- (void)restoreSnapshot:(LayerSnapshot*)snapshot automatic:(BOOL)automatic;

@end

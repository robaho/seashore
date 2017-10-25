#import "Globals.h"
#import "StandardMerge.h"
#import "AltiVecMerge.h"
#import "SeaCompositor.h"

/*!
	@class		SeaCompositorAV
	@abstract	Handles layer compositing for SeaWhitebaord.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaCompositorAV : NSObject {

	// The document associated with this compositor
	id document;
	
	// The random table
	int randomTable[RANDOM_TABLE_SIZE];
	
}

/*!
	@method		initWithDocument:
	@discussion	Initializes an instance of this class with the given document.
	@param		doc
				The document with which to initialize the instance.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithDocument:(id)doc;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		compositeLayer:withOptions:
	@discussion	Composites a layer on to the document's whiteboard using the
				specified options.
	@param		layer
				The layer to composite.
	@param		options
				The options for compositing.
*/
- (void)compositeLayer:(id)layer withOptions:(CompositorOptions)options;

/*!
	@method		compositeLayer:withOptions:andData:
	@discussion	Composites a layer on to the document's whiteboard using the
				specified options.
	@param		layer
				The layer to composite.
	@param		options
				The options for compositing.
	@param		andData
				A pointer to the data the layer should be composited onto.
*/
- (void)compositeLayer:(id)layer withOptions:(CompositorOptions)options andData: (unsigned char *) destPtr;

/*!
	@method		compositeLayer:withFloat:withOptions:
	@discussion	Composites a layer on to the document's whiteboard using the
				specified options with the specified floating layer.
	@param		layer
				The layer to composite.
	@param		floatingLayer
				The floating layer.
	@param		options
				The options for compositing.
*/
- (void)compositeLayer:(id)layer withFloat:(id)floatingLayer andOptions:(CompositorOptions)options;

@end

#import "Seashore.h"
#import <AppKit/AppKit.h>

/*!
	@enum		k...Mode
	@constant	kDefaultMode
				Default selection.
	@constant	kAddMode
				Add to the selection.
	@constant	kSubtractMode
				Subtract from the selection.
	@constant	kMultiplyMode
				Multiply the selections.
	@constant	kSubtractProductMode
				Subtract the product of the selections.
	@constant	kForceNewMode
				For a new selection
*/
enum {
	kDefaultMode,
	kAddMode,
	kSubtractMode,
	kMultiplyMode,
	kSubtractProductMode,
	kForceNewMode
};

/*!
	@class	SeaSelection
	@abstract	Manages user selections.
*/

@interface SeaSelection : NSObject {

	// The document associated with this object
	__weak id document;

	// The current selection rectangle in document coordinates
	IntRect maskRect;
	// The current selection bitmap and mask - the size is the size of the maskRect
	unsigned char *mask;
	
	// Used to determine if the selection is active
	BOOL active;
	
	// Help present the user with a visual representation of the mask
	int selectionColorIndex;
    float lastScale;

    CGImageRef maskImage;
    CGPathRef maskPath;
    
	// The point of the last copied selection and its size
	IntPoint sel_point;
	IntSize sel_size;
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
	@method		active
	@discussion	Returns whether the current selection is active or not.
	@result		Returns YES if the selection is active, NO otherwise.
*/
- (BOOL)active;

/*!
	@method		mask
	@discussion	Returns a mask indicating the opacity of the selection, if NULL
				is returned the selection rectangle should be assumed to be
				entirely opaque.
	@result		Returns a reference to an 8-bit single-channel bitmap or NULL.
*/
- (unsigned char *)mask;

/*!
	@method		maskImage
	@discussion	Returns an image of the mask in the current selection colour.
				This is used so the selection can be represented to users.
*/
- (CGImageRef)maskImage;

/*!
 @method        maskPath
 @discussion    Returns the path of the outline of the selection mask.
 */
- (CGPathRef)maskPath;

/*!
	@method		maskRect
	@discussion	Returns the unclipped document rect mask.
*/
- (IntRect)maskRect;

/*!
 @method        inSelection
 @discussion    Returns true if no selection, or the point is valid in the mask
 */
- (BOOL)inSelection:(IntPoint)p;

/*!
 @method        globalRect
 @discussion    Returns a rectangle enclosing the current mask clipped to the current layer in document coords
 @result        Returns an IntRect reprensenting the rectangle that encloses the
 current selection in the document's co-ordinates.
 */
- (IntRect)globalRect;

/*!
	@method		localRect
	@discussion	Returns a rectangle enclosing the current msk clipped to the current layer
	@result		Returns an IntRect reprensenting the rectangle that encloses the
				current selection in the overlay's co-ordinates.
*/
- (IntRect)localRect;

/*!
     @method localOffset
     @return the offset into 'mask' that represents the upper left in the selection localRect
 */
- (int)localOffset;

/*!
	@method		selectRect:
	@discussion Selects the given rectangle in the document (handles updates and
				undos).
	@param		selectionRect
				The rectangle to select in the overlay's co-ordinates.
	@param		mode
				The mode of the selection (see above).
*/
- (void)selectRect:(IntRect)selectionRect mode:(int)mode;

/*!
	@method		selectEllipse:intermediate:
	@discussion Selects the given ellipse in the document.
	@param		selectionRect
				The rectangle containing the ellipse to select in the overlay's
				co-ordinates.
	@param		mode
				The mode of the selection (see above).
*/
- (void)selectEllipse:(IntRect)selectionRect mode:(int)mode;

/*!
	@method		selectRoundedRect:intermediate:
	@discussion Selects the given rounded rectangle in the document.
	@param		selectionRect
				The rectangle containing the rounded rectangle to select in the
				overlay's co-ordinates.
	@param		radius
				An integer indicating the rounded rectangle's curve radius.
	@param		mode
				The mode of the selection (see above).
*/
- (void)selectRoundedRect:(IntRect)selectionRect radius:(int)radius mode:(int)mode;

/*!
	@method		selectOverlay:inRect:mode:
	@discussion Selects the area given by the overlay's alpha channel.
	@param		rect
				The rectangle contianing the section of the overlay to be
				considered for selection.
	@param		mode
				The mode of the selection (see above).
*/
- (void)selectOverlay:(IntRect)selectionRect mode:(int)mode;

- (void)selectPath:(NSBezierPath*)path mode:(int)mode;

/*!
	@method		selectOpaque
	@discussion	Selects the opaque parts of the active layer.
*/
- (void)selectOpaque;

/*!
	@method		moveSelection:
	@discussion	This moves the selection (but not the selection's contents) to the
				new origin.
	@param		newOrigin
				The new origin.
*/
- (void)moveSelection:(IntPoint)newOrigin fromOrigin:(IntPoint)oldOrigin;

/*!
	@method		clearSelection
	@discussion	Makes the current selection void (don't confuse this with
				deleteSelection).
*/
- (void)clearSelection;

/*!
	@method		flipSelection:
	@discussion	Flips the current selection's mask in the desired manner (does
				not affect content).
	@param		type
				The type of flip (see SeaFlip).
*/
- (void)flipSelection:(int)type;

/*!
	@method		invertSelection
	@discussion	Inverts the current selection (i.e. selects everything in the
				layer that is not selected or nothing if everything is
				selected).
*/
- (void)invertSelection;

/*!
	@method		selectionData
	@discussion	Returns a block of memory containing the layer data encapsulated
				by the rectangle.
	@result		Returns a pointer to a block of memory containing the layer data
				encapsulated by the rectangle.
*/
- (unsigned char *)selectionData;

/*!
	@method		selectionSizeMatch:
	@discussion	Compares the given size to the size of the last selection.
	@param		inp_size
				The size for comparison.
	@result		Returns YES if the size is equal to the size of the last selection,
				NO otherwise.
*/
- (BOOL)selectionSizeMatch:(IntSize)inp_size;

/*!
	@method		selectionPoint
	@discussion	Returns the point from which the last selection was copied.
	@result		Returns an IntPoint indicating the point from which the last
				selection was copied.
*/
- (IntPoint)selectionPoint;

/*!
	@method		cutSelection
	@discussion	Calls copySelection followed by deleteSelection.
*/
- (void)cutSelection;

/*!
	@method		copySelection
	@discussion	Copies the current selection to the clipboard.
*/
- (void)copySelection;

/*!
	@method		deleteSelection
	@discussion	Deletes the contents of the current selection from the active
				layer (don't confuse this with clearSelection).
*/
- (void)deleteSelection;

/*!
	@method		adjustOffset:
	@discussion	Adjusts the offset of the selection rectangle.
	@param		offset
				An IntPoint representing the adjustment in the offset of the
				selection rectangle.
*/
- (void)adjustOffset:(IntPoint)offset;

/*!
	@method		scaleSelectionHorizontally:vertically:
	@discussion	Scales the current selection.
	@param		xScale
				The scaling to be done horizontally on the selection.
	@param		yScale
				The scaling to be done vertically on the selection.
*/
- (void)scaleSelectionHorizontally:(float)xScale vertically:(float)yScale;

/*!
	@method		scaleSelectionTo:from:interpolation:usingMask:
	@discussion	Scales the current selection.
	@param		newRect
				The rectangle of the new selection.
	@param		oldRect
				The rectangle of the old selection.
	@param		oldMask
				The mask that should be scaled to the newRect.
*/
- (void)scaleSelectionTo:(IntRect)newRect from:(IntRect)oldRect usingMask:(unsigned char*)oldMask;

/*!
	@method		trimSelection
	@discussion	Trims the selection so it contains no redundant parts, that is,
				so every line in the mask contains some white.
*/
- (void)trimSelection;


@end

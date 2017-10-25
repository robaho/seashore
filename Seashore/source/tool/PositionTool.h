#import "Globals.h"
#import "AbstractTool.h"

/*!
	@class		PositionTool
	@abstract	The position tool allows layers to be repositioned within the
				document.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PositionTool : AbstractTool {

	// The point from which the drag started
	IntPoint initialPoint;
	
	// The mode of positioning
	int mode;

	// An outlet to an instance of a class with the same name
	IBOutlet id seaOperations;
	
	// The scale and rotation values
	float scale;
	float rotation;
	BOOL rotationDefined;

}


/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		mouseDownAt:withEvent:
	@discussion	Handles mouse down events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		modifiers
				The state of the modifiers at the time (see NSEvent).
	@param		event
				The mouse down event.
*/
- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		mouseDraggedTo:withEvent:
	@discussion	Handles mouse dragging events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		modifiers
				The state of the modifiers at the time (see NSEvent).
	@param		event
				The mouse dragged event.
*/
- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		mouseUpAt:withEvent:
	@discussion	Handles mouse up events.
	@param		where
				Where in the document the mouse up event occurred (in terms of
				the document's pixels).
	@param		modifiers
				The state of the modifiers at the time (see NSEvent).
	@param		event
				The mouse up event.
*/
- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		scale
	@discussion	Returns the scale value.
	@result		Returns an floating point number representing the scale value.
*/
- (float)scale;

/*!
	@method		rotation
	@discussion	Returns the rotation value.
	@result		Returns an float representing the rotation value in degrees.
*/
- (float)rotation;

/*!
	@method		rotationDefined
	@discussion	Returns whether or not the rotation value is defined.
	@result		Returns YES if the rotation value is defined, NO otherwise.
*/
- (BOOL)rotationDefined;

/*!
	@method		undoToOrigin:forLayer:
	@discussion	Undoes the repositioning of a layer (this method should only
				ever be called by the undo manager following a call to
				mouseDownAt:withEvent:).
	@param		origin
				The position to restore the given layer's origin to.
	@param		index
				The index of the layer to restore.
*/
- (void)undoToOrigin:(IntPoint)origin forLayer:(int)index;

@end

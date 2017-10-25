#import "Globals.h"
#import "AbstractScaleTool.h"

/*!
	@class		CropTool
	@abstract	The cropping tool allows the user to easily crop the image.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface CropTool : AbstractScaleTool {

	// The point where the selection begun
	IntPoint startPoint;
		
	// The rectangle used for cropping
	IntRect cropRect;
	
	// Are we using the one-to-one ratio?
	BOOL oneToOne;

}

/*!
	@method		mouseDownAt:withEvent:
	@discussion	Handles mouse down events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
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
	@param		event
				The mouse up event.
*/
- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		cropRect
	@discussion	Returns the cropping rectangle.
	@result		Returns an IntRect representing the cropping rectangle.
*/
- (IntRect)cropRect;

/*!
	@method		clearCrop
	@discussion	Reduces the cropping rectangle to nothing.
*/
- (void)clearCrop;

/*!
	@method		adjustOffset:
	@discussion	Adjusts the offset of the cropping rectangle.
	@param		offset
				An IntPoint representing the adjustment in the offset of the
				cropping rectangle.
*/
- (void)adjustCrop:(IntPoint)offset;

/*!
	@method		setCropRect:
	@discussion	Sets the cropping rectangle.
	@param		newCropRect
				An IntRect representing the new rectangle.
*/
- (void)setCropRect:(IntRect)newCropRect;


@end

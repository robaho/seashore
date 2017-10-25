#import "Globals.h"
#import "AbstractTool.h"

/*!
	@class		EyedropTool
	@abstract	The colour sampling tool's role is much the same as in any paint
				program.
	@discussion	Option key - Sets the background colour instead of the
				foreground colour.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface EyedropTool : AbstractTool {

}


/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		sampleSize
	@discussion	Returns the size of the sample square.
	@result		Returns an integer indicating the size (in pixels) of the sample
				square.
*/
- (int)sampleSize;


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
	@method		getColor
	@discussion	Returns a colour as would be used if the colour sampling tool
				was at the current mouse location.
	@result		Returns an instance of NSColor representing the colour as would
				be used if the colour sampling tool was at the current mouse
				location.
*/
- (NSColor *)getColor;

@end

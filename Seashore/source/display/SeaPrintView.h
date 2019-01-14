#import "Globals.h"
#import "SeaPrintOptionsController.h"
#import "SeaDocument.h"

/*!
	@class		SeaView
	@abstract	Responsible for drawing the whiteboard's image to the printer.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli		
*/

@interface SeaPrintView : NSView {

	// The document associated with this view
	SeaDocument *document;
	
}

@property (assign) SeaPrintOptionsController *printOptionsController;

/*!
	@method		initWithDocument:
	@discussion	Initializes an instance of this class with the given document.
	@param		doc
				The document with which to initialize the instance.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithDocument:(id)doc;

/*!
	@method		drawRect:
	@discussion	Draws the contents of the view within the given rectangle.
	@param		rect
				The rectangle containing the contents to be drawn.
*/
- (void)drawRect:(NSRect)rect;

/*!
	@method		isFlipped
	@discussion	Returns whether or not the view uses a flipped co-ordinate
				system.
	@result		Returns YES indicating that the view does use a flipped
				co-ordinate system.
*/
- (BOOL)isFlipped;

/*!
	@method		isOpaque
	@discussion	Returns whether or not the view is opaque.
	@result		Returns YES indicating that the view is opaque.
*/
- (BOOL)isOpaque;

@end

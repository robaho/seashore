#import "Globals.h"

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
	id document;
	
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
	@method		drawRect:
	@discussion	Draws the contents of the view within the given rectangle.
	@param		rect
				The rectangle containing the contents to be drawn.
*/
- (void)drawRect:(NSRect)rect;

/*!
	@method		knowsPageRange:
	@discussion	Sets the page range for the document.
	@param		range
				Returns the page range for the document.
	@result		Returns YES.
*/
- (BOOL)knowsPageRange:(NSRangePointer)range;

/*!
	@method		rectForPage
	@discussion	Returns the printing rectangle for the given page.
	@param		page
				The page for which to return the rectangle.
	@result		Returns an NSRect indicating the printing rectangle.
*/
- (NSRect)rectForPage:(int)page;

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

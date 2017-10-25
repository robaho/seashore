#import "Globals.h"

/*!
	@class		SeaCursors
	@abstract	Handles the cursors for the SeaView
	@discussion	This is a second class for organizational simplicity because it 
	contains a separate set of functionality from the view class.
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@class SeaDocument;
@class	SeaView;

@interface SeaCursors : NSObject {
	// Other Important Objects
	SeaDocument *document;
	SeaView *view;
	
	// The various cursors used by the toolbox
	NSCursor *crosspointCursor, *wandCursor, *zoomCursor, *pencilCursor, *brushCursor, *bucketCursor, *eyedropCursor, *moveCursor, *eraserCursor, *smudgeCursor, *effectCursor, *addCursor, *subtractCursor, *noopCursor;

	// The view-specific cursors
	NSCursor *handCursor, *grabCursor, *udCursor, *lrCursor, *urdlCursor, *uldrCursor, *closeCursor, *resizeCursor, *rotateCursor , *anchorCursor;
	
	// The rects for the handles and selection
	NSRect handleRects[8];
	NSCursor* handleCursors[8];
	
	// The close rect
	NSRect closeRect;

	// Scrolling mode variables
	BOOL scrollingMode;
	BOOL scrollingMouseDown;
}

/*!
	@method		initWithDocument:andView:
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
	@param			newDocument
				The SeaDocument this cursor manager is in
	@param			newView
				The SeaView that uses these cursors
*/
- (id)initWithDocument:(id)newDocument andView:(id)newView;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		resetCursorRects
	@discussion	Sets the current cursor for the view (this is an overridden
				method).
*/
- (void)resetCursorRects;

/*!
	@method		addCursorRect:cursor:
	@discussion	We need this because we need to clip the cursor rect from the
				image to the cursor rect for the superview (so the rects are
				not outside the image).
	@param		rect
				The rect in the coordinates of the SeaView
	@param		cursor
				The cursor to add.
*/
- (void)addCursorRect:(NSRect)rect cursor:(NSCursor *)cursor;

/*!
	@method		handleRectsPointer
	@discussion	Returns a pointer to the rectangles used for the handles.
*/
- (NSRect *)handleRectsPointer;

/*!
	@method		setCloseRect:
	@discussion	For setting the rectangle used for the close cursor for the polygon lasso tool.
	@param		rect
				A NSRect containing the rectangle of the handle.
*/
- (void)setCloseRect:(NSRect)rect;

/*!
	@method		setScrollingMode:mouseDown:
	@discussion	For letting the cursors manager know we are in scrolling mode.
	@param		inMode
				A BOOL if we are in the mode or not.
	@param		mouseDown
				A BOOL if the mouse is down or not.
*/
- (void)setScrollingMode:(BOOL)inMode mouseDown:(BOOL)mouseDown;

@end

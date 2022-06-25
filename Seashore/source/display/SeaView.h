#import "Seashore.h"
#import "SeaCursors.h"
#import "SeaBackground.h"
#import "SeaExtrasView.h"
#import "SeaWhiteboard.h"

/*!
	@enum		k...HandleType
	@constant	kSelectionHandleType
				Indicates the handle is for a selection.
	@constant	kLayerHandleType
				Indicates the handle is for layer boundaries.
	@constant	kCropHandleType
				Indicates the handle is for cropping.
	@constant	kGradientStartType
				Indicates the handle is for the beginning of a gradient tool.
	@constant	kGradentEndType
				Indicates the handle is for the end of a gradient tool.
	@constant	kPolygonalLassoType
				Indicates the handle at the beginning of a polygonal lasso tool.
	@constant	kPositionType
				Indicates the handle for the position tool (scale, rotate).
*/
enum {
	kSelectionHandleType,
	kLayerHandleType,
	kCropHandleType,
	kGradientStartType,
	kGradientEndType,
	kPolygonalLassoType,
	kPositionType,
    kTextHandleType
};

/*!
	@class		SeaView
	@abstract	Responsible for drawing the whiteboard's image to screen.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli		
*/
@class SeaDocument;

@interface SeaView : NSView {
	
	// The document associated with this view
	__weak SeaDocument *document;
	
	// The cursors manager for this view
	SeaCursors* cursorsManager;
	
	// Is this a line draw? (sent to mouseDragged methods)
	BOOL lineDraw;
	
	// Is scaling mode active
	int scalingMode;

	// The magnify timer
	NSTimer* magnifyTimer;

	// Is the tablet eraser active?
	// 0 = No; 1 = Yes, activated through sub-events, 2 = Yes, activated through native events.
	int tabletEraser;

	// The change in the cursor position
	IntPoint delta;
	IntPoint initialPoint;

	// The mouse down location
	NSPoint mouseDownLoc;
	
	// The last active layer point
	IntPoint lastLocalPoint;

	// Was the key up last time?
	BOOL keyWasUp;

	// Memorize the previous tool for a temporary eyedrop selection
	int eyedropToolMemory;
	
	// Values to tell when to trigger scroll
	float scrollZoom, lastTrigger;

	// The amount we've magnified it the time
	float magnifyFactor;

    NSImage *checkerboard;
    NSImage *checkerboard_dark;

    SeaBackground *background;
    SeaWhiteboard *whiteboard;
    SeaExtrasView *extrasView;
}

/*!
	@method		initWithDocument:
	@discussion	Initializes an instance of this class with the given document.
	@param		doc
				The document with which to initialize the instance.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithDocument:(id)doc;

- (IBAction)changeFont:(id)sender;

/*!
	@method		canZoomIn
	@discussion	Returns whether the view can be zoomed in on.
	@result		Returns YES if the view can be zoomed in on, NO otherwise.
*/
- (BOOL)canZoomIn;

/*!
	@method		canZoomOut
	@discussion	Returns whether the view can be zoomed out of.
	@result		Returns YES if the view can be zoomed out of, NO otherwise.
*/
- (BOOL)canZoomOut;

/*!
	@method		zoomNormal:
	@discussion	Sets the zoom of the view to 100%.
	@param		sender
				Ignored.
*/
- (IBAction)zoomNormal:(id)sender;

/*!
    @method        zoomToFit:
    @discussion    Sets the zoom of the view to fit in content area.
    @param        sender
                Ignored.
*/
- (IBAction)zoomToFit:(id)sender;

/*!
 @method        zoomToFitRect:
 @discussion    Sets the zoom to fill the content with the rect
 Ignored.
 */
- (IBAction)zoomToFitRect:(IntRect)rect;

/*!
	@method		zoomIn:
	@discussion	Zooms in on the centre of the view.
	@param		sender
				Ignored.
*/
- (IBAction)zoomIn:(id)sender;

/*!
	@method		zoomOut:
	@discussion	Zooms out from the centre of the view.
	@param		sender
				Ignored.
*/
- (IBAction)zoomOut:(id)sender;

/*!
	@method		zoomTo:
	@discussion	Zooms to a specific power of 2
	@param		power
				An integer that will be the zoom factor.
*/
- (void)zoomTo:(int)power;

/*!
	@method		zoomInToPoint:
	@discussion	Zooms in on a given point of the view.
	@param		point
				The point to zoom in on.
*/
- (void)zoomInToPoint:(NSPoint)point;

/*!
	@method		zoomOutFromPoint:
	@discussion	Zooms out from a given point of the view.
	@param		point
				The point to zoom out from.
*/
- (void)zoomOutFromPoint:(NSPoint)point;

/*!
	@method		zoom
	@discussion	Returns the current zoom level of the view.
	@result		Returns a floating-point number representing the current zoom
				level (1.0 = 100%).
*/
- (float)zoom;

/*!
	@method		mouseMoved:
	@discussion	Handles mouse movements inside the view by sending a mouseMoved
				message to the SeaHelpers.
	@param		theEvent
				The event triggering this method.
*/
- (void)mouseMoved:(NSEvent *)theEvent;

/*!
	@method		scrollWheel:
	@discussion	Overrides scroll wheel to allow zooming.
	@param		theEvent
				The event triggering this method.
*/
- (void)scrollWheel:(NSEvent *)theEvent;

/*!
	@method		readjust
	@discussion	Updates the size of the view to accomodate a change in the
				document size.
*/
- (void)readjust;

/*!
	@method		tabletProximity:
	@discussion	Handles tablet proximity events.
	@param		theEvent
				The event triggering this method.
*/
- (void)tabletProximity:(NSEvent *)theEvent;

/*!
	@method		tabletPoint:
	@discussion	Handles tablet point events.
	@param		theEvent
				The event triggering this method.
*/
- (void)tabletPoint:(NSEvent *)theEvent;

/*!
	@method		rightMouseDown:
	@discussion	Handles right mouse down events inside the view.
	@param		theEvent
				The event triggering this method.
*/
- (void)rightMouseDown:(NSEvent *)theEvent;

/*!
	@method		mouseDown:
	@discussion	Handles mouse down events inside the view generally by passing a
				message on to the current tool.
	@param		theEvent
				The event triggering this method.
*/
- (void)mouseDown:(NSEvent *)theEvent;

/*!
	@method		rightMouseDragged:
	@discussion	Handles right mouse dragged events inside the view.
	@param		theEvent
				The event triggering this method.
*/
- (void)rightMouseDragged:(NSEvent *)theEvent;

/*!
	@method		mouseDragged:
	@discussion	Handles mouse dragged events inside the view generally by
				passing a message on to the current tool.
	@param		theEvent
				The event triggering this method.
*/
- (void)mouseDragged:(NSEvent *)theEvent;

/*!
	@method		rightMouseUp:
	@discussion	Handles right mouse up events inside the view.
	@param		theEvent
				The event triggering this method.
*/
- (void)rightMouseUp:(NSEvent *)theEvent;

/*!
	@method		mouseUp:
	@discussion	Handles mouse up events inside the view generally by passing a
				message on to the current tool. mouseUp: also calls
				mouseDragged: one last time.
	@param		theEvent
				The event triggering this method.
*/
- (void)mouseUp:(NSEvent *)theEvent;

/*!
	@method		delta
	@discussion	A measure of how far the mouse has been dragged.
	@result		An IntPoint that represents the change in position.
*/
- (IntPoint) delta;

/*!
	@method		flagsChanged:
	@discussion	Handles a change in the modifier keys.
	@param		theEvent
				The event triggering this method.
*/
- (void)flagsChanged:(NSEvent *)theEvent;

/*!
	@method		keyDown:
	@discussion	Handles key down events.
	@param		theEvent
				The event triggering this method.
*/
- (void)keyDown:(NSEvent *)theEvent;

/*!
	@method		keyUp:
	@discussion	Handles key up events.
	@param		theEvent
				The event triggering this method.
*/
- (void)keyUp:(NSEvent *)theEvent;

/*!
	@method		clearMagnifySum:
	@discussion	Needed because we don't have discreet magnification, so we need 
				to tally up events (in this case in intervals of 0.1 seconds) and then
				perform the zoom.
	@param		theTimer
				The timer that calls this method, unused
*/
- (void)clearMagnifySum:(NSTimer *)theTimer;

/*!
	@method		cut:
	@discussion	Cuts the currently selected content from the document.
	@param		sender
				Ignored.
*/
- (IBAction)cut:(id)sender;

/*!
	@method		copy:
	@discussion	Copies the currently selected content.
	@param		sender
				Ignored.
*/
- (IBAction)copy:(id)sender;


/*!
	@method		paste:
	@discussion	Pastes the contents of the clipboard.
	@param		sender
				Ignored.
*/
- (IBAction)paste:(id)sender;

/*!
	@method		delete:
	@discussion	Deletes the currently selected content.
	@param		sender
				Ignored.
*/
- (IBAction)delete:(id)sender;

/*!
	@method		selectAll:
	@discussion	Selects all of the active layer.
	@param		sender
				Ignored.
*/
- (IBAction)selectAll:(id)sender;

/*!
	@method		selectNone:
	@discussion	Destroys the active selection.
	@param		sender
				Ignored.
*/
- (IBAction)selectNone:(id)sender;

/*!
	@method		selectInverse:
	@discussion	Selects the inverse of the current selection.
	@param		sender
				Ignored.
*/
- (IBAction)selectInverse:(id)sender;

/*!
 @method        selectInverse:
 @discussion    Selects the alpha mask
 @param        sender
 Ignored.
 */
- (IBAction)selectOpaque:(id)sender;

/*!
	@method		endLineDrawing
	@discussion	Ends line drawing (called by some methods in SeaHelpers).
*/
- (void)endLineDrawing;

/*!
	@method		getMousePosition
	@discussion	Returns the position of the pixel that the mouse is currently
				over or (-1, -1) if no such pixel exists. The value is correct
				for layer specific views.
	@param		compensation
				YES if channel settings should be considered, NO otherwise.
	@result		Returns the position of the pixel that the mouse is currently
				over or (-1, -1) if no such pixel exists.
*/
- (IntPoint)getMousePosition:(BOOL)compensation;

/*!
    @method     setNeedsDisplayInDocumentRect
    @discussion invalid the view in document coordinates
    @param      invalidRect
                the rect to be refreshed in documen coordinates
 */
-(void)setNeedsDisplayInDocumentRect:(IntRect) invalidRect : (int)scaledArea;

/*!
	@method		draggingEntered
	@discussion	Accepts or rejects dragging operations.
	@param		sender
				The NSDraggingInfo object describing the drag operation.
	@result		Returns a constant representing a drag operation or
				NSDragOperationNone if the drag was rejected.
*/
- (NSDragOperation)draggingEntered:(id)sender;

/*!
	@method		performDragOperation:
	@discussion	Completes a drag operation.
	@param		sender
				The NSDraggingInfo object describing the drag operation.
	@result		Returns YES if the operation was successful, NO otherwise.
*/
- (BOOL)performDragOperation:(id)sender;

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

/*!
	@method		acceptsFirstResponder
	@discussion	Returns whether or not the view can be the first responder.
				Being the first responder allows the view to recieve key events.
	@result		Returns YES indicating that the view can be the first responder.
*/
- (BOOL)acceptsFirstResponder;

/*!
	@method		resignFirstResponder
	@discussion	Returns whether or not the view will resign first responder
				status. Being the first responder allows the view to recieve key
				events.
	@result		Returns NO indicating that the view will not resign first
				responder status.
*/
- (BOOL)resignFirstResponder;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled.
	@param		menuItem
				The menu item to be validated.
	@result		YES if the menu item should be enabled, NO otherwise.
*/
- (BOOL)validateMenuItem:(id)menuItem;

- (SeaExtrasView*)extrasView;
@end

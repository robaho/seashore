#ifdef USE_CENTERING_CLIPVIEW

#import "Globals.h"

/*!
	@class		CenteringClipView
	@abstract	Extends NSClipView so that it behaves similiar to the clip view
				seen in the Preview application.
	@discussion	Elaborating on the abstract, CenteringClipView centres the 
				document view and hides the scrollbars when the window size
				exceeds that of the document. It also provides methods for easy
				centre-focused zooming. This is version is intended for Mac OS
				10.3 and later.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Brock Brandenberg and
				Copyright (c) 2002 Mark Pazolli
				<br><br>
				<i>See <a href="http://bergdesign.com/missing_cocoa_docs/nsclipview.html">
				http://bergdesign.com/missing_cocoa_docs/nsclipview.html</a>
				for the tutorial from which this code came.</i>
*/

@interface CenteringClipView : NSClipView {
	
	// Does the view have a horizontal scrollbar?
	BOOL hasHorizontalScrollbar;
	
	// Does the view have a vertical scrollbar?
	BOOL hasVerticalScrollbar;
	
	// We nede to prevent an infinate loop in scroll events...
	NSEvent *mostRecentScrollEvent;
}

/*!
	@method		centerPoint:
	@discussion	Returns the point at the centre of the clip view.
	@result		Returns a NSPoint indicating the point relative to the document
				contents at the centre of the clip view.
*/
- (NSPoint)centerPoint;

/*!
	@method		setCenterPoint:
	@discussion	Sets the point at the centre of the clip view.
	@param		centerPoint
				The point to be located at the centre of the clip view (if
				possible).
*/
- (void)setCenterPoint:(NSPoint)centerPoint;

/*!
	@method		setDocumentView:
	@discussion	Used when the document starts and determines if we have scrollbars
	@param		aView
				The NSView to setup
*/
- (void)setDocumentView:(NSView *)aView;

/*!
	@method		constrainScrollPoint:
	@discussion	We need to override this so that the superclass doesn't override our new origin point.
	@param		proposedNewOrigin
				The NSPoint that we are going to use
*/
- (NSPoint)constrainScrollPoint:(NSPoint)proposedNewOrigin;

/*!
	@method		setFrame:
	@discussion	When a new frame is needed (the window has been resized).
	@param		frameRect
				The NSRect that is this new frame
*/
- (void)setFrame:(NSRect)frameRect;

/*!
	@method		viewFrameChanged:
	@discussion	A notification that tells us the subview has changed (usually because of zooming).
	@param		notification
				The NSNotification we're given
*/
- (void)viewFrameChanged:(NSNotification *)notification;

/*!
	@method		scrollToPoint:
	@discussion	Scroll to a different point
	@param		newOrigin
				The new origin for the veiw
*/
- (void)scrollToPoint:(NSPoint)newOrigin;

@end

#endif

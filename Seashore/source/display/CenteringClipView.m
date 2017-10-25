#ifdef USE_CENTERING_CLIPVIEW

#import "CenteringClipView.h"

@implementation CenteringClipView

- (NSPoint)centerPoint
{
	NSRect docRect = [[self documentView] frame];
	NSRect clipRect = [self bounds];
	NSPoint point;
	
	// Work out the x co-ordinate that is at the center of the NSScrollView
	if (docRect.size.width > clipRect.size.width)
		point.x = roundf(clipRect.size.width / 2.0 + clipRect.origin.x);
	else
		point.x = roundf(docRect.size.width / 2.0);
	
	// Work out the y co-ordinate that is at the center of the NSScrollView
	if (docRect.size.height > clipRect.size.height)
		point.y = roundf(clipRect.size.height / 2.0 + clipRect.origin.y);
	else
		point.y = roundf(docRect.size.height / 2.0);

	return point;
}

- (void)setCenterPoint:(NSPoint)centerPoint
{
	NSRect docRect = [[self documentView] frame];
	NSRect clipRect = [self bounds];
	NSPoint point;
	
	// If the document is horizontally larger than the scroll view...
	if (docRect.size.width > clipRect.size.width) {
		
		// Request the scroll bars be shown and make the given point the center
		point.x = roundf(centerPoint.x - clipRect.size.width / 2.0);
		
	}
	
	// If the document is vertically larger than the scroll view...
	if (docRect.size.height > clipRect.size.height) {
		
		// Request the scroll bars be shown and make the given point the center
		point.y = roundf(centerPoint.y - clipRect.size.height / 2.0);
	
	}
	
	// Move in to position
	[self scrollToPoint:[self constrainScrollPoint:point]];
	[(NSScrollView *)[self superview] setNeedsDisplay:YES];
	[(NSScrollView *)[self superview] reflectScrolledClipView:self];
}

- (void)setDocumentView:(NSView *)aView
{
	NSRect docRect, frameRect;
	BOOL shouldHaveVerticalScrollbar = NO;
	BOOL shouldHaveHorizontalScrollbar = NO;
	
	// Set the document view
	[super setDocumentView:aView];
	
	// Get the document rectangle
	docRect = [[self documentView] frame];
	frameRect = [super frame];
	
	// If the document is horizontally larger than the scroll view...
	if (docRect.size.width > frameRect.size.width) {
		
		// Request the horizontal scroll bar be shown
		shouldHaveHorizontalScrollbar = YES;
	
	}
	
	// If the document is vertically larger than the scroll view...
	if (docRect.size.height > frameRect.size.height) {
	
		// Request the vertical scroll bar be shown
		shouldHaveVerticalScrollbar = YES;
	}
	
	// Show/hide scrollbars
	hasHorizontalScrollbar = shouldHaveHorizontalScrollbar;
	hasVerticalScrollbar = shouldHaveVerticalScrollbar;
	[(NSScrollView *)[self superview] setHasHorizontalScroller:hasHorizontalScrollbar];
	[(NSScrollView *)[self superview] setHasVerticalScroller:hasVerticalScrollbar];
}

- (NSPoint)constrainScrollPoint:(NSPoint)proposedNewOrigin
{
	NSRect docRect, frameRect;
	NSPoint point = proposedNewOrigin;
	float maxX, maxY;
	
	// Get the document rectangle
	docRect = [[self documentView] frame];
	frameRect = [super frame];
	
	// Determine maxX and maxY
	maxX = docRect.size.width - frameRect.size.width;
	maxY = docRect.size.height - frameRect.size.height;
	
	// Don't let the x co-ordinate of the new origin go out of bounds (or if this view is centering off center)
	if (docRect.size.width > frameRect.size.width)
		point.x = roundf(MAX(0, MIN(point.x, maxX)));
	else
		point.x = roundf(maxX / 2.0);
	
	// Don't let the y co-ordinate of the new origin go out of bounds (or if this view is centering off center)
	if(docRect.size.height > frameRect.size.height)
		point.y = roundf(MAX(0, MIN(point.y, maxY)));
	else
		point.y = roundf(maxY / 2.0);
		
	return point;
}

static BOOL preventRecurse = NO;

- (void)updateScrollbars:(NSRect)frameRect
{
	NSRect docRect;
	BOOL shouldHaveVerticalScrollbar;
	BOOL shouldHaveHorizontalScrollbar;
	NSPoint scrollPoint;
	float dw, dh, fw, fh, fwo, fho;
	
	if (!preventRecurse) {
		
		// Get the document rectangle
		docRect = [[self documentView] frame];
		scrollPoint = [self bounds].origin;
		shouldHaveVerticalScrollbar = NO;
		shouldHaveHorizontalScrollbar = NO;
		
		// Store for easy access
		dw = docRect.size.width;
		dh = docRect.size.height;
		fw = frameRect.size.width;
		fh = frameRect.size.height;
		fwo = fw + 15 * hasVerticalScrollbar;
		fho = fh + 15 * hasHorizontalScrollbar;
		
		// Figure out how if the scrollbars will display
		if (dw <= fw && dh <= fh) {
			shouldHaveHorizontalScrollbar = NO;
			shouldHaveVerticalScrollbar = NO;
		} else if(dw > fwo && dh < fh) {
			shouldHaveHorizontalScrollbar = YES;
			shouldHaveVerticalScrollbar = NO;
		} else if(dh > fho && dw < fw) {
			shouldHaveHorizontalScrollbar = NO;
			shouldHaveVerticalScrollbar = YES;
		} else if(dw > fwo && dh > fho) {
			shouldHaveHorizontalScrollbar = YES;
			shouldHaveVerticalScrollbar = YES;
		} else if(dw <= fwo && dh <= fho) {
			shouldHaveHorizontalScrollbar = NO;
			shouldHaveVerticalScrollbar = NO;
		} else {
			shouldHaveHorizontalScrollbar = YES;
			shouldHaveVerticalScrollbar = YES;
		}

		// Find the new center(s)
		if (shouldHaveHorizontalScrollbar && !shouldHaveVerticalScrollbar) {
			scrollPoint.y = roundf((dh - fh + 15 * !hasHorizontalScrollbar) / 2.0);
		} else if (!shouldHaveHorizontalScrollbar && shouldHaveVerticalScrollbar) {
			scrollPoint.x = roundf((dw - fw + 15 * !hasVerticalScrollbar) / 2.0);
		} else if (!shouldHaveHorizontalScrollbar && !shouldHaveVerticalScrollbar) {
			scrollPoint.x = roundf((dw - fwo) / 2.0);
			scrollPoint.y = roundf((dh - fho) / 2.0);
		}
			
		// Show/hide scrollbars
		if (shouldHaveHorizontalScrollbar != hasHorizontalScrollbar) {
			hasHorizontalScrollbar = !hasHorizontalScrollbar;
			preventRecurse = YES;
			[(NSScrollView *)[self superview] setHasHorizontalScroller:hasHorizontalScrollbar];
			preventRecurse = NO;
		}
		
		if (shouldHaveVerticalScrollbar != hasVerticalScrollbar) {
			hasVerticalScrollbar = !hasVerticalScrollbar;
			preventRecurse = YES;
			[(NSScrollView *)[self superview] setHasVerticalScroller:hasVerticalScrollbar];
			preventRecurse = NO;
		}

		// Move in to position
		[self scrollToPoint:scrollPoint];
		
	}
}

- (void)setFrame:(NSRect)frameRect
{
	// Set the frame
	[super setFrame:frameRect];
	[self updateScrollbars:frameRect];
}

- (void)viewFrameChanged:(NSNotification *)notification
{
	// Observe the change
	[super viewFrameChanged:notification];
	[self updateScrollbars:[super frame]];
}

- (void)scrollToPoint:(NSPoint)newOrigin
{
	[super scrollToPoint:newOrigin];
	[(NSScrollView *)[self superview] setNeedsDisplay:YES];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	if(mostRecentScrollEvent==theEvent)
	{
		[super scrollWheel:theEvent];
		return;
	}
	mostRecentScrollEvent = theEvent;
	[[self documentView] scrollWheel:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[[self documentView] rightMouseDown:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[[self documentView] mouseDown:theEvent];
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	[[self documentView] rightMouseDragged:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	[[self documentView] mouseDragged:theEvent];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	[[self documentView] rightMouseUp:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[[self documentView] mouseUp:theEvent];
}

- (void)magnifyWithEvent:(NSEvent *)theEvent
{
	[[self documentView] magnifyWithEvent:theEvent];
}

- (void)swipeWithEvent:(NSEvent *)theEvent
{
	[[self documentView] swipeWithEvent:theEvent];
}

@end

#endif

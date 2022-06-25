#import "CenteringClipView.h"
#import "SeaPrefs.h"

#import <CoreGraphics/CGGeometry.h>
#import <Carbon/Carbon.h>
#import <CoreImage/CoreImage.h>
#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>


@implementation CenteringClipView

- (CenteringClipView*)init
{
    self = [super init];
    if (@available(macOS 10.10, *)) {
        // need to do our own layout because of bugs
        self.automaticallyAdjustsContentInsets = NO;
    }

    self.translatesAutoresizingMaskIntoConstraints=FALSE;
    self.autoresizesSubviews=TRUE;

    return self;
}

- (void)updateTrackingAreas
{
    for(NSTrackingArea *ta in [self trackingAreas]){
        [self removeTrackingArea:ta];
    }

    NSTrackingAreaOptions options = (NSTrackingActiveInKeyWindow | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved);

    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                        options:options
                                                          owner:self
                                                       userInfo:nil];
    [self addTrackingArea:area];
}

- (void)setFrame:(NSRect)frame
{
    NSScrollView *sv = [self enclosingScrollView];
    if (sv.rulersVisible) {
        NSRulerView *hr = sv.horizontalRulerView;
        NSRulerView *vr = sv.verticalRulerView;
        frame.origin.x += vr.requiredThickness;
        frame.size.width -= vr.requiredThickness;
        frame.origin.y += hr.requiredThickness;
        frame.size.height -= hr.requiredThickness;
    }
    [super setFrame:frame];
}

-(void)drawRect:(NSRect)dirtyRect
{
    [[(SeaPrefs *)[SeaController seaPrefs] windowBack] setFill];
    NSRectFill(dirtyRect);

    float magnification = [(NSScrollView*)[self superview] magnification];

    NSRect docFrame = [[self documentView] frame];

    NSSize offset = NSMakeSize(10,10);
    NSRect border = NSOffsetRect(docFrame,offset.width/magnification,offset.height/magnification);

    NSShadow *shadow = [[NSShadow alloc] init];
    [[shadow shadowColor] setFill];
    NSRectFillUsingOperation(border, NSCompositingOperationSourceOver);
}

- (NSPoint)centerPoint
{
	NSRect docRect = [[self documentView] frame];
	NSRect clipRect = [self frame];
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

- (NSRect)constrainBoundsRect:(NSRect)r {

    r = [super constrainBoundsRect:r];

    NSView *containerView = [self documentView];

    NSRect avail = containerView.frame;

    if (r.size.width > avail.size.width) {
        r.origin.x = (avail.size.width - r.size.width) / 2;
    }

    if(r.size.height > avail.size.height) {
        r.origin.y = (avail.size.height - r.size.height) / 2;
    }

    return r;
}
- (BOOL)autoscroll:(NSEvent *)event
{
    NSScrollView *sv = [self enclosingScrollView];
    if([[sv verticalScroller] isHidden] && [[sv horizontalScroller] isHidden])
        return FALSE;

    return [super autoscroll:event];
}

- (BOOL)isFlipped
{
    return TRUE;
}

- (BOOL)isOpaque
{
    return TRUE;
}
- (void)mouseEntered:(NSEvent *)event
{
    [[self window] disableCursorRects];
}

- (void)mouseExited:(NSEvent *)event
{
    [[self window] enableCursorRects];
}

- (void)mouseMoved:(NSEvent *)event
{
    [[self documentView] mouseMoved:event];
}

@end

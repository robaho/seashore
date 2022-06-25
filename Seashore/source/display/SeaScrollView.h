#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class SeaDocument;

@interface SeaScrollView : NSScrollView
{
    __weak SeaDocument *document;
    NSRulerView* verticalRuler,*horizontalRuler;
    NSRulerMarker* vMarker,*hMarker,*vStatMarker,*hStatMarker;
    NSDate *lastRulerUpdate;
    NSView *overlay;
}
- (SeaScrollView*) initWithDocument:(SeaDocument*)document andView:(NSView*)view andOverlay:(NSView*)overlay;
- (void) updateRulers;
- (void) updateRulersVisibility;

/*!
 @method        updateRulerMarkings:andStationary:
 @discussion    Updates the ruler markings including the stationary ones.
 @param        mouseLocation
 The mouse location.
 @param        statLocation
 The mouse location corresponding to the stationary markers.
 */
- (void)updateRulerMarkings:(NSPoint)mouseLocation andStationary:(NSPoint)statLocation;

@end

NS_ASSUME_NONNULL_END

#import "Seashore.h"
#import "SeaScrollView.h"
#import "CenteringClipView.h"
#import "SeaController.h"
#import "SeaDocument.h"
#import "SeaPrefs.h"
#import "Units.h"

#import <Carbon/Carbon.h>
#import <CoreImage/CoreImage.h>
#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

@implementation SeaScrollView

- (SeaScrollView*) initWithDocument:(SeaDocument*)document andView:(NSView*)view andOverlay:(NSView*)overlay
{
    self = [super init];

    self->document = document;
    self->overlay = overlay;

    lastRulerUpdate = [NSDate distantPast];

    CenteringClipView *clipView = [[CenteringClipView alloc] init];

    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    [self setContentView:clipView];
    [self setDocumentView:view];

    [self addSubview:overlay positioned:NSWindowAbove relativeTo:clipView];

    [self setHasHorizontalScroller:TRUE];
    [self setHasVerticalScroller:TRUE];
    [self setAutohidesScrollers:TRUE];

    [self setDrawsBackground:YES];

    [self setMinMagnification:(1/32.0)];
    [self setMaxMagnification:32];

    [self setHasHorizontalRuler:YES];
    [self setHasVerticalRuler:YES];

    horizontalRuler = [self horizontalRulerView];
    verticalRuler = [self verticalRulerView];

    [verticalRuler setClientView:view];
    [horizontalRuler setClientView:view];

    // Add the markers
    vMarker = [[NSRulerMarker alloc]initWithRulerView:verticalRuler markerLocation:0 image:[NSImage imageNamed:@"vMarkerTemplate"] imageOrigin:NSMakePoint(4.0,4.0)];
    [verticalRuler addMarker:vMarker];
    hMarker = [[NSRulerMarker alloc]initWithRulerView:horizontalRuler markerLocation:0 image:[NSImage imageNamed:@"hMarkerTemplate"] imageOrigin:NSMakePoint(4.0,0.0)];
    [horizontalRuler addMarker:hMarker];
    vStatMarker = [[NSRulerMarker alloc]initWithRulerView:verticalRuler markerLocation:-256e6 image:[NSImage imageNamed:@"vStatMarkerTemplate"] imageOrigin:NSMakePoint(4.0,4.0)];
    [verticalRuler addMarker:vStatMarker];
    hStatMarker = [[NSRulerMarker alloc]initWithRulerView:horizontalRuler markerLocation:-256e6 image:[NSImage imageNamed:@"hStatMarkerTemplate"] imageOrigin:NSMakePoint(4.0,0.0)];
    [horizontalRuler addMarker:hStatMarker];

    // Make the rulers visible/invsible
    [self updateRulers];
    [self updateRulersVisibility];

    return self;
}

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];

    if(!self.window.visible && [[SeaController seaPrefs] zoomToFitAtOpen]) {
        [[document docView] zoomToFit:self];
    }
}

- (void)tile
{
    [super tile];

    [overlay setFrame:[[self contentView] frame]];
    [overlay setBounds:[[self contentView] bounds]];
}

- (void)reflectScrolledClipView:(NSClipView *)cView
{
    [super reflectScrolledClipView:cView];
    [overlay setFrame:[[self contentView] frame]];
    [overlay setBounds:[[self contentView] bounds]];
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize
{
    [self setFrame:[self.superview bounds]];
}

- (void)updateRulersVisibility
{
    [self setRulersVisible:[[SeaController seaPrefs] rulers]];
    [self setNeedsLayout:TRUE];
}

- (void)updateRulers
{
    NSString *uniqueId = [NSString stringWithFormat:@"%p", document];;
    NSString *uniqueIdX = [uniqueId stringByAppendingString:@"x"];
    NSString *uniqueIdY = [uniqueId stringByAppendingString:@"y"];

    // Set up the rulers for the new settings
    switch ([document measureStyle]) {
        case kPixelUnits:
            [NSRulerView registerUnitWithName:uniqueIdX abbreviation:@"px" unitToPointsConversionFactor:1.0 stepUpCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:10.0]] stepDownCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:0.5]]];
            [horizontalRuler setMeasurementUnits:uniqueIdX];
            [NSRulerView registerUnitWithName:uniqueIdY abbreviation:@"px" unitToPointsConversionFactor:1.0 stepUpCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:10.0]] stepDownCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:0.5]]];
            [verticalRuler setMeasurementUnits:uniqueIdY];
            break;
        case kInchUnits:
            [NSRulerView registerUnitWithName:uniqueIdX abbreviation:@"in" unitToPointsConversionFactor:[[document contents] xres] stepUpCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:2.0]] stepDownCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:0.5]]];
            [NSRulerView registerUnitWithName:uniqueIdY abbreviation:@"in" unitToPointsConversionFactor:[[document contents] yres]  stepUpCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:2.0]] stepDownCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:0.5]]];
            [horizontalRuler setMeasurementUnits:uniqueIdX];
            [verticalRuler setMeasurementUnits:uniqueIdY];
            break;
        case kMillimeterUnits:
            [NSRulerView registerUnitWithName:uniqueIdX abbreviation:@"mm" unitToPointsConversionFactor:[[document contents] xres]/25.4 stepUpCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:5.0]] stepDownCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:0.5]]];
            [NSRulerView registerUnitWithName:uniqueIdY abbreviation:@"mm" unitToPointsConversionFactor:[[document contents] yres]/25.4 stepUpCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:5.0]] stepDownCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:0.5]]];
            [horizontalRuler setMeasurementUnits:uniqueIdX];
            [verticalRuler setMeasurementUnits:uniqueIdY];
            break;
    }
}

- (void)updateRulerMarkings:(NSPoint)mouseLocation andStationary:(NSPoint)statLocation
{
    NSPoint markersLocation, statMarkersLocation;

    // Only make a change if it has been more than 0.03 seconds
    if ([self rulersVisible] && (!lastRulerUpdate || [[NSDate date] timeIntervalSinceDate:lastRulerUpdate] > 0.03)) {

        // Record this as the new time of the last update
        lastRulerUpdate = [NSDate date];

        // Get mouse location and convert it
        markersLocation.x = [[horizontalRuler clientView] convertPoint:mouseLocation fromView:nil].x;
        markersLocation.y = [[verticalRuler clientView] convertPoint:mouseLocation fromView:nil].y;
        statMarkersLocation.x = [[horizontalRuler clientView] convertPoint:statLocation fromView:nil].x;
        statMarkersLocation.y = [[verticalRuler clientView] convertPoint:statLocation fromView:nil].y;

        // Move the horizontal marker
        [hMarker setMarkerLocation:markersLocation.x];
        [hStatMarker setMarkerLocation:statMarkersLocation.x];
        [horizontalRuler setNeedsDisplay:YES];

        // Move the vertical marker
        [vMarker setMarkerLocation:markersLocation.y];
        [vStatMarker setMarkerLocation:statMarkersLocation.y];
        [verticalRuler setNeedsDisplay:YES];
    }
}


@end

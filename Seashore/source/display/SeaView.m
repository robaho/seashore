#import "SeaView.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "UtilitiesManager.h"
#import "CenteringClipView.h"
#import "TransparentUtility.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "SeaLayer.h"
#import "ToolboxUtility.h"
#import "ColorSelectView.h"
#import "SeaWhiteboard.h"
#import "SeaTools.h"
#import "PositionTool.h"
#import "PencilTool.h"
#import "BrushTool.h"
#import "SeaLayerUndo.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import "Units.h"
#import "SeaPrintView.h"
#import "PositionTool.h"
#import "InfoUtility.h"
#import "OptionsUtility.h"
#import "BrushOptions.h"
#import "PositionOptions.h"
#import "RectSelectOptions.h"
#import "CloneTool.h"
#import "LassoTool.h"
#import "RectSelectTool.h"
#import "EllipseSelectTool.h"
#import "PolygonLassoTool.h"
#import "CropTool.h"
#import "WandTool.h"
#import "SeaWarning.h"
#import "EffectTool.h"
#import "GradientTool.h"
#import "SeaFlip.h"
#import "SeaOperations.h"
#import "SeaCursors.h"
#import "AspectRatio.h"
#import "WarningsUtility.h"
#import "SeaScale.h"
#import "NSEvent_Extensions.h"
#import <Carbon/Carbon.h>

extern IntPoint gScreenResolution;

static NSString*    SelectNoneToolbarItemIdentifier = @"Select None Toolbar Item Identifier";
static NSString*    SelectAllToolbarItemIdentifier = @"Select All Toolbar Item Identifier";
static NSString*    SelectInverseToolbarItemIdentifier = @"Select Inverse Toolbar Item Identifier";
static NSString*    SelectAlphaToolbarItemIdentifier = @"Select Alpha Toolbar Item Identifier";

static CGFloat black[4] = {0,.5,2,3.5};
static CGFloat white[4] = {0,3.5,2,.5};

@implementation SeaView

- (id)initWithDocument:(id)doc 
{    
    NSRect frame;
    int xres, yres;
    
    // Set the last ruler update to take place in the distant past
    lastRulerUpdate = [NSDate distantPast];
    
    // Remember the document this view is displaying
    document = doc;
    
    // Determine the frame at 100% 72-dpi
    frame = NSMakeRect(0, 0, [(SeaContent *)[document contents] width], [(SeaContent *)[document contents] height]);

    // Adjust frame for non 72 dpi resolutions
    xres = [[document contents] xres];
    yres = [[document contents] yres];
    if (gScreenResolution.x != 0 && xres != gScreenResolution.x){
        frame.size.width /= ((float)xres / gScreenResolution.x);
    }
    
    if (gScreenResolution.y != 0 && yres != gScreenResolution.y) {
        frame.size.height /= ((float)yres / gScreenResolution.y);
    }

    // Initialize superclass
    if ([super initWithFrame:frame] == NULL){
        return NULL;
    }
    
    // Set data members appropriately
    lineDraw = NO;
    keyWasUp = YES;
    scrollingMode = NO;
    scrollTimer = NULL;
    magnifyTimer = NULL;
    magnifyFactor = 1.0;
    tabletEraser = 0;
    eyedropToolMemory = kEyedropTool;
    scrollZoom = lastTrigger = 0.0;
    
    // Set the delta
    delta = IntMakePoint(0,0);
    
    // Set the zoom appropriately
    zoom = 1.0;
    
    // Create the cursors manager
    cursorsManager = [[SeaCursors alloc] initWithDocument: doc andView: self];
    
    // Register for drag operations
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSTIFFPboardType, NSPICTPboardType, NSFilenamesPboardType, nil]];
    
    // Set up the rulers
    [[document scrollView] setHasHorizontalRuler:YES];
    [[document scrollView] setHasVerticalRuler:YES];
    horizontalRuler = [[document scrollView] horizontalRulerView];
    verticalRuler = [[document scrollView] verticalRulerView];
    [self updateRulers];
    
    // Change the ruler client views
    [verticalRuler setClientView:[document scrollView]];
    [horizontalRuler setClientView:[document scrollView]];
    [document scrollView];
    
    // Add the markers
    vMarker = [[NSRulerMarker alloc]initWithRulerView:verticalRuler markerLocation:0 image:[NSImage imageNamed:@"vMarker"] imageOrigin:NSMakePoint(4.0,4.0)];
    [verticalRuler addMarker:vMarker];
    hMarker = [[NSRulerMarker alloc]initWithRulerView:horizontalRuler markerLocation:0 image:[NSImage imageNamed:@"hMarker"] imageOrigin:NSMakePoint(4.0,0.0)];
    [horizontalRuler addMarker:hMarker];
    vStatMarker = [[NSRulerMarker alloc]initWithRulerView:verticalRuler markerLocation:-256e6 image:[NSImage imageNamed:@"vStatMarker"] imageOrigin:NSMakePoint(4.0,4.0)];
    [verticalRuler addMarker:vStatMarker];
    hStatMarker = [[NSRulerMarker alloc]initWithRulerView:horizontalRuler markerLocation:-256e6 image:[NSImage imageNamed:@"hStatMarker"] imageOrigin:NSMakePoint(4.0,0.0)];
    [horizontalRuler addMarker:hStatMarker];
    
    // Make the rulers visible/invsible
    [self updateRulersVisiblity];
    
    // Warn if bad resolution
    if (xres != yres || (xres < 72)) {
        [[SeaController seaWarning] addMessage:LOCALSTR(@"strange res message", @"This image has an unusual resolution. As such, it may look different to what is expected at 100% zoom. To fix this use \"Image > Resolution...\" and set to 72 x 72 dpi.") forDocument: document level:kLowImportance];
    }
    else if (xres > 300) {
        [[SeaController seaWarning] addMessage:LOCALSTR(@"high res message", @"This image has a high resolution. Seashore's performance may therefore be reduced. You can reduce the resolution using \"Image > Resolution...\" (with \"Preserve size\" checked). This will result in a lower-quality image.") forDocument: document level:kLowImportance];
    }
    
    return self;
}

- (void)dealloc
{
    // the following is a work-around for issue #30 which appears to be OS version dependent
    [verticalRuler setClientView:nil];
    [horizontalRuler setClientView:nil];
}


- (IBAction)changeSpecialFont:(id)sender
{
    [[[[SeaController utilitiesManager] optionsUtilityFor:document] getOptions:kTextTool] changeFont:sender];
}

- (void)needsCursorsReset
{
    // Tell the parent that the cursors need to be invalidated
    [[self window] invalidateCursorRectsForView:self];
}
    
- (void)resetCursorRects
{
    // Inform the cursor manager that we will need the new cursor rects
    [cursorsManager resetCursorRects];
}

- (BOOL)canZoomIn
{
    return (zoom <= 128.0);
}

- (BOOL)canZoomOut
{
    return (zoom >= 1.0 / 32.0);
}

- (IBAction)zoomNormal:(id)sender
{
    NSRect frame;
    
    zoom = 1.0;
    [self updateRulers];
    frame = NSMakeRect(0, 0, [(SeaContent *)[document contents] width], [(SeaContent *)[document contents] height]);
    if (gScreenResolution.x != 0 && [[document contents] xres] != gScreenResolution.x) frame.size.width /= ((float)[[document contents] xres] / gScreenResolution.x);
    if (gScreenResolution.y != 0 && [[document contents] yres] != gScreenResolution.y) frame.size.height /= ((float)[[document contents] yres] / gScreenResolution.y);
    [(NSClipView *)[self superview] scrollToPoint:NSMakePoint(0, 0)];
    [self setFrame:frame];
    [(CenteringClipView *)[self superview] setCenterPoint:NSMakePoint(frame.size.width / 2.0, frame.size.height / 2.0)];
    [self setNeedsDisplay:YES];
    [[document helpers] zoomChanged];
}

- (IBAction)zoomIn:(id)sender
{    
    NSPoint point = [(CenteringClipView *)[self superview] centerPoint];
    [self zoomInToPoint:point];
}

- (void)zoomTo:(int)power
{
    NSPoint point = NSZeroPoint;
    point = [(CenteringClipView *)[self superview] centerPoint];
    
    if(zoom > pow(2, power)){
        while(zoom > pow(2, power)){
            [self zoomOutFromPoint:point];
        }
    }else if(zoom < pow(2, power)){
        while(zoom < pow(2, power)){
            [self zoomInToPoint:point];
        }
    }
}

- (void)zoomInToPoint:(NSPoint)point
{
    NSRect frame;
    
    zoom *= 2.0; point.x *= 2.0; point.y *= 2.0;
    [self updateRulers];
    frame = NSMakeRect(0, 0, [(SeaContent *)[document contents] width], [(SeaContent *)[document contents] height]);
    if (gScreenResolution.x != 0 && [[document contents] xres] != gScreenResolution.x) frame.size.width /= ((float)[[document contents] xres] / gScreenResolution.x);
    if (gScreenResolution.y != 0 && [[document contents] yres] != gScreenResolution.y) frame.size.height /= ((float)[[document contents] yres] / gScreenResolution.y);
    frame.size.height *= zoom; frame.size.width *= zoom;
    [self setFrame:frame];
    [(CenteringClipView *)[self superview] setCenterPoint:point];
    [self setNeedsDisplay:YES];
    [[document helpers] zoomChanged];
}

- (IBAction)zoomOut:(id)sender
{
    NSPoint point = [(CenteringClipView *)[self superview] centerPoint];
    
    [self zoomOutFromPoint:point];
}

- (void)zoomOutFromPoint:(NSPoint)point
{
    NSRect frame;
    
    zoom /= 2.0; point.x = roundf(point.x / 2.0); point.y = roundf(point.y / 2.0);
    [self updateRulers];
    frame = NSMakeRect(0, 0, [(SeaContent *)[document contents] width], [(SeaContent *)[document contents] height]);
    if (gScreenResolution.x != 0 && [[document contents] xres] != gScreenResolution.x) frame.size.width /= ((float)[[document contents] xres] / gScreenResolution.x);
    if (gScreenResolution.y != 0 && [[document contents] yres] != gScreenResolution.y) frame.size.height /= ((float)[[document contents] yres] / gScreenResolution.y);
    frame.size.height *= zoom; frame.size.width *= zoom;
    [self setFrame:frame];
    [(CenteringClipView *)[self superview] setCenterPoint:point];
    [self setNeedsDisplay:YES];
    [[document helpers] zoomChanged];
}

- (float)zoom
{
    return zoom;
}

- (void)drawRect:(NSRect)rect
{
    NSRect srcRect, destRect;
    NSImage *image = NULL;
    id tUtil = [[SeaController utilitiesManager] toolboxUtilityFor:document];
    int curToolIndex = [tUtil tool];
    IntRect imageRect = [[document whiteboard] imageRect];
    int xres = [[document contents] xres], yres = [[document contents] yres];
    float xResScale, yResScale;

    // Get the correct image for displaying
    image = [[document whiteboard] image];
    srcRect = destRect = rect;
    
//    NSLog(@"%@",NSStringFromRect(rect));
    
    // Set the background color
    if ([[document whiteboard] whiteboardIsLayerSpecific]) {
        [[NSColor colorWithCalibratedWhite:0.6667 alpha:1.0] set];
        [[NSBezierPath bezierPathWithRect:destRect] fill];
    }
    else {
        if([(SeaPrefs *)[SeaController seaPrefs] useCheckerboard]){
            [[NSColor colorWithPatternImage: [NSImage imageNamed:@"checkerboard"] ] set];
        }else{
            [(NSColor*)[[[SeaController utilitiesManager] transparentUtility] color] set];
        }
        [[NSBezierPath bezierPathWithRect:destRect] fill];
    }
    
    // We want our image flipped
    [image setFlipped:YES];
    
    // For non 72 dpi resolutions we must scale here
    xResScale = yResScale = 1.0;
    if (gScreenResolution.x != 0 && gScreenResolution.y != 0) {
        if (xres != gScreenResolution.x) {
            xResScale = ((float)xres / gScreenResolution.x);
        }
        if (yres != gScreenResolution.y) {
            yResScale = ((float)yres / gScreenResolution.y);
        }
    }
    srcRect.origin.x *= xResScale;
    srcRect.size.width *= xResScale;
    srcRect.origin.y *= yResScale;
    srcRect.size.height *= yResScale;
    
    // Then scale here for zoom
    srcRect.origin.x /= zoom;
    srcRect.size.width /= zoom;
    srcRect.origin.y /= zoom;
    srcRect.size.height /= zoom;
    
    // Position the image correctly
    srcRect.origin.x -= imageRect.origin.x;
    srcRect.origin.y -= imageRect.origin.y;
    
    // Set interpolation (image smoothing) appropriately
    if ([[SeaController seaPrefs] smartInterpolation]) {
        if (srcRect.size.width > destRect.size.width || (gScreenResolution.x > 72 && (xres / 72.0) * zoom <= 4))
            [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        else
            [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
    }
    else {
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
    }
    
    // Draw the image to screen
    [image drawInRect:destRect fromRect:srcRect operation:NSCompositeSourceOver fraction:1.0];

    // Clear out the old cursor rects
    [self needsCursorsReset];
    
    // If we aren't using the view for printing draw the boundaries and the marching ants
    if (
        ([[SeaController seaPrefs] layerBounds] && ![[document whiteboard] whiteboardIsLayerSpecific]) ||
        [[document selection] active] ||
        (curToolIndex == kCropTool) ||
        (curToolIndex == kRectSelectTool && [(RectSelectTool *)[[document tools] getTool: kRectSelectTool] intermediate]) ||
        (curToolIndex == kEllipseSelectTool && [(EllipseSelectTool *)[[document tools] getTool: kEllipseSelectTool] intermediate]) ||
        (curToolIndex == kLassoTool && [(LassoTool *)[[document tools] getTool:kLassoTool] intermediate]) ||
        (curToolIndex == kPolygonLassoTool && [(PolygonLassoTool *)[[document tools] getTool:kPolygonLassoTool] intermediate])
        ) {
        [self drawBoundaries];
    }
    [self drawExtras];
}

- (void)drawBoundaries
{
    int curToolIndex = [[[SeaController utilitiesManager] toolboxUtilityFor:document] tool];
    
    if (curToolIndex == kCropTool) {
        [self drawCropBoundaries];
    }
    else {
        [self drawSelectBoundaries];
    }
}

- (void)drawCropBoundaries
{
    NSRect tempRect;
    IntRect cropRect;
    NSBezierPath *tempPath;
    float xScale, yScale;
    int width, height;
    
    xScale = [[document contents] xscale];
    yScale = [[document contents] yscale];
    width = [(SeaContent *)[document contents] width];
    height = [(SeaContent *)[document contents] height];
    cropRect = [[[document tools] currentTool] cropRect];
    if (cropRect.size.width == 0 || cropRect.size.height == 0)
        return;
    tempRect.origin.x = floor(cropRect.origin.x * xScale);
    tempRect.origin.y =  floor(cropRect.origin.y * yScale);
    tempRect.size.width = ceil(cropRect.size.width * xScale);
    tempRect.size.height = ceil(cropRect.size.height * yScale);
    [[[SeaController seaPrefs] selectionColor:0.4] set];
    tempPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, width * xScale + 1.0, height * yScale + 1.0)];
    [tempPath appendBezierPathWithRect:tempRect];
    [tempPath setWindingRule:NSEvenOddWindingRule];
    [tempPath fill];
    
    [self drawDragHandles: tempRect type: kCropHandleType];
}


- (void)drawSelectBoundaries
{
    float xScale, yScale;
    NSRect tempRect, srcRect;
    IntRect selectRect, tempSelectRect;
    int xoff, yoff, width, height, lwidth, lheight;
    BOOL useSelection, special, intermediate;
    int curToolIndex = (int)[(ToolboxUtility *)[(UtilitiesManager *)[SeaController utilitiesManager] toolboxUtilityFor:document] tool];
    AbstractTool* curTool = [[document tools] getTool: curToolIndex];
    NSBezierPath *tempPath;
    NSImage *maskImage;
    int radius = 0;
    float revCurveRadius, f;
    
    selectRect = [[document selection] globalRect];
    useSelection = [[document selection] active];
    xoff = [[[document contents] activeLayer] xoff];
    yoff = [[[document contents] activeLayer] yoff];
    width = [(SeaContent *)[document contents] width];
    height = [(SeaContent *)[document contents] height];
    lwidth = [(SeaLayer *)[[document contents] activeLayer] width];
    lheight = [(SeaLayer *)[[document contents] activeLayer] height];
    xScale = [[document contents] xscale];
    yScale = [[document contents] yscale];

    tempPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, width * xScale + 1.0, height * yScale + 1.0)];

    // First step is to draw the layer bounds
    tempRect = NSMakeRect(xoff, yoff, lwidth, lheight);
    tempRect.origin.x = floor(tempRect.origin.x * xScale);
    tempRect.origin.y =  floor(tempRect.origin.y * yScale);
    tempRect.size.width = ceil(tempRect.size.width * xScale);
    tempRect.size.height = ceil(tempRect.size.height * yScale);
    
    [tempPath appendBezierPathWithRect:tempRect];
    [tempPath setWindingRule:NSEvenOddWindingRule];

    if([[SeaController seaPrefs] layerBounds] && [[SeaController seaPrefs] whiteLayerBounds]){
        [[NSColor colorWithDeviceWhite:1.0 alpha:0.4] set];
        [tempPath fill];        
    }else if(useSelection || [[SeaController seaPrefs] layerBounds]){
        // If we are not drawing the layer bounds we should still draw the full selection boundaries
        [[[SeaController seaPrefs] selectionColor:0.4] set];
        [tempPath fill];
    }
    
    // Change colors to just selection now
    [[[SeaController seaPrefs] selectionColor:0.4] set];
    
    // The selection rectangle
    if (useSelection){
        tempPath = [NSBezierPath bezierPathWithRect:tempRect];
        tempRect = NSMakeRect(selectRect.origin.x, selectRect.origin.y, selectRect.size.width, selectRect.size.height);

        // Ensure we're drawing whole pixels, again
        tempRect.origin.x = floor(tempRect.origin.x * xScale);
        tempRect.origin.y =  floor(tempRect.origin.y * yScale);
        tempRect.size.width = ceil(tempRect.size.width * xScale);
        tempRect.size.height = ceil(tempRect.size.height * yScale);

        [tempPath appendBezierPathWithRect:tempRect];
        [tempPath setWindingRule:NSEvenOddWindingRule];
        [tempPath fill];
        
        // Draw the mask image
        maskImage = [[document selection] maskImage];
        srcRect.origin = IntPointMakeNSPoint([[document selection] maskOffset]);
        srcRect.size = IntSizeMakeNSSize(selectRect.size);
        [maskImage drawInRect:tempRect fromRect:srcRect operation:NSCompositeSourceOver fraction:0.4];

        // If the currently selected tool is a selection tool, draw the handles
        if(curToolIndex >= kFirstSelectionTool && curToolIndex <= kLastSelectionTool){
            [self drawDragHandles: tempRect type: kSelectionHandleType];
        }
    }
    
    // Get the data for drawing rounded rectangular selections
    special = NO;
    if (curToolIndex == kRectSelectTool) {
        radius = [(RectSelectOptions *)[[[SeaController utilitiesManager] optionsUtilityFor:document] currentOptions] radius];
        tempSelectRect = [(RectSelectTool *)curTool selectionRect];
        special = tempSelectRect.size.width < 2 * radius && tempSelectRect.size.height < 2 * radius;
    }
    
    // Check to see if the user is currently dragging a selection
    intermediate = NO;
    if(curToolIndex >= kFirstSelectionTool && curToolIndex <= kLastSelectionTool){
        intermediate =  [(AbstractScaleTool *)curTool intermediate] && ! [(AbstractScaleTool *)curTool isMovingOrScaling];
    }
    
    [cursorsManager setCloseRect:NSMakeRect(0, 0, 0, 0)];
    if ((intermediate && (curToolIndex == kEllipseSelectTool)) || special) {
        // The ellipse tool is currently being dragged, so draw its marching ants
        tempSelectRect = [(EllipseSelectTool *)curTool selectionRect];
        tempRect = IntRectMakeNSRect(tempSelectRect);
        tempRect.origin.x += xoff; tempRect.origin.y += yoff;
        tempRect.origin.x *= xScale; tempRect.origin.y *= yScale; tempRect.size.width *= xScale; tempRect.size.height *= yScale; 
        tempPath = [NSBezierPath bezierPathWithOvalInRect:tempRect];
        [[NSColor blackColor] set];
        [tempPath setLineDash: black count: 4 phase: 0.0];
        [tempPath stroke];
        [[NSColor whiteColor] set];
        [tempPath setLineDash: white count: 4 phase: 0.0];
        [tempPath stroke];
    }
    else if (curToolIndex == kRectSelectTool && intermediate) {
        
        // The rectangle tool is being dragged, so draw its marching ants
        tempSelectRect = [(RectSelectTool *)curTool selectionRect];
        tempRect = IntRectMakeNSRect(tempSelectRect);
        tempRect.origin.x += xoff; tempRect.origin.y += yoff;        
        tempRect.origin.x *= xScale; tempRect.origin.y *= yScale; tempRect.size.width *= xScale; tempRect.size.height *= yScale; 
        // The corners have a rounding
        if (radius) {
            f = (4.0 / 3.0) * (sqrt(2) - 1);
            
            if (tempSelectRect.size.width < 2 * radius) revCurveRadius = tempSelectRect.size.width / 2.0;
            else if (tempSelectRect.size.height < 2 * radius) revCurveRadius = tempSelectRect.size.height / 2.0;
            else revCurveRadius = radius;
            
            tempPath = [NSBezierPath bezierPath];
            [tempPath moveToPoint:NSMakePoint(tempRect.origin.x, tempRect.origin.y + revCurveRadius * yScale)];
            [tempPath curveToPoint:NSMakePoint(tempRect.origin.x + revCurveRadius * xScale, tempRect.origin.y) controlPoint1:NSMakePoint(tempRect.origin.x, tempRect.origin.y + (1.0 - f) * revCurveRadius * yScale) controlPoint2:NSMakePoint(tempRect.origin.x + (1.0 - f) * revCurveRadius * xScale, tempRect.origin.y)];
            [tempPath lineToPoint:NSMakePoint(tempRect.origin.x + tempRect.size.width - revCurveRadius * xScale, tempRect.origin.y)];
            [tempPath curveToPoint:NSMakePoint(tempRect.origin.x + tempRect.size.width, tempRect.origin.y + revCurveRadius * yScale) controlPoint1:NSMakePoint(tempRect.origin.x + tempRect.size.width - (1.0 - f) * revCurveRadius * xScale, tempRect.origin.y) controlPoint2:NSMakePoint(tempRect.origin.x + tempRect.size.width, tempRect.origin.y + (1.0 - f) * revCurveRadius * yScale)];
            [tempPath lineToPoint:NSMakePoint(tempRect.origin.x + tempRect.size.width, tempRect.origin.y + tempRect.size.height - revCurveRadius * yScale)];
            [tempPath curveToPoint:NSMakePoint(tempRect.origin.x + tempRect.size.width - revCurveRadius * xScale, tempRect.origin.y + tempRect.size.height) controlPoint1:NSMakePoint(tempRect.origin.x + tempRect.size.width, tempRect.origin.y + tempRect.size.height - (1.0 - f) * revCurveRadius * yScale) controlPoint2:NSMakePoint(tempRect.origin.x + tempRect.size.width - (1.0 - f) * revCurveRadius * xScale, tempRect.origin.y + tempRect.size.height)];
            [tempPath lineToPoint:NSMakePoint(tempRect.origin.x + revCurveRadius * xScale, tempRect.origin.y + tempRect.size.height)];
            [tempPath curveToPoint:NSMakePoint(tempRect.origin.x, tempRect.origin.y + tempRect.size.height - revCurveRadius * yScale) controlPoint1:NSMakePoint(tempRect.origin.x + (1.0 - f) * revCurveRadius * xScale, tempRect.origin.y + tempRect.size.height) controlPoint2:NSMakePoint(tempRect.origin.x, tempRect.origin.y + tempRect.size.height - (1.0 - f) * revCurveRadius * yScale)];
            [tempPath lineToPoint:NSMakePoint(tempRect.origin.x, tempRect.origin.y + revCurveRadius * yScale)];
        }
        else {
            // There are no rounded corners
            tempRect.origin.x += .5;
            tempRect.origin.y += .5;
            tempRect.size.width -= 1;
            tempRect.size.height -= 1;
            
            tempPath = [NSBezierPath bezierPathWithRect:tempRect];        
        }
        
        [[NSColor blackColor] set];
        [tempPath setLineDash: black count: 4 phase: 0.0];
        [tempPath stroke];
        [[NSColor whiteColor] set];
        [tempPath setLineDash: white count: 4 phase: 0.0];
        [tempPath stroke];
    }else if((curToolIndex == kLassoTool || curToolIndex == kPolygonLassoTool) && intermediate){
        // Finally, draw the marching ants for the lasso or polygon lasso tools
        tempPath = [NSBezierPath bezierPath];
        
        LassoPoints lassoPoints;
        NSPoint start;
        lassoPoints = [(LassoTool *)curTool currentPoints];
        start = NSMakePoint((lassoPoints.points[0].x + xoff) *xScale , (lassoPoints.points[0].y + yoff) * yScale );
    
        // Create a special start point for the polygonal lasso tool
        // This allows the user to close the polygon by just clicking 
        // near the first point in the polygon.
        if(curToolIndex == kPolygonLassoTool){
            [self drawHandle: start type:kPolygonalLassoType index: -1];
        }
        
        // It is now the job of the SeaView instead of the tool itself to draw the edges because
        // this way, the polygon can be persistent across view changes such as scrolling or resizing
        [tempPath moveToPoint:start];
        int i;
        for(i = 1; i <= lassoPoints.pos; i++){
            IntPoint thisPoint = lassoPoints.points[i];
            [tempPath lineToPoint:NSMakePoint((thisPoint.x + xoff) * xScale , (thisPoint.y + yoff) * yScale )];
        }
        
        [[NSColor blackColor] set];
        [tempPath setLineDash: black count: 4 phase: 0.0];
        [tempPath stroke];
        [[NSColor whiteColor] set];
        [tempPath setLineDash: white count: 4 phase: 0.0];
        [tempPath stroke];
    }
}

- (void)drawDragHandles:(NSRect) rect type: (int)type
{
    rect.origin.x -= 1;
    rect.origin.y -= 1;
    [self drawHandle: rect.origin type: type index: 0];
    rect.origin.x += rect.size.width / 2 + 1;
    [self drawHandle: rect.origin type: type index: 1];
    rect.origin.x += rect.size.width / 2 + 1;
    [self drawHandle: rect.origin type: type index: 2];
    rect.origin.y += rect.size.height / 2 + 1;
    [self drawHandle: rect.origin type: type index: 3];
    rect.origin.y += rect.size.height / 2 + 1;
    [self drawHandle: rect.origin type: type index: 4];
    rect.origin.x -= rect.size.width / 2 + 1;
    [self drawHandle: rect.origin type: type index: 5];
    rect.origin.x -= rect.size.width / 2 + 1;
    [self drawHandle: rect.origin type: type index: 6];
    rect.origin.y -= rect.size.height / 2 + 1;
    [self drawHandle: rect.origin type: type index: 7];
}

- (void)drawHandle:(NSPoint) origin  type: (int)type index:(int) index
{
    NSRect outside  = NSMakeRect(origin.x - 4,origin.y - 4,8,8);
    // This function is also used to set the appropriate cursor rects
    // The rectangles must be persistent because in the event loop, each view
    // has its cursor rects reset AFTER the view is drawn, so setting the rects
    // here would just have them immediately invalidated.
    NSRect *handleRects = [(SeaCursors *) cursorsManager handleRectsPointer];
    if(index >= 0)
        handleRects[index] = outside;
    
    NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect: outside];
    switch (type) {
        case kSelectionHandleType:
            [[NSColor whiteColor] set];
            break;
        case kLayerHandleType:
            [[NSColor whiteColor] set];
            break;
        case kCropHandleType:
            [[NSColor redColor] set];
            break;
        case kGradientStartType:
            [[NSColor whiteColor] set];
            break;
        case kGradientEndType:
            [[NSColor whiteColor] set];
            break;
        case kPolygonalLassoType:
            [[NSColor blackColor] set];
            [cursorsManager setCloseRect:outside];
            break;
        case kPositionType:
            [[(SeaPrefs *)[SeaController seaPrefs] guideColor: 1.0] set];
            outside = NSMakeRect(origin.x - 3, origin.y - 3, 6, 6);
            path = [NSBezierPath bezierPathWithRect:outside];
            break;
        default:
            NSLog(@"Handle type not understood.");
            break;
    }

    // The handle should have a subtle shadow so that it can be visible on background
    // where the color is the same as the inside and outside of the handle
    [NSGraphicsContext saveGraphicsState];
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowOffset: NSMakeSize(0, 0)];
    [shadow setShadowBlurRadius: 1];
    
    if(type == kPolygonalLassoType){
        // This handle has inverted colors to make it obvious
        [shadow setShadowColor:[NSColor whiteColor]];
    }else{
        [shadow setShadowColor:[NSColor blackColor]];
    }
    [shadow set];
    [path fill];

    [NSGraphicsContext restoreGraphicsState];

    NSRect inside  = NSMakeRect(origin.x - 3,origin.y - 3,6,6);
    path = [NSBezierPath bezierPathWithOvalInRect: inside];

    switch (type) {
        case kSelectionHandleType:
            [[(SeaPrefs *)[SeaController seaPrefs] selectionColor:1] set];
            break;
        case kCropHandleType:
            [[(SeaPrefs *)[SeaController seaPrefs] selectionColor:0.6] set];
            inside  = NSMakeRect(origin.x - 2.5,origin.y - 3,5.5,6);
            path = [NSBezierPath bezierPathWithOvalInRect: inside];
            break;
        case kLayerHandleType:
            [[NSColor cyanColor] set];
            break;
        case kGradientStartType:
            [[[document contents] foreground] set];
            break;
        case kGradientEndType:
            [[[document contents] background] set];
            break;
        case kPolygonalLassoType:
            [[NSColor whiteColor] set];
            break;
        case kPositionType:
            inside = NSMakeRect(origin.x - 2, origin.y - 2, 4, 4);
            path = [NSBezierPath bezierPathWithRect: inside];
            [[NSColor whiteColor] set];
            break;
        default:
            NSLog(@"Handle type not understood.");
            break;
    }
    [path fill];
    [[(SeaPrefs *)[SeaController seaPrefs] guideColor: 1.0] set];
}

- (void)drawExtras
{    
    int curToolIndex = [[[SeaController utilitiesManager] toolboxUtilityFor:document] tool];
    id cloneTool = [[document tools] getTool:kCloneTool];
    id effectTool = [[document tools] getTool:kEffectTool];
    NSPoint outPoint, hilightPoint;
    float xScale, yScale;
    int xoff, yoff, lwidth, lheight, i;
    NSBezierPath *tempPath;
    IntPoint sourcePoint;
    NSImage *crossImage;
    
    
    // Fill out various variables
    xoff = [[[document contents] activeLayer] xoff];
    yoff = [[[document contents] activeLayer] yoff];
    lwidth = [(SeaLayer *)[[document contents] activeLayer] width];
    lheight = [(SeaLayer *)[[document contents] activeLayer] height];
    xScale = [[document contents] xscale];
    yScale = [[document contents] yscale];

    tempPath = [NSBezierPath bezierPath];
    [tempPath setLineWidth:1.0];
    
    
    if([(SeaPrefs *)[SeaController seaPrefs] guides] && xScale > 2 && yScale > 2){
        [[NSColor colorWithCalibratedWhite:0.9 alpha:0.25] set];
        int i, j;
        
        for(i = 0; i < [self frame].size.width / xScale; i++){
            [tempPath moveToPoint:NSMakePoint(xScale * i - 0.5, 0)];
            [tempPath lineToPoint:NSMakePoint(xScale * i - 0.5, [self frame].size.height)];
        }
        
        for(j = 0; j < [self frame].size.height / yScale; j++){
            [tempPath moveToPoint:NSMakePoint(0, yScale * j - 0.5)];
            [tempPath lineToPoint:NSMakePoint([self frame].size.width, yScale *j - 0.5)];
        }        
        [tempPath stroke];
        [[NSColor colorWithCalibratedWhite:0.5 alpha:0.25] set];

        for(i = 0; i < [self frame].size.width / xScale; i++){
            [tempPath moveToPoint:NSMakePoint(xScale * i + 0.5, 0)];
            [tempPath lineToPoint:NSMakePoint(xScale * i + 0.5, [self frame].size.height)];
        }
        
        for(j = 0; j < [self frame].size.height / yScale; j++){
            [tempPath moveToPoint:NSMakePoint(0, yScale * j + 0.5)];
            [tempPath lineToPoint:NSMakePoint([self frame].size.width, yScale *j + 0.5)];
        }        
        [tempPath stroke];
        
    
    }
    
    if(curToolIndex == kPositionTool && [(SeaPrefs *)[SeaController seaPrefs] guides]){
        float radians = 0.0;
        id positionTool = [[document tools] getTool:kPositionTool];

        // The position tool now has guides (which the user can turn on or off)
        // This makes it easy to see the dimensions and the boundaries of the moved layer
        // or selection, even when there is currently an active selection.
        xoff *= xScale;
        lwidth *= xScale;
        yoff *= yScale;
        lheight *= yScale;
        
        [[(SeaPrefs *)[SeaController seaPrefs] guideColor: 1.0] set];
        
        if([positionTool intermediate]){
            IntRect postScaledRect = [positionTool postScaledRect];
            xoff = postScaledRect.origin.x;
            yoff = postScaledRect.origin.y;
            lwidth = postScaledRect.size.width;
            lheight = postScaledRect.size.height;
        }
            
        [self drawDragHandles:NSMakeRect(xoff, yoff, lwidth, lheight) type:kPositionType];
        
        NSPoint centerPoint = NSMakePoint(xoff + lwidth / 2, yoff + lheight / 2);
        // Additionally, the new guides are directly proportional to the amount of rotation or 
        // of scaling done by the layer if these modifiers are used.
        if ([(PositionTool *)positionTool scale] != -1) {
            float scale = [(PositionTool *)positionTool scale];
            lwidth *= scale;
            lheight *= scale;
            xoff = centerPoint.x - lwidth / 2;
            yoff = centerPoint.y - lheight / 2;
        }else if([(PositionTool *)positionTool rotationDefined]){
            radians = [(PositionTool *)positionTool rotation];
        }
        
        // All of the silliness with the 0.5's is because when drawing with Bezier paths
        // the coordinates are at vertices between the pixels, not centered on them.
        [tempPath moveToPoint:NSPointRotateNSPoint(NSMakePoint(xoff + 0.5, yoff +0.5), centerPoint, radians)];
        [tempPath lineToPoint:NSPointRotateNSPoint(NSMakePoint(xoff + lwidth - 0.5, yoff +0.5), centerPoint, radians)];
        [tempPath lineToPoint:NSPointRotateNSPoint(NSMakePoint(xoff+lwidth -0.5, yoff+ lheight -0.5), centerPoint, radians)];
        [tempPath lineToPoint:NSPointRotateNSPoint(NSMakePoint(xoff +0.5, yoff+ lheight -0.5), centerPoint, radians)];
        [tempPath lineToPoint:NSPointRotateNSPoint(NSMakePoint(xoff+0.5, yoff +0.5), centerPoint, radians)];
        
        // In addition to the 4 sides, there are guides that divide the rectangle into thirds.
        // This is better than halves because that way scaling is visible
        [tempPath moveToPoint:NSPointRotateNSPoint(NSMakePoint(floor(xoff + lwidth / 3) + 0.5, yoff), centerPoint, radians)];
        [tempPath lineToPoint:NSPointRotateNSPoint(NSMakePoint(floor(xoff + lwidth / 3) + 0.5, yoff + lheight), centerPoint, radians)];
        [tempPath moveToPoint:NSPointRotateNSPoint(NSMakePoint(ceil(xoff + 2 * lwidth / 3) - 0.5, yoff + lheight), centerPoint, radians)];
        [tempPath lineToPoint:NSPointRotateNSPoint(NSMakePoint(ceil(xoff + 2 * lwidth / 3) - 0.5, yoff), centerPoint, radians)];
        
        [tempPath moveToPoint:NSPointRotateNSPoint(NSMakePoint(xoff, floor(yoff + lheight / 3) + 0.5), centerPoint, radians)];
        [tempPath lineToPoint:NSPointRotateNSPoint(NSMakePoint(xoff + lwidth, floor(yoff + lheight / 3) + 0.5), centerPoint, radians)];
        [tempPath moveToPoint:NSPointRotateNSPoint(NSMakePoint(xoff, ceil(yoff + 2* lheight / 3) -0.5), centerPoint, radians)];
        [tempPath lineToPoint:NSPointRotateNSPoint(NSMakePoint(xoff + lwidth, ceil(yoff + 2* lheight / 3) - 0.5), centerPoint, radians)];

        [tempPath stroke];

    }else if(curToolIndex == kCloneTool){
        // Draw source point
        if ([cloneTool sourceSetting]) {
            sourcePoint = [cloneTool sourcePoint:NO];
            crossImage = [NSImage imageNamed:@"cross"];
            outPoint = IntPointMakeNSPoint(sourcePoint);
            outPoint.x *= xScale;
            outPoint.y *= yScale;
            outPoint.x -= 12;
            outPoint.y -= 10;
            outPoint.y += 26;
            [crossImage compositeToPoint:outPoint operation:NSCompositeSourceOver fraction:(float)[cloneTool sourceSetting] / 100.0];
        }
    }else if (curToolIndex == kEffectTool){
        // Draw effect tool dots
        for (i = 0; i < [(EffectTool*)effectTool clickCount]; i++) {
            [[[SeaController seaPrefs] selectionColor:0.6] set];
            hilightPoint = IntPointMakeNSPoint([effectTool point:i]);
            tempPath = [NSBezierPath bezierPath];
            [tempPath moveToPoint:NSMakePoint((hilightPoint.x + xoff) * xScale - 4, (hilightPoint.y + yoff) * yScale + 4)];
            [tempPath lineToPoint:NSMakePoint((hilightPoint.x + xoff) * xScale + 4, (hilightPoint.y + yoff) * yScale - 4)];
            [tempPath moveToPoint:NSMakePoint((hilightPoint.x + xoff) * xScale + 4, (hilightPoint.y + yoff) * yScale + 4)];
            [tempPath lineToPoint:NSMakePoint((hilightPoint.x + xoff) * xScale - 4, (hilightPoint.y + yoff) * yScale - 4)];
            [tempPath setLineWidth:2.0];
            [tempPath stroke];
        }
    }else if (curToolIndex == kGradientTool) {
        GradientTool *tool = [[document tools] getTool:kGradientTool];
        
        if([tool intermediate]){
            // Draw the connecting line
            [[(SeaPrefs *)[SeaController seaPrefs] guideColor: 1.0] set];

            tempPath = [NSBezierPath bezierPath];
            [tempPath setLineWidth:1.0];
            [tempPath moveToPoint:[tool start]];
            [tempPath lineToPoint:[tool current]];
            [tempPath stroke];
            
            // The handles are the appropriate color of the gradient.
            [self drawHandle:[tool start] type:kGradientStartType index: -1];
            [self drawHandle:[tool current] type:kGradientEndType index: -1];
        }
    }else if (curToolIndex == kWandTool || curToolIndex == kBucketTool){
        WandTool *tool = [[document tools] getTool: curToolIndex];
        if([tool intermediate] && (curToolIndex == kBucketTool || ![tool isMovingOrScaling])){
            // Draw the connecting line
            [[(SeaPrefs *)[SeaController seaPrefs] guideColor: 1.0] set];

            tempPath = [NSBezierPath bezierPath];
            [tempPath setLineWidth:1.0];
            [tempPath moveToPoint:[tool start]];
            [tempPath lineToPoint:[tool current]];
            [tempPath stroke];
            
            [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect([tool start].x - 3, [tool start].y-3, 6,6)] fill];
            [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect([tool current].x - 3, [tool current].y-3, 6,6)] fill];
             
        }
    }
}

- (void)checkMouseTracking
{
    if ([[self window] isMainWindow]) {
        if ([[document scrollView] rulersVisible] || [[[SeaController utilitiesManager] infoUtilityFor:document] visible])
            [[self window] setAcceptsMouseMovedEvents:YES];
        else
            [[self window] setAcceptsMouseMovedEvents:NO];
    }
}

- (void)updateRulerMarkings:(NSPoint)mouseLocation andStationary:(NSPoint)statLocation
{
    NSPoint markersLocation, statMarkersLocation;
    
    // Only make a change if it has been more than 0.03 seconds
    if ([[NSDate date] timeIntervalSinceDate:lastRulerUpdate] > 0.03) {
    
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

- (void)mouseMoved:(NSEvent *)theEvent
{
    if ([[[SeaController utilitiesManager] infoUtilityFor:document] visible]) [[[SeaController utilitiesManager] infoUtilityFor:document] update];
    if ([[document scrollView] rulersVisible]) [self updateRulerMarkings:[theEvent locationInWindow] andStationary:NSMakePoint(-256e6, -256e6)];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    unsigned int mods;
    NSPoint globalPoint;
    
    // Check for zoom-in or zoom-out
    mods = [theEvent modifierFlags];
    if ((mods & NSAlternateKeyMask) >> 19) {
        globalPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
        if (scrollZoom - lastTrigger > 10.0) {
            lastTrigger = scrollZoom;
            [self zoomInToPoint:globalPoint];
        }
        else if (scrollZoom - lastTrigger < -10.0) {
            lastTrigger = scrollZoom;
            [self zoomOutFromPoint:globalPoint];
        }
        scrollZoom += ([theEvent deltaY] > 0.0) ? 1.0 : -1.0;
    }
    else {
        [super scrollWheel:theEvent];
    }
}

- (void)readjust:(BOOL)scaling
{
    NSPoint point = [(CenteringClipView *)[self superview] centerPoint];
    NSRect frame;
    
    // Readjust the frame
    frame = NSMakeRect(0, 0, [(SeaContent *)[document contents] width], [(SeaContent *)[document contents] height]);
    if (gScreenResolution.x != 0 && [[document contents] xres] != gScreenResolution.x) frame.size.width /= ((float)[[document contents] xres] / gScreenResolution.x);
    if (gScreenResolution.y != 0 && [[document contents] yres] != gScreenResolution.y) frame.size.height /= ((float)[[document contents] yres] / gScreenResolution.y);
    frame.size.height *= zoom; frame.size.width *= zoom;
    if (scaling) {
        point.x *= frame.size.width / [self frame].size.width;
        point.y *= frame.size.height / [self frame].size.height;
    }
    [self setFrame:frame];
    [(CenteringClipView *)[self superview] setCenterPoint:point];
    [self setNeedsDisplay:YES];
}

- (void)tabletProximity:(NSEvent *)theEvent
{
    tabletEraser = 0;
    if ([theEvent isEnteringProximity] && [theEvent pointingDeviceType] == NSEraserPointingDevice) {
        tabletEraser = 2;
    }
}

- (void)tabletPoint:(NSEvent *)theEvent
{
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    [self mouseDown:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    float xScale, yScale;
    id curTool;
    IntPoint localActiveLayerPoint;
    NSPoint localPoint, globalPoint;
    int curToolIndex = [[[SeaController utilitiesManager] toolboxUtilityFor:document] tool];
    id options = [[[SeaController utilitiesManager] optionsUtilityFor:document] currentOptions];
    
    // Get xScale, yScale    
    xScale = [[document contents] xscale];
    yScale = [[document contents] yscale];
    
    // Check if we are in scrolling mode
    if (scrollingMode) {
        [cursorsManager setScrollingMode: YES mouseDown:YES];
        [self needsCursorsReset];
        lastScrollPoint = [theEvent locationInWindow];
        return;
    }
    

    /* else if(curToolIndex == kCropTool || curToolIndex == kPositionTool) {
        IntRect localRect;
        if(curToolIndex == kCropTool){
            CropTool *tool = [[document tools] getTool:kCropTool];
            localRect = [tool cropRect];
        }else {
            localRect = [[[document contents] activeLayer] localRect];
        }

        scalingDir = [self point: [self convertPoint:[theEvent locationInWindow] fromView:NULL] isInHandleFor: localRect];
        if(scalingDir >= 0){
            if(curToolIndex == kCropTool){
                scalingMode = kCropScalingMode;
            }else {
                scalingMode = kPositionScalingMode;
            }

            preScaledRect = localRect;
            preScaledMask = NULL;
            return;
        }
    }     */
    
    // Check if it is a line draw
    if (lineDraw) {
        [self mouseDragged:theEvent];
        return;
    }
    
    // Get the current tool
    curTool = [[document tools] currentTool];
    
    // Calculate the localPoint and localActiveLayerPoint
    mouseDownLoc = [theEvent locationInWindow];
    globalPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
    localPoint.x = globalPoint.x / xScale;
    localPoint.y = globalPoint.y / yScale;
    localActiveLayerPoint.x = localPoint.x - [[[document contents] activeLayer] xoff];
    localActiveLayerPoint.y = localPoint.y - [[[document contents] activeLayer] yoff];
    
    // Turn mouse coalescing on or off
    if ([curTool useMouseCoalescing] || [(SeaPrefs *)[SeaController seaPrefs] mouseCoalescing] || scrollingMode){
        SetMouseCoalescingEnabled(true, NULL);
    }else{
        SetMouseCoalescingEnabled(false, NULL);
    }
    
    if (tabletEraser < 2) {
        tabletEraser = 0;
        if ([theEvent subtype] == NSTabletProximityEventSubtype) {
            if ([theEvent pointingDeviceType] == NSEraserPointingDevice) {
                tabletEraser = 1;
            }
        }
    }
    
    // Reset the deltas
    delta = IntMakePoint(0,0);
    initialPoint = NSPointMakeIntPoint(localPoint);
    
    // Determine special value
    if (([theEvent buttonNumber] == 1) || tabletEraser) {
        [options forceAlt];
    }
    
    // Run the event
    [document lock];
    if (curToolIndex == kZoomTool) {
        if ([(AbstractOptions*)options modifier] == kAltModifier) {
            if ([self canZoomOut])
                [self zoomOutFromPoint:globalPoint];
            else
                NSBeep();
        }
        else {
            if ([self canZoomIn])
                [self zoomInToPoint:globalPoint];
            else
                NSBeep();
        }
    }
    else if ([curTool isFineTool]) {
        [curTool fineMouseDownAt:localPoint withEvent:theEvent];
    }
    else {
        [curTool mouseDownAt:localActiveLayerPoint withEvent:theEvent];
    }
    lastActiveLayerPoint = localActiveLayerPoint;
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
    [self mouseDragged:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    float xScale, yScale;
    id curTool;
    IntPoint localActiveLayerPoint;
    NSPoint localPoint;
    int curToolIndex, deltaX, deltaY;
    double angle;
    NSPoint origin, newScrollPoint;
    NSClipView *view;
    id options = [[[SeaController utilitiesManager] optionsUtilityFor:document] currentOptions];
    
    NSRect visRect = [(NSClipView *)[self superview] documentVisibleRect];
    localPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
    
    /* When the user drags the mouse out of the currently visible view rect, they expect it to 
    scroll, probably proportionally to the distance they are outside of the view. Thus we need to
    calculate if we're outside of the view, and the scroll the view by that much.*/
    
    // Cancel any previous scroll options
    if(scrollTimer){
        [scrollTimer invalidate];
        scrollTimer = NULL;
    }
    
    float horzScroll = 0;
    float rightVis = visRect.origin.x + visRect.size.width;
    float rightAct = [(SeaContent *)[document contents] width] * [[document contents] xscale];
    if(localPoint.x < visRect.origin.x){
        horzScroll = localPoint.x - visRect.origin.x;
        // This is so users don't scroll past the beginning
        if(-1 * horzScroll > visRect.origin.x){
            horzScroll = visRect.origin.x < 0 ? 0 : -1 * visRect.origin.x;
        }
    }else if(localPoint.x > rightVis){
        horzScroll = localPoint.x - rightVis;
        // And this is so users don't scroll past the end
        if(horzScroll > rightAct - rightVis){
            horzScroll = rightVis > rightAct ? 0 : rightAct - rightVis;
        }
    }
    
    
    float vertScroll = 0;
    float botVis = visRect.origin.y + visRect.size.height;
    float botAct = [(SeaContent *)[document contents] height] * [[document contents] yscale];
    if(localPoint.y < visRect.origin.y){
        vertScroll = localPoint.y - visRect.origin.y;
        // This is so users don't scroll past the beginning
        if(-1 *vertScroll > visRect.origin.y){
            vertScroll = visRect.origin.y < 0 ? 0 : -1 * visRect.origin.y;
        }
    }else if(localPoint.y > botVis){
        vertScroll = localPoint.y - botVis;
        // And this is so users don't scroll past the end
        if(vertScroll > botAct - botVis){
            vertScroll = botVis > botAct ? 0 : botAct - botVis;
        }
    }
    
    // We will want the document to continue to scroll even if the user isn't sending mouse events
    // This means there needs to be some sort of timer to call the method automatically
    if(horzScroll != 0 || vertScroll != 0){
        //NSDictionary *uInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:horzScroll], @"x", [NSNumber numberWithFloat:vertScroll], @"y", nil];
        NSClipView *view = (NSClipView *)[self superview];
        NSPoint origin =  [view documentVisibleRect].origin;
        origin.x += horzScroll;
        origin.y += vertScroll;
        [view scrollToPoint:[view constrainScrollPoint:origin]];
        [(NSScrollView *)[view superview] reflectScrolledClipView:view];
        
        //scrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target: self selector:@selector(autoScroll:) userInfo: theEvent repeats: YES];
    }
    
    // Check if we are in manual scrolling mode
    if (scrollingMode) {
        newScrollPoint = [theEvent locationInWindow];
        view = (NSClipView *)[self superview];
        origin = visRect.origin;
        origin.x -= (newScrollPoint.x - lastScrollPoint.x) * 2;
        origin.y += (newScrollPoint.y - lastScrollPoint.y) * 2;
        [view scrollToPoint:[view constrainScrollPoint:origin]];
        [(NSScrollView *)[view superview] reflectScrolledClipView:view];
        lastScrollPoint = newScrollPoint;
        return;
    }
    
    // Set up tools
    curTool = [[document tools] currentTool];
    curToolIndex = [[[SeaController utilitiesManager] toolboxUtilityFor:document] tool];
    
    // Calculate the localPoint and localActiveLayerPoint
    xScale = [[document contents] xscale];
    yScale = [[document contents] yscale];
    localPoint.x /= xScale;
    localPoint.y /= yScale;    
    localActiveLayerPoint.x = localPoint.x - [[[document contents] activeLayer] xoff];
    localActiveLayerPoint.y = localPoint.y - [[[document contents] activeLayer] yoff];
    
    // Snap to 45 degree intervals if requested
    deltaX = localActiveLayerPoint.x - lastActiveLayerPoint.x;
    deltaY = localActiveLayerPoint.y - lastActiveLayerPoint.y;
    if (lineDraw && ([(AbstractOptions*)options modifier] == kShiftControlModifier) && deltaX != 0) {
        angle = atan((double)deltaY / (double)abs(deltaX));
        if (angle > -0.3927 && angle < 0.3927)
            localActiveLayerPoint.y = lastActiveLayerPoint.y;
        else if (angle > 1.1781 || angle < -1.1781)
            localActiveLayerPoint.x = lastActiveLayerPoint.x;
        else if (angle > 0.0)
            localActiveLayerPoint.y = lastActiveLayerPoint.y + abs(deltaX);
        else 
            localActiveLayerPoint.y = lastActiveLayerPoint.y - abs(deltaX);
    }
    
    // Determine the delta
    delta.x = localPoint.x - initialPoint.x;
    delta.y = localPoint.y - initialPoint.y;

    // Behave differently depending on current tool
    if ([curTool isFineTool]) {
        [(AbstractTool *)curTool fineMouseDraggedTo:localPoint withEvent:theEvent];
    }
    else {
        [(AbstractTool *)curTool mouseDraggedTo:localActiveLayerPoint withEvent:theEvent];
    }
    lastActiveLayerPoint = localActiveLayerPoint;
    lineDraw = NO;
    
    // Update the info utility
    if ([[[SeaController utilitiesManager] infoUtilityFor:document] visible]) [[[SeaController utilitiesManager] infoUtilityFor:document] update];
    if ([[document scrollView] rulersVisible]) [self updateRulerMarkings:[theEvent locationInWindow] andStationary:mouseDownLoc];
}


- (void)rightMouseUp:(NSEvent *)theEvent
{
    [self mouseUp:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    float xScale, yScale;
    id curTool = [[document tools] currentTool];
    NSPoint localPoint;
    IntPoint localActiveLayerPoint;
    AbstractOptions *options = [[[SeaController utilitiesManager] optionsUtilityFor:document] currentOptions];
    
    // Get xScale, yScale
    xScale = [[document contents] xscale];
    yScale = [[document contents] yscale];
    
    // Return to normal coalescing
    SetMouseCoalescingEnabled(true, NULL);
    
    // Check if we are in scrolling mode
    if (scrollingMode) {
        [cursorsManager setScrollingMode: YES mouseDown: NO];
        [self needsCursorsReset];
        return;
    }
    
    // Check if it is a line draw
    if ([curTool acceptsLineDraws] && ([(AbstractOptions*)options modifier] == kShiftModifier || [options modifier] == kShiftControlModifier)) {
        lineDraw = YES;
        return;
    }

    // Calculate the localPoint and localActiveLayerPoint
    mouseDownLoc = NSMakePoint(-256e6, -256e6);
    localPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
    localPoint.x /= xScale;
    localPoint.y /= yScale;
    localActiveLayerPoint.x = localPoint.x - [[[document contents] activeLayer] xoff];
    localActiveLayerPoint.y = localPoint.y - [[[document contents] activeLayer] yoff];
    
    // First treat this as an ordinary drag
    [self mouseDragged:theEvent];
    
    // Reset the delta
    delta = IntMakePoint(0,0);

    // Run the event
    [document unlock];
    if ([curTool isFineTool]) {
        [curTool fineMouseUpAt:localPoint withEvent:theEvent];
    }
    else {
        [curTool mouseUpAt:localActiveLayerPoint withEvent:theEvent];
    }
    
    // Unforce alt
    [options unforceAlt];
}

- (IntPoint)delta
{
    return delta;
}

- (void)flagsChanged:(NSEvent *)theEvent
{
    [(AbstractOptions *)[[[SeaController utilitiesManager] optionsUtilityFor:document] currentOptions] updateModifiers:[theEvent modifierFlags]];
    [[document helpers] endLineDrawing];
}

- (void)keyDown:(NSEvent *)theEvent
{
    int whichKey, whichLayer, xoff, yoff;
    id curLayer, activeLayer;
    IntPoint oldOffsets;
    unichar key;
    unsigned int mods;
    int curToolIndex = [[[SeaController utilitiesManager] toolboxUtilityFor:document] tool];
    BOOL floating = [[document selection] floating];
    
    // End the line drawing
    [[document helpers] endLineDrawing];
    
    // Check for zoom-in or zoom-out
    mods = [theEvent modifierFlags];
    if ((mods & NSCommandKeyMask) >> 20) {
        for (whichKey = 0; whichKey < [[theEvent characters] length]; whichKey++) {
            key = [[theEvent charactersIgnoringModifiers] characterAtIndex:whichKey];
            if (key == NSUpArrowFunctionKey)
                [self zoomIn:NULL];
            else if (key == NSDownArrowFunctionKey)
                [self zoomOut:NULL];
        }
    }
    
    // Don't do anything if a modifier is down
    // Actually, we may want to do something with the option key
    if (((mods & NSControlKeyMask) >> 18) || ((mods & NSCommandKeyMask) >> 20))
        return;
    
    // Go through all keys
    for (whichKey = 0; whichKey < [[theEvent characters] length]; whichKey++) {
    
        // Find the key
        key = [[theEvent charactersIgnoringModifiers] characterAtIndex:whichKey];
        
        // For arrow nudging
        if (key == NSUpArrowFunctionKey || key == NSDownArrowFunctionKey || key == NSLeftArrowFunctionKey || key == NSRightArrowFunctionKey) {
            int nudge = ((mods & NSAlternateKeyMask) >> 19) ? 10 : 1;
            // Get the active layer
            activeLayer = [[document contents] activeLayer];
        
            // Undo to the old position
            if (keyWasUp) {
            
                // If the active layer is linked we have to move all associated layers
                if ([activeLayer linked]) {
                
                    // Go through all linked layers allowing a satisfactory undo
                    for (whichLayer = 0; whichLayer < [[document contents] layerCount]; whichLayer++) {
                        curLayer = [[document contents] layer:whichLayer];
                        if ([curLayer linked]) {
                            oldOffsets.x = [curLayer xoff]; oldOffsets.y = [curLayer yoff];
                            [[[document undoManager] prepareWithInvocationTarget:[[document tools] getTool:kPositionTool]] undoToOrigin:oldOffsets forLayer:whichLayer];            
                        }
                    }
                    
                }
                else {
                    oldOffsets.x = [activeLayer xoff]; oldOffsets.y = [activeLayer yoff];
                    [[[document undoManager] prepareWithInvocationTarget:[[document tools] getTool:kPositionTool]] undoToOrigin:oldOffsets forLayer:[[document contents] activeLayerIndex]];
                }
                keyWasUp = NO;
                
            }
            
            // If there is a selection active move the selection otherwise move the layer
            if (curToolIndex == kCropTool) {
            
                // Make the adjustment
                switch (key) {
                    case NSUpArrowFunctionKey:
                        [[[document tools] currentTool] adjustCrop:IntMakePoint(0, -1 * nudge)];
                    break;
                    case NSDownArrowFunctionKey:
                        [[[document tools] currentTool] adjustCrop:IntMakePoint(0, nudge)];
                    break;
                    case NSLeftArrowFunctionKey:
                        [[[document tools] currentTool] adjustCrop:IntMakePoint(-1 * nudge, 0)];
                    break;
                    case NSRightArrowFunctionKey:
                        [[[document tools] currentTool] adjustCrop:IntMakePoint(nudge, 0)];
                    break;
                }
                
            
            }
            else if ([[document selection] active] && ![[document selection] floating]) {
            
                // Make the adjustment
                switch (key) {
                    case NSUpArrowFunctionKey:
                        [[document selection] adjustOffset:IntMakePoint(0, -1 * nudge)];
                    break;
                    case NSDownArrowFunctionKey:
                        [[document selection] adjustOffset:IntMakePoint(0, nudge)];
                    break;
                    case NSLeftArrowFunctionKey:
                        [[document selection] adjustOffset:IntMakePoint(-1 * nudge, 0)];
                    break;
                    case NSRightArrowFunctionKey:
                        [[document selection] adjustOffset:IntMakePoint(nudge, 0)];
                    break;
                }
                
                // Advise the change has taken place
                [[document helpers] selectionChanged];
            
            }
            else {
            
                // If the active layer is linked we have to move all associated layers
                if ([activeLayer linked]) {
                
                    // Move all of the linked layers
                    for (whichLayer = 0; whichLayer < [[document contents] layerCount]; whichLayer++) {
                        curLayer = [[document contents] layer:whichLayer];
                        if ([curLayer linked]) {
                        
                            // Get the old position
                            xoff = [curLayer xoff]; yoff = [curLayer yoff];
                            
                            // Make the adjustment
                            switch (key) {
                                case NSUpArrowFunctionKey:
                                    [curLayer setOffsets:IntMakePoint(xoff, yoff - nudge)];
                                break;
                                case NSDownArrowFunctionKey:
                                    [curLayer setOffsets:IntMakePoint(xoff, yoff + nudge)];
                                break;
                                case NSLeftArrowFunctionKey:
                                    [curLayer setOffsets:IntMakePoint(xoff - nudge, yoff)];
                                break;
                                case NSRightArrowFunctionKey:
                                    [curLayer setOffsets:IntMakePoint(xoff + nudge, yoff)];
                                break;
                            }
                            
                        }
                    }
                    oldOffsets.x = [activeLayer xoff]; oldOffsets.y = [activeLayer yoff];
                    [[document helpers] layerOffsetsChanged:kLinkedLayers from:oldOffsets];
                    
                }
                else {
                
                    // Get the old position
                    xoff = [activeLayer xoff]; yoff = [activeLayer yoff];
                
                    // Make the adjustment
                    switch (key) {
                        case NSUpArrowFunctionKey:
                            [activeLayer setOffsets:IntMakePoint(xoff, yoff - nudge)];
                        break;
                        case NSDownArrowFunctionKey:
                            [activeLayer setOffsets:IntMakePoint(xoff, yoff + nudge)];
                        break;
                        case NSLeftArrowFunctionKey:
                            [activeLayer setOffsets:IntMakePoint(xoff - nudge, yoff)];
                        break;
                        case NSRightArrowFunctionKey:
                            [activeLayer setOffsets:IntMakePoint(xoff + nudge, yoff)];
                        break;
                    }
                    
                    // Advise the change has taken place
                    oldOffsets = IntMakePoint(xoff, yoff);
                    [[document helpers] layerOffsetsChanged:kActiveLayer from:oldOffsets];
                    
                }
            
            }
            
        }
        
        // No repeat keys
        if (![theEvent isARepeat]) {
            
            // For window configurations and keyboard shortcuts
            switch (key) {
                case kDeleteCharCode:
                    [self delete:NULL];
                break;
                case kEscapeCharCode:
                    if(curToolIndex >= kFirstSelectionTool && curToolIndex <= kLastSelectionTool && [[[document tools] currentTool] intermediate])
                        [[[document tools] currentTool] cancelSelection];
                    else
                        [[document selection] clearSelection];
                break;
                case '`':
                    if ([[document selection] active] && ![[document selection] floating]) {
                        [self selectInverse:NULL];
                    }
                break;
                case 'm':
                    if (!floating) {
                        if ([[[SeaController utilitiesManager] toolboxUtilityFor:document] tool] == kRectSelectTool)
                            [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kEllipseSelectTool];
                        else
                            [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kRectSelectTool];
                    }
                break;
                case 'l':
                    if (!floating) {
                        if ([[[SeaController utilitiesManager] toolboxUtilityFor:document] tool] == kLassoTool)
                            [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kPolygonLassoTool];
                        else
                            [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kLassoTool];
                    }
                break;
                case 'w':
                    if (!floating) {
                        [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kWandTool];
                    }
                break;
                case 'b':
                    if ([[[SeaController utilitiesManager] toolboxUtilityFor:document] tool] == kBrushTool)
                        [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kPencilTool];
                    else
                        [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kBrushTool];
                break;
                case 'g':
                    if ([[[SeaController utilitiesManager] toolboxUtilityFor:document] tool] == kBucketTool)
                        [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kGradientTool];
                    else
                        [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kBucketTool];
                break;
                case 't':
                    [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kTextTool];
                break;
                case 'e':
                    [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kEraserTool];
                break;
                case 'i':
                    [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kEyedropTool];
                break;
                case 'o':
                    if ([[[SeaController utilitiesManager] toolboxUtilityFor:document] tool] == kSmudgeTool)
                        [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kEffectTool];
                    else
                        [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kSmudgeTool];
                break;
                case 's':
                    [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kCloneTool];
                break;
                case 'c':
                    [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kCropTool];
                break;
                case 'z':
                    [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kZoomTool];
                break;
                case 'v':
                    [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kPositionTool];
                break;
                case 'x':
                    [[[[SeaController utilitiesManager] toolboxUtilityFor:document] colorView] swapColors: self];
                break;
                case 'd':
                    [[[[SeaController utilitiesManager] toolboxUtilityFor:document] colorView] defaultColors: self];
                break;
                case '\t':
                    eyedropToolMemory = [[[SeaController utilitiesManager] toolboxUtilityFor:document] tool];
                    [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kEyedropTool];
                break;
                case '\r':
                case kEnterCharCode:
                    [[document warnings] keyTriggered];
                break;
            }

            // Activate scrolling mode
            if (key == ' ' && ![document locked]) {
                scrollingMode = YES;
                [cursorsManager setScrollingMode: YES mouseDown: NO];
                [self needsCursorsReset];
            }
            
        }
        
    }
}

- (void)keyUp:(NSEvent *)theEvent
{
    int whichKey;
    unichar key;
    
    // Go through all keys
    for (whichKey = 0; whichKey < [[theEvent characters] length]; whichKey++) {
    
        // Find the key
        key = [[theEvent charactersIgnoringModifiers] characterAtIndex:whichKey];
            
        // Deactivate scrolling mode
        switch (key) {
            case ' ':
                scrollingMode = NO;
                [cursorsManager setScrollingMode: NO mouseDown: NO];
                [self needsCursorsReset];
            break;
            case '\t':
                [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:eyedropToolMemory];
            break;
        }
    
    }
    
    keyWasUp = YES;
}

- (void)autoScroll:(NSTimer *)theTimer
{
    // The point of autoscrolling is that we simulate another mouse event
    // outside of the bounds, but that we're moving the viewport to keep
    // that even inside what the user sees.
    [self mouseDragged:[theTimer userInfo]];
}

- (void)clearScrollingMode
{
    scrollingMode = NO;
    [cursorsManager setScrollingMode: NO mouseDown: NO];
    [self needsCursorsReset];
}

- (void)magnifyWithEvent:(NSEvent *)event
{
    if(magnifyTimer){
        [magnifyTimer invalidate];
        magnifyTimer = NULL;
    }
    
    float factor = ((float)[event magnification] + 1.0);
    magnifyFactor = factor * magnifyFactor;
    magnifyTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                   target: self
                                                 selector:@selector(clearMagnifySum:)
                                                 userInfo: event
                                                  repeats: NO];
}

- (void)swipeWithEvent:(NSEvent *)event {
    float x = [event deltaX];
    float y = [event deltaY];
    if (x > 0) {
        [[document contents] layerBelow];
    }else if (x < 0) {
        [[document contents] layerAbove];
    }else if (y < 0) {
        [[document contents] anchorSelection];
    }else if (y > 0) {
        unsigned int mods = [event modifierFlags];
        [[document contents] makeSelectionFloat:(mods & NSAlternateKeyMask) >> 19];
    }
}

- (void)clearMagnifySum:(NSTimer *)theTimer
{
    if(magnifyTimer){
        [magnifyTimer invalidate];
        magnifyTimer = NULL;
    }
    
    if(magnifyFactor >= 2){
        [self zoomIn:self];
    }else if (magnifyFactor <= 0.5) {
        [self zoomOut:self];
    }
    
    magnifyFactor = 1.0;
}

- (IBAction)cut:(id)sender
{
    [[document selection] cutSelection];
}

- (IBAction)copy:(id)sender
{
    [[document selection] copySelection];
}

- (IBAction)paste:(id)sender
{
    if ([[document selection] active])
        [[document selection] clearSelection];
    [[[SeaController utilitiesManager] toolboxUtilityFor:document] changeToolTo:kRectSelectTool];
    [[document contents] makePasteboardFloat];
}

- (IBAction)delete:(id)sender
{
    if ([[document selection] floating]) {
        [[document contents] deleteLayer:kActiveLayer];
        [[document selection] clearSelection];
    }
    else {
        [[document selection] deleteSelection];
    }
}

- (IBAction)selectAll:(id)sender
{
    [[document selection] selectRect:IntMakeRect(0, 0, [(SeaLayer *)[[document contents] activeLayer] width], [(SeaLayer *)[[document contents] activeLayer] height]) mode:kDefaultMode];
}

- (IBAction)selectNone:(id)sender
{
    int curToolIndex = [[[SeaController utilitiesManager] toolboxUtilityFor:document] tool];
    
    if(curToolIndex >= kFirstSelectionTool && curToolIndex <= kLastSelectionTool && [[[document tools] currentTool] intermediate])
        [[[document tools] currentTool] cancelSelection];
    else
        [[document selection] clearSelection];
}

- (IBAction)selectInverse:(id)sender
{
    [[document selection] invertSelection];
}

- (IBAction)selectOpaque:(id)sender
{
    [[document selection] selectOpaque];
}

- (void)endLineDrawing
{
    lineDraw = NO;
}

- (IntPoint)getMousePosition:(BOOL)compensation
{
    NSPoint tempPoint;
    IntPoint localPoint;
    float xScale, yScale;
    id contents = [document contents];
    
    xScale = [[document contents] xscale];
    yScale = [[document contents] yscale];
    localPoint.x = localPoint.y = -1;
    tempPoint = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:NULL];
    // tempPoint.y = [self bounds].size.height - tempPoint.y;
    if (!NSMouseInRect(tempPoint, [self visibleRect], YES) || ![[self window] isVisible])
        return localPoint;
    localPoint.x = tempPoint.x / xScale;
    localPoint.y = tempPoint.y / yScale;
    if ([[document whiteboard] whiteboardIsLayerSpecific] && compensation) {
        localPoint.x -= [[contents activeLayer] xoff];
        localPoint.y -= [[contents activeLayer] yoff];
        if (localPoint.x < 0 || localPoint.x >= [(SeaLayer *)[contents activeLayer] width] || localPoint.y < 0 || localPoint.y >= [(SeaLayer *)[contents activeLayer] height])
            localPoint.x = localPoint.y = -1;        
    }
    else {
        if (localPoint.x < 0 || localPoint.x >= [(SeaContent *)[document contents] width] || localPoint.y < 0 || localPoint.y >= [(SeaContent *)[document contents] height])
            localPoint.x = localPoint.y = -1;
    }
    
    return localPoint;
}

- (NSDragOperation)draggingEntered:(id)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    NSArray *files;
    id layer;
    int i;
    BOOL success;
    
    // Determine the pasteboard and acceptable dragging operations
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    if ([sender draggingSource] && [[sender draggingSource] respondsToSelector:@selector(source)])
        layer = [[sender draggingSource] source];
    else
        layer = NULL;
    
    // Accept copy operations if possible
    if (sourceDragMask & NSDragOperationCopy) {
        if ([[pboard types] containsObject:NSTIFFPboardType] || [[pboard types] containsObject:NSPICTPboardType]) {
            if (layer != [[document contents] activeLayer] && ![document locked] && ![[document selection] floating] ) {
                return NSDragOperationCopy;
            }
        }
        if ([[pboard types] containsObject:NSFilenamesPboardType]) {
            if (layer != [[document contents] activeLayer] && ![document locked] && ![[document selection] floating]) {
                files = [pboard propertyListForType:NSFilenamesPboardType];
                success = YES;
                for (i = 0; i < [files count]; i++)
                    success = success && [[document contents] canImportLayerFromFile:[files objectAtIndex:i]];
                if (success) {
                    return NSDragOperationCopy;
                }
            }
        }
    }
    
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    NSArray *files;
    BOOL success;
    id layer;
    int i;
    
    // Determine the pasteboard and acceptable dragging operations
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    if ([sender draggingSource] && [[sender draggingSource] respondsToSelector:@selector(source)])
        layer = [[sender draggingSource] source];
    else
        layer = NULL;

    if (sourceDragMask & NSDragOperationCopy) {
    
        // Accept TIFFs as new layers
        if ([[pboard types] containsObject:NSTIFFPboardType]) {
            if (layer != NULL) {
                [[document contents] copyLayer:layer];
                return YES;
            }
            else {
                [[document contents] addLayerFromPasteboard:pboard];
                return YES;
            }
        }
        
        // Accept PICTs as new layers
        if ([[pboard types] containsObject:NSPICTPboardType]) {
            [[document contents] addLayerFromPasteboard:pboard];
            return YES;
        }
        
        // Accept files as new layers
        if ([[pboard types] containsObject:NSFilenamesPboardType]) {
            files = [pboard propertyListForType:NSFilenamesPboardType];
            success = YES;
            for (i = 0; i < [files count]; i++)
                success = success && [[document contents] importLayerFromFile:[files objectAtIndex:i]];
            return success;
        }

    }

    return NO;
}

- (void)updateRulersVisiblity
{
    NSView *superview = [[document scrollView] superview];
    int i;
    // This assumes that all of the subviews will actually respond to setRulersVisible
    for(i = 0; i < [[superview subviews] count]; i++){
        [[[superview subviews] objectAtIndex: i] setRulersVisible:[[SeaController seaPrefs] rulers]];
    }
    
    [self checkMouseTracking];
}

- (void)updateRulers
{    
    // Set up the rulers for the new settings
    switch ([document measureStyle]) {
        case kPixelUnits:
            [NSRulerView registerUnitWithName:@"Custom Horizontal Pixels" abbreviation:@"px" unitToPointsConversionFactor:((float)[[document contents] xres] / 72.0) * zoom stepUpCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:10.0]] stepDownCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:0.5]]];
            [horizontalRuler setMeasurementUnits:@"Custom Horizontal Pixels"];
            [NSRulerView registerUnitWithName:@"Custom Vertical Pixels" abbreviation:@"px" unitToPointsConversionFactor:((float)[[document contents] yres] / 72.0) * zoom stepUpCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:10.0]] stepDownCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:0.5]]];
            [verticalRuler setMeasurementUnits:@"Custom Vertical Pixels"];
        break;
        case kInchUnits:
            [NSRulerView registerUnitWithName:@"Custom Inches" abbreviation:@"in" unitToPointsConversionFactor:72.0 * zoom stepUpCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:2.0]] stepDownCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:0.5]]];
            [horizontalRuler setMeasurementUnits:@"Custom Inches"];
            [verticalRuler setMeasurementUnits:@"Custom Inches"];
        break;
        case kMillimeterUnits:
            [NSRulerView registerUnitWithName:@"Custom Millimetres" abbreviation:@"mm" unitToPointsConversionFactor:2.83464 * zoom stepUpCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:5.0]] stepDownCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:0.5]]];
            [horizontalRuler setMeasurementUnits:@"Custom Millimetres"];
            [verticalRuler setMeasurementUnits:@"Custom Millimetres"];
        break;
    }
}

- (BOOL)isFlipped
{
    return YES;
}

- (BOOL)isOpaque
{
    return YES;
}

- (BOOL)acceptsFirstResponder
{    
    [[self window] makeFirstResponder:self];
    
    return YES;
}

- (BOOL)resignFirstResponder 
{
    return YES;
    // WHY NOT?
    //return NO;
}

- (BOOL)validateMenuItem:(id)menuItem
{
    id availableType;
    
    [[document helpers] endLineDrawing];
    switch ([menuItem tag]) {
        case 261: /* Copy */
            if (![[document selection] active])
                return NO;
        break;
        case 260: /* Cut */
            if (![[document selection] active] || [[document selection] floating] || [[document contents] selectedChannel] != kAllChannels)
                return NO;
        break;
        case 263: /* Delete */
            if (![[document selection] active] || [[document contents] selectedChannel] != kAllChannels)
                return NO;
        break;
        case 270: /* Select All */
        case 273: /* Select Alpha */
            if ([[document selection] floating])
                return NO;
        break;
        case 271: /* Select None */
            if ([[[SeaController utilitiesManager] toolboxUtilityFor:document] tool] == kPolygonLassoTool && [[[document tools] currentTool] intermediate])
                return YES;
            if (![[document selection] active] || [[document selection] floating])
                return NO;
        break;
        case 272: /* Select Inverse */
            if (![[document selection] active] || [[document selection] floating])
                return NO;
        break;
        case 262: /* Paste */
            if ([[document selection] floating])
                return NO;
            availableType = [[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NSPICTPboardType, NULL]];
            if (availableType)
                return YES;
            else
                return NO;
        break;
    }
    
    return YES;
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    if([[theItem itemIdentifier] isEqual: SelectNoneToolbarItemIdentifier]){
        if ([[[SeaController utilitiesManager] toolboxUtilityFor:document] tool] == kPolygonLassoTool && [[[document tools] currentTool] intermediate])
            return YES;
        if (![[document selection] active] || [[document selection] floating])
            return NO;
    } else     if([[theItem itemIdentifier] isEqual: SelectAllToolbarItemIdentifier] || [[theItem itemIdentifier] isEqual: SelectAlphaToolbarItemIdentifier] ){
        if ([[document selection] floating])
            return NO;
    } else if([[theItem itemIdentifier] isEqual: SelectInverseToolbarItemIdentifier]){
        if (![[document selection] active] || [[document selection] floating])
            return NO;
    }
    
    return YES;
}

@end

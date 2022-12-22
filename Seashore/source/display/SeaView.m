#import "SeaView.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "CenteringClipView.h"
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
#import "EffectTool.h"
#import "GradientTool.h"
#import "SeaFlip.h"
#import "SeaOperations.h"
#import "SeaCursors.h"
#import "AspectRatio.h"
#import "WarningsUtility.h"
#import "SeaScale.h"
#import "SeaBackground.h"
#import "SeaExtrasView.h"

#import "NSEvent_Extensions.h"
#import <Carbon/Carbon.h>
#import <CoreImage/CoreImage.h>
#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

static NSString*    SelectNoneToolbarItemIdentifier = @"Select None Toolbar Item Identifier";
static NSString*    SelectAllToolbarItemIdentifier = @"Select All Toolbar Item Identifier";
static NSString*    SelectInverseToolbarItemIdentifier = @"Select Inverse Toolbar Item Identifier";
static NSString*    SelectAlphaToolbarItemIdentifier = @"Select Alpha Toolbar Item Identifier";

@implementation SeaView

- (id)initWithDocument:(id)doc 
{    
    NSRect frame;
    int xres, yres;
     
    // Remember the document this view is displaying
    document = doc;
    
    // Determine the frame at 100% 72-dpi
    frame = IntRectMakeNSRect([[document contents] rect]);

    // Adjust frame for non 72 dpi resolutions
    xres = [[document contents] xres];
    yres = [[document contents] yres];

    // Initialize superclass
    if ([super initWithFrame:frame] == NULL){
        return NULL;
    }
    
    // Set data members appropriately
    lineDraw = NO;
    magnifyTimer = NULL;
    magnifyFactor = 1.0;
    tabletEraser = 0;
    toolMemory = kEyedropTool;
    scrollZoom = lastTrigger = 0.0;
    
    // Set the delta
    delta = IntMakePoint(0,0);
    
    // Create the cursors manager
    cursorsManager = [[SeaCursors alloc] initWithDocument: doc andView: self];
    
    // Register for drag operations
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSTIFFPboardType, NSFilenamesPboardType, NSURLPboardType, NSFilesPromisePboardType, nil]];

    // Warn if bad resolution
    if (xres != yres || (xres < 72)) {
        [[document warnings] addMessage:LOCALSTR(@"strange res message", @"This image has an unusual resolution. To fix this use \"Image > Resolution...\" and set to 72 x 72 dpi.") level:kLowImportance];
    }

    whiteboard = [document whiteboard];
    extrasView = [[SeaExtrasView alloc] initWithDocument:document];

    [self addSubview:whiteboard];

    [self layout];

    return self;
}

- (void)layout
{
    [super layout];

    [background setFrame:[self frame]];
    [whiteboard setFrame:[self frame]];
}

- (void)dealloc
{
}

- (SeaExtrasView*)extrasView
{
    return extrasView;
}

- (IBAction)changeFont:(id)sender
{
    [[[document optionsUtility] getOptions:kTextTool] changeFont:sender];
}

- (IBAction)changeSpecialFont:(id)sender
{
    [[[document optionsUtility] getOptions:kTextTool] changeFont:sender];
}

- (IBAction)changeColor:(id)sender
{
    [[[document optionsUtility] getOptions:kTextTool] changeColor:sender];
}

- (BOOL)canZoomIn
{
    NSScrollView *view = [document scrollView];
    return [view magnification] < [view maxMagnification];
}

- (BOOL)canZoomOut
{
    NSScrollView *view = [document scrollView];
    return [view magnification] > [view minMagnification];
}

- (IBAction)zoomNormal:(id)sender
{
    float dpi = MAX([[document contents] xres], [[document contents] yres]);
    [[document scrollView] setMagnification:72.0/dpi];
    [self setNeedsDisplay:YES];
    [[document helpers] zoomChanged];
}

- (IBAction)zoomToFit:(id)sender
{
    [self zoomToFitRect:[[document contents] rect]];
}

- (IBAction)zoomToFitRect:(IntRect)rect
{
    NSRect r = IntRectMakeNSRect(rect);

    float adjust = ceilf(MAX(r.size.width,r.size.height)*.03); // add 3% border

    r = NSGrowRect(r,adjust);
    [[document scrollView] magnifyToFitRect:r];
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
    NSPoint point = [(CenteringClipView *)[self superview] centerPoint];

    if([self zoom] > pow(2, power)){
        while([self zoom] > pow(2, power)){
            float z0 = [self zoom];
            [self zoomOutFromPoint:point];
            if([self zoom]==z0)
                break;
        }
    }else if([self zoom] < pow(2, power)){
        while([self zoom] < pow(2, power)){
            float z0 = [self zoom];
            [self zoomInToPoint:point];
            if([self zoom]==z0)
                break;
        }
    }
}

- (void)zoomInToPoint:(NSPoint)point
{
    float magnification = [[document scrollView] magnification];
    magnification *= 2;
    [[document scrollView] setMagnification:magnification centeredAtPoint:point];
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
    float magnification = [[document scrollView] magnification];
    magnification /= 2;
    [[document scrollView] setMagnification:magnification centeredAtPoint:point];
    [self setNeedsDisplay:YES];
    [[document helpers] zoomChanged];
}

- (float)zoom
{
    return [[document scrollView] magnification];
}

-(void)setNeedsDisplay:(BOOL)b
{
    [whiteboard setNeedsDisplay:b];
    [background setNeedsDisplay:b];
    [extrasView setNeedsDisplay:b];
}

- (void)setNeedsDisplayInDocumentRect:(IntRect)invalidRect : (int)scaledArea
{
    NSRect displayUpdateRect = IntRectMakeNSRect(invalidRect);

    float size = [self scaledSize:scaledArea];

    displayUpdateRect = NSGrowRect(displayUpdateRect,size);
    displayUpdateRect = NSIntegralRectWithOptions(displayUpdateRect,NSAlignAllEdgesOutward | NSAlignRectFlipped);

    [extrasView setNeedsDisplayInRect:displayUpdateRect];
}

- (void)setNeedsDisplayInLayerRect:(IntRect)invalidRect : (int)scaledArea
{
    SeaLayer *layer = [[document contents] activeLayer];

    invalidRect = IntOffsetRect(invalidRect,[layer xoff],[layer yoff]);

    NSRect displayUpdateRect = IntRectMakeNSRect(invalidRect);

    float size = [self scaledSize:scaledArea];

    displayUpdateRect = NSGrowRect(displayUpdateRect,size);
    displayUpdateRect = NSIntegralRectWithOptions(displayUpdateRect,NSAlignAllEdgesOutward | NSAlignRectFlipped);

    [extrasView setNeedsDisplayInRect:displayUpdateRect];
}


- (float)scaledSize:(int)size
{
    float magnification = [[document scrollView] magnification];
    return size/magnification;
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    [[document infoUtility] update];
    [[document scrollView] updateRulerMarkings:[theEvent locationInWindow] andStationary:NSMakePoint(-256e6, -256e6)];
    [cursorsManager updateCursor:theEvent];
    lastMouseMove = getCurrentMillis();

    AbstractTool* tool = [document currentTool];

    if([tool respondsToSelector:@selector(mouseMovedTo:withEvent:)]) {
        NSPoint globalPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
        IntPoint localPoint = IntMakePoint(globalPoint.x-[[[document contents] activeLayer] xoff], globalPoint.y-[[[document contents] activeLayer] yoff]);

        [tool mouseMovedTo:localPoint withEvent:theEvent];
    }
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

- (void)readjust
{
    NSRect frame = NSMakeRect(0, 0, [[document contents] width], [[document contents] height]);
    [self setFrame:frame];
    [self layout];
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
    IntPoint localPoint;
    NSPoint globalPoint;

    AbstractOptions* options = [[document currentTool] getOptions];

    [cursorsManager updateCursor:theEvent];

    // Check if it is a line draw
    if (lineDraw) {
        [self mouseDragged:theEvent];
        return;
    }
    
    // Get the current tool
    AbstractTool *curTool = [document currentTool];
    
    // Calculate the localPoint and localActiveLayerPoint
    mouseDownLoc = [theEvent locationInWindow];
    globalPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
    localPoint.x = globalPoint.x - [[[document contents] activeLayer] xoff];
    localPoint.y = globalPoint.y - [[[document contents] activeLayer] yoff];
    
    // Turn mouse coalescing on or off
    if ([curTool useMouseCoalescing] || [(SeaPrefs *)[SeaController seaPrefs] mouseCoalescing]){
        NSEvent.mouseCoalescingEnabled = true;
    }else{
        NSEvent.mouseCoalescingEnabled = false;
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
    initialPoint = localPoint;
    
    if (([theEvent buttonNumber] == 1) || tabletEraser) {
        [options forceAlt];
        [cursorsManager updateCursor:theEvent]; // might have changed mode
    }
    
    [curTool mouseDownAt:localPoint withEvent:theEvent];
    lastLocalPoint = localPoint;
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
    [self mouseDragged:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    IntPoint localPoint;
    int deltaX, deltaY;
    double angle;

    id options = [[document currentTool] getOptions];

    NSPoint globalPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];

    AbstractTool *curTool = [document currentTool];
    
    localPoint.x = globalPoint.x - [[[document contents] activeLayer] xoff];
    localPoint.y = globalPoint.y - [[[document contents] activeLayer] yoff];
    
    // Snap to 45 degree intervals if requested
    deltaX = localPoint.x - lastLocalPoint.x;
    deltaY = localPoint.y - lastLocalPoint.y;

    if (lineDraw && ([(AbstractOptions*)options modifier] == kShiftControlModifier) && deltaX != 0) {
        angle = atan((double)deltaY / (double)abs(deltaX));
        if (angle > -0.3927 && angle < 0.3927)
            localPoint.y = lastLocalPoint.y;
        else if (angle > 1.1781 || angle < -1.1781)
            localPoint.x = lastLocalPoint.x;
        else if (angle > 0.0)
            localPoint.y = lastLocalPoint.y + abs(deltaX);
        else 
            localPoint.y = lastLocalPoint.y - abs(deltaX);
    }
    
    // Determine the delta
    delta.x = localPoint.x - initialPoint.x;
    delta.y = localPoint.y - initialPoint.y;

    [curTool mouseDraggedTo:localPoint withEvent:theEvent];
    lastLocalPoint = localPoint;
    lineDraw = NO;

    [self autoscroll:theEvent];
    
    [[document infoUtility] update];
    [[document scrollView] updateRulerMarkings:[theEvent locationInWindow] andStationary:mouseDownLoc];
}


- (void)rightMouseUp:(NSEvent *)theEvent
{
    [self mouseUp:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    id curTool = [document currentTool];
    NSPoint localPoint;
    IntPoint localActiveLayerPoint;

    AbstractOptions* options = [[document currentTool] getOptions];

    // Return to normal coalescing
    NSEvent.mouseCoalescingEnabled = true;

    // Check if it is a line draw
    if ([curTool acceptsLineDraws] && ([options modifier] == kShiftModifier || [options modifier] == kShiftControlModifier)) {
        lineDraw = YES;
        return;
    }

    // Calculate the localPoint and localActiveLayerPoint
    mouseDownLoc = NSMakePoint(-256e6, -256e6);
    localPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
    localActiveLayerPoint.x = localPoint.x - [[[document contents] activeLayer] xoff];
    localActiveLayerPoint.y = localPoint.y - [[[document contents] activeLayer] yoff];
    
    // First treat this as an ordinary drag
    [self mouseDragged:theEvent];
    
    // Reset the delta
    delta = IntMakePoint(0,0);

    [curTool mouseUpAt:localActiveLayerPoint withEvent:theEvent];
    [cursorsManager updateCursor:theEvent];

    [options unforceAlt];
}

- (IntPoint)delta
{
    return delta;
}

- (void)flagsChanged:(NSEvent *)theEvent
{
    int mods = [theEvent modifierFlags];

    [[[document currentTool] getOptions] updateModifiers:mods];
    [cursorsManager updateCursor:theEvent];
}

- (void)keyDown:(NSEvent *)theEvent
{
    int whichKey, whichLayer, xoff, yoff;
    id curLayer, activeLayer;
    IntPoint oldOffsets;
    unichar key;
    unsigned int mods;
    
    ToolboxUtility *toolbox = [document toolboxUtility];
    
    int curToolIndex = [toolbox tool];

#ifdef DEBUG
    // need to handle these before any other processing or the data could be changed
    switch([[theEvent charactersIgnoringModifiers] characterAtIndex:0]){
        case '1':
            [[document whiteboard] debugTempLayer];
            return;
        case '2':
            [[document whiteboard] debugDataCtx];
            return;
        case '3':
            [[document whiteboard] debugOverlayCtx];
            return;
    }
#endif

    
    // End the line drawing
    [[document helpers] endLineDrawing];
    
    // Check for zoom-in or zoom-out
    mods = [theEvent modifierFlags];
    if ((mods & NSCommandKeyMask)) {
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
    if ((mods & NSControlKeyMask) || (mods & NSCommandKeyMask))
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
        
            // If there is a selection active move the selection otherwise move the layer
            if (curToolIndex == kPositionTool) {
                PositionTool *positionTool = (PositionTool*)[document currentTool];

                // Make the adjustment
                switch (key) {
                    case NSUpArrowFunctionKey:
                        [positionTool adjustOffset:IntMakePoint(0, -1 * nudge)];
                        break;
                    case NSDownArrowFunctionKey:
                        [positionTool adjustOffset:IntMakePoint(0, nudge)];
                        break;
                    case NSLeftArrowFunctionKey:
                        [positionTool adjustOffset:IntMakePoint(-1 * nudge, 0)];
                        break;
                    case NSRightArrowFunctionKey:
                        [positionTool adjustOffset:IntMakePoint(nudge, 0)];
                        break;
                }
            }
            else if (curToolIndex == kCropTool) {
                CropTool *cropTool = (CropTool*)[document currentTool];
            
                // Make the adjustment
                switch (key) {
                    case NSUpArrowFunctionKey:
                        [cropTool adjustCrop:IntMakePoint(0, -1 * nudge)];
                    break;
                    case NSDownArrowFunctionKey:
                        [cropTool adjustCrop:IntMakePoint(0, nudge)];
                    break;
                    case NSLeftArrowFunctionKey:
                        [cropTool adjustCrop:IntMakePoint(-1 * nudge, 0)];
                    break;
                    case NSRightArrowFunctionKey:
                        [cropTool adjustCrop:IntMakePoint(nudge, 0)];
                    break;
                }
                
            
            }
            else if ([[document selection] active] ) {
            
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
                    if(curToolIndex >= kFirstSelectionTool && curToolIndex <= kLastSelectionTool && [[document currentTool] intermediate])
                        [(AbstractSelectTool*)[document currentTool] cancelSelection];
                    else
                        [[document selection] clearSelection];
                break;
                case '`':
                    if ([[document selection] active]) {
                        [self selectInverse:NULL];
                    }
                break;
                case 'm':
                    if ([toolbox tool] == kRectSelectTool)
                        [toolbox changeToolTo:kEllipseSelectTool];
                    else
                        [toolbox changeToolTo:kRectSelectTool];
                break;
                case 'l':
                    if ([toolbox tool] == kLassoTool)
                        [toolbox changeToolTo:kPolygonLassoTool];
                    else
                        [toolbox changeToolTo:kLassoTool];
                break;
                case 'w':
                        [toolbox changeToolTo:kWandTool];
                break;
                case 'b':
                    if ([toolbox tool] == kBrushTool)
                        [toolbox changeToolTo:kPencilTool];
                    else
                        [toolbox changeToolTo:kBrushTool];
                break;
                case 'g':
                    if ([toolbox tool] == kBucketTool)
                        [toolbox changeToolTo:kGradientTool];
                    else
                        [toolbox changeToolTo:kBucketTool];
                break;
                case 't':
                    [toolbox changeToolTo:kTextTool];
                break;
                case 'e':
                    [toolbox changeToolTo:kEraserTool];
                break;
                case 'i':
                    [toolbox changeToolTo:kEyedropTool];
                break;
                case 'o':
                    if ([toolbox tool] == kSmudgeTool)
                        [toolbox changeToolTo:kEffectTool];
                    else
                        [toolbox changeToolTo:kSmudgeTool];
                break;
                case 's':
                    [toolbox changeToolTo:kCloneTool];
                break;
                case 'c':
                    [toolbox changeToolTo:kCropTool];
                break;
                case 'Z':
                    [toolbox changeToolTo:kZoomTool];
                break;
                case 'v':
                    [toolbox changeToolTo:kPositionTool];
                break;
                case 'x':
                    [[toolbox colorView] swapColors: self];
                break;
                case 'd':
                    [[toolbox colorView] defaultColors: self];
                break;
                case '\t':
                    toolMemory = [toolbox tool];
                    [toolbox changeToolTo:kEyedropTool];
                break;
                case 'z':
                    toolMemory = [toolbox tool];
                    [toolbox changeToolTo:kZoomTool];
                    break;
                break;
            }
        }
    }
    [cursorsManager updateCursor:theEvent];
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
            break;
            case '\t':
            case 'z':
                [[document toolboxUtility] changeToolTo:toolMemory];
            break;
        }
    }
    
    [cursorsManager updateCursor:theEvent];
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
        [[document contents] mergeDown];
    }else if (y > 0) {
        unsigned int mods = [event modifierFlags];
        [[document contents] layerFromSelection:(mods & NSAlternateKeyMask) >> 19];
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
    [[document toolboxUtility] changeToolTo:kRectSelectTool];
    [[document contents] layerFromPasteboard:[NSPasteboard generalPasteboard] atIndex:0];
}

- (IBAction)delete:(id)sender
{
    [[document selection] deleteSelection];
}

- (IBAction)selectAll:(id)sender
{
    [[document selection] selectRect:[[[document contents] activeLayer] globalRect] mode:kDefaultMode];
}

- (IBAction)selectNone:(id)sender
{
    int curToolIndex = [[document currentTool] toolId];
    
    if(curToolIndex >= kFirstSelectionTool && curToolIndex <= kLastSelectionTool && [[document currentTool] intermediate])
        [(AbstractSelectTool*)[document currentTool] cancelSelection];
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
    SeaContent *contents = [document contents];
    
    NSPoint tempPoint = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:NULL];
    IntPoint localPoint = NSPointMakeIntPoint(tempPoint);
    // tempPoint.y = [self bounds].size.height - tempPoint.y;
    if (!NSMouseInRect(tempPoint, [self visibleRect], YES) || ![[self window] isVisible])
        return localPoint;
    if ([[document whiteboard] whiteboardIsLayerSpecific] && compensation) {
        localPoint.x -= [[contents activeLayer] xoff];
        localPoint.y -= [[contents activeLayer] yoff];
        if (localPoint.x < 0 || localPoint.x >= [(SeaLayer *)[contents activeLayer] width] || localPoint.y < 0 || localPoint.y >= [[contents activeLayer] height])
            localPoint.x = localPoint.y = -1;        
    }
    else {
        if (localPoint.x < 0 || localPoint.x >= [(SeaContent *)[document contents] width] || localPoint.y < 0 || localPoint.y >= [[document contents] height])
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
        if ([[pboard types] containsObject:NSTIFFPboardType]) {
            if (layer != [[document contents] activeLayer]) {
                return NSDragOperationCopy;
            }
        }
        if([[pboard types] containsObject:NSFilesPromisePboardType]){
            if (layer != [[document contents] activeLayer]) {
                files = [pboard propertyListForType:NSFilesPromisePboardType];
                success = YES;
                for (i = 0; i < [files count]; i++)
                    success = success && [[document contents] canImportLayerFromFile:[files objectAtIndex:i]];
                if (success) {
                    return NSDragOperationCopy;
                }
            }
        }
        if ([[pboard types] containsObject:NSFilenamesPboardType]) {
            if (layer != [[document contents] activeLayer]) {
                files = [pboard propertyListForType:NSFilenamesPboardType];
                success = YES;
                for (i = 0; i < [files count]; i++)
                    success = success && [[document contents] canImportLayerFromFile:[files objectAtIndex:i]];
                if (success) {
                    return NSDragOperationCopy;
                }
            }
        }
        if ([[pboard types] containsObject:NSURLPboardType]) {
            if (layer != [[document contents] activeLayer]) {
                NSURL *url = [NSURL URLFromPasteboard:pboard];
                if([url isFileURL]) {
                    NSString *path = [url path];
                    if([[document contents] canImportLayerFromFile:path]){
                        return NSDragOperationCopy;
                    }
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
    id layer;

    // Determine the pasteboard and acceptable dragging operations
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    if ([sender draggingSource] && [[sender draggingSource] respondsToSelector:@selector(source)])
        layer = [[sender draggingSource] source];
    else
        layer = NULL;

    if (!(sourceDragMask & NSDragOperationCopy))
        return NO;

    if (layer != NULL) {
        [[document contents] copyLayer:layer];
        return YES;
    }
    else {
        [[document contents] layerFromPasteboard:pboard atIndex:0];
        return YES;
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
    return YES;
}

- (BOOL)resignFirstResponder 
{
    return YES;
}

- (BOOL)validateMenuItem:(id)menuItem
{
    id availableType;
    
    switch ([menuItem tag]) {
        case 261: /* Copy */
            if (![[document selection] active])
                return NO;
        break;
        case 260: /* Cut */
            if (![[document selection] active])
                return NO;
        break;
        case 263: /* Delete */
            if (![[document selection] active])
                return NO;
        break;
        case 270: /* Select All */
        case 273: /* Select Alpha */
        break;
        case 271: /* Select None */
            if ([[document currentTool] toolId] == kPolygonLassoTool && [[document currentTool] intermediate])
                return YES;
            if (![[document selection] active])
                return NO;
        break;
        case 272: /* Select Inverse */
            if (![[document selection] active])
                return NO;
        break;
        case 262: /* Paste */
            availableType = [[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NULL]];
            if (availableType)
                return YES;
            else
                return NO;
        break;
    }
    
    return YES;
}

@end

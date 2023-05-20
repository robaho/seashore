#import "AbstractTool.h"
#import "AbstractScaleTool.h"
#import "SeaExtrasView.h"
#import "SeaController.h"
#import "SeaWhiteboard.h"
#import "SeaPrefs.h"
#import "SeaTools.h"
#import "RectSelectOptions.h"
#import "RectSelectTool.h"
#import "EllipseSelectTool.h"
#import "LassoOptions.h"
#import "LassoTool.h"
#import "PositionTool.h"
#import "CropTool.h"
#import "TextTool.h"
#import "CloneTool.h"
#import "EffectTool.h"
#import "GradientTool.h"
#import "BucketTool.h"
#import "WandTool.h"
#import "TextTool.h"
#import "SeaSelection.h"
#import "ZoomTool.h"
#import "SeaLayer.h"
#import "SeaTextLayer.h"

@implementation SeaExtrasView

static CGFloat line_dash[2] = {3,3};
static CGFloat line_dash_0[2] = {3,3};

- (SeaExtrasView*)initWithDocument:(SeaDocument*)doc
{
    self = [super init];

    document = doc;

    return self;
}

- (NSView*)hitTest:(NSPoint)point
{
    if(NSPointInRect(point, [self frame]))
        return [document docView];
    return nil;
}

- (BOOL)isFlipped
{
    return TRUE;
}

- (BOOL)isOpaque
{
    return FALSE;
}

- (void)drawRect:(NSRect)dirtyRect {

    long start = LOG_PERFORMANCE ? getCurrentMillis() : 0;

    dirtyRect = NSIntegralRectWithOptions(dirtyRect,NSAlignAllEdgesOutward|NSAlignRectFlipped);

    float magnification = [[document scrollView] magnification];

    line_dash[0]=line_dash_0[0]/magnification;
    line_dash[1]=line_dash_0[1]/magnification;

    [NSBezierPath setDefaultLineWidth:2/magnification];

    if ([self shouldDrawBoundaries]) {
        [self drawBoundaries];
    }
    [self drawExtras];

    if(LOG_PERFORMANCE)
        NSLog(@"draw extras rect %@ %ld",NSStringFromRect(dirtyRect),getCurrentMillis()-start);
}

- (float)scaledSize:(int)size
{
    float magnification = [[document scrollView] magnification];
    return size/magnification;
}

- (BOOL)shouldDrawBoundaries
{
    ToolboxUtility *tUtil = [document toolboxUtility];
    int curToolIndex = [tUtil tool];
    AbstractTool *theTool = [[document tools] getTool:curToolIndex];

    return ([[SeaController seaPrefs] layerBounds] && ![[document whiteboard] whiteboardIsLayerSpecific]) ||
        [[document selection] active] ||
        (curToolIndex == kCropTool) ||
        (curToolIndex == kTextTool) ||
        (curToolIndex == kPositionTool) ||
        (curToolIndex == kZoomTool && [theTool intermediate]) ||
        (curToolIndex == kRectSelectTool && [theTool intermediate]) ||
        (curToolIndex == kEllipseSelectTool && [theTool intermediate]) ||
        (curToolIndex == kLassoTool && [theTool intermediate]) ||
        (curToolIndex == kPolygonLassoTool && [theTool intermediate]);
}

- (void)drawBoundaries
{
    int curToolIndex = [[document toolboxUtility] tool];

    if (curToolIndex == kCropTool) {
        [self drawLayerBoundaries];
        [self drawCropBoundaries];
    }
    else if (curToolIndex == kPositionTool) {
        // dont draw select/layer boundaries as it is confusing when using select tool
        [self drawPositionBoundaries];
    }
    else if (curToolIndex == kTextTool) {
        [self drawTextBoundaries];
    }
    else {
        [self drawLayerBoundaries];
        [self drawSelectBoundaries];
    }
}

- (void)drawCropBoundaries
{
    AbstractScaleTool* curTool = (AbstractScaleTool*)[document currentTool];

    BOOL intermediate =  [curTool intermediate];

    IntRect cropRect = [(CropTool*)[document currentTool] cropRect];

    if(IntRectIsEmpty(cropRect))
        return;

    NSRect tempRect = IntRectMakeNSRect(cropRect);

    NSBezierPath *tempPath = [NSBezierPath bezierPathWithRect:tempRect];
    [self strokePath:tempPath];

    if(!intermediate || [curTool isMovingOrScaling]) {
        [self drawDragHandles: tempRect type: kCropHandleType];
    }
}

-(void)strokePath:(NSBezierPath*)path
{
    [self strokePath:path withColor:[[SeaController seaPrefs] selectionColor:1.0]];
}

-(void)strokePath:(NSBezierPath*)path withColor:(NSColor*)selcolor
{
    NSColor *color = [NSColor blackColor];
    if(isBlack(selcolor)) {
        color = [NSColor whiteColor];
    }

    [color set];
    [path stroke];
    [selcolor set];
    [path setLineDash: line_dash count: 2 phase: 0.0];
    [path stroke];
}

- (void)drawPositionBoundaries
{
    SeaLayer *layer = [[document contents] activeLayer];

    if(layer==NULL)
        return;

    PositionTool *positionTool = (PositionTool*)[document currentTool];

    NSRect r = IntRectMakeNSRect([layer globalRect]);

    int w = r.size.width;
    int h = r.size.height;

    NSBezierPath *tempPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0,0,w,h)];
    NSAffineTransform *tx = [NSAffineTransform transform];
    [tx translateXBy:-(w/2) yBy:-(h/2)];
    [tempPath transformUsingAffineTransform:tx];
    [tempPath transformUsingAffineTransform:[positionTool transform]];
    tx = [NSAffineTransform transform];
    [tx translateXBy:(w/2) yBy:(h/2)];
    [tx translateXBy:r.origin.x yBy:r.origin.y];
    [tempPath transformUsingAffineTransform:tx];

    [self strokePath:tempPath];
    [self drawDragHandles:[tempPath bounds] type:kPositionType];
}

- (void)drawTextBoundaries
{
    TextTool *textTool = (TextTool*)[document currentTool];

    bool intermediate = [textTool intermediate];

    SeaLayer *layer = [[document contents] activeLayer];
    if(!intermediate && ([layer isRasterized] || ![layer isTextLayer]))
        return;

    NSRect tempRect = IntRectMakeNSRect([textTool bounds]);

    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(ctx);

    NSBezierPath *tempPath = [NSBezierPath bezierPathWithRect:tempRect];

    NSBezierPath *textPath = [textTool textPath];
    if(textPath) {
        NSBezierPath *tp = [NSBezierPath bezierPath];
        [tp appendBezierPath:textPath];
        NSAffineTransform *tx = [NSAffineTransform transform];
        [tx translateXBy:tempRect.origin.x yBy:tempRect.origin.y];
        [tx scaleXBy:tempRect.size.width/[tp bounds].size.width yBy:tempRect.size.height/[tp bounds].size.height];
        [tp transformUsingAffineTransform:tx];
        [tempPath appendBezierPath:tp];
    }

    [self strokePath:tempPath withColor:[NSColor greenColor]];

    if(!intermediate || [textTool isMovingOrScaling]) {
        [self drawDragHandles:tempRect type:kTextHandleType];
    }

    CGContextRestoreGState(ctx);
}

- (void)drawSelectMaskTimer
{
    if(![[self window] isKeyWindow])
        return;

    if([[SeaController seaPrefs] marchingAnts] && [[document selection] active]){
        selectionPhase++;

        float scale = 1 / [[document scrollView] magnification];
        NSRect selectRect = IntRectMakeNSRect([[document selection] maskRect]);
        [self setNeedsDisplayInRect:NSGrowRect(selectRect,2*scale)];
    }
}

static bool isBlack(NSColor *c){
    return [c redComponent]==0 && [c greenComponent]==0 && [c blueComponent]==0;
}

- (void)drawMarchingAnts:(NSRect)selectRect path:(CGPathRef)path context:(CGContextRef)ctx withColor:(NSColor*)selcolor
{
    CGContextSaveGState(ctx);
    CGContextSetBlendMode(ctx,kCGBlendModeCopy);
    CGContextSetInterpolationQuality(ctx,kCGInterpolationNone);
    CGContextSetShouldAntialias(ctx,false);

    int phase = selectionPhase%2;
    float scale = 1 / [[document scrollView] magnification];

    CGContextTranslateCTM(ctx,selectRect.origin.x,selectRect.origin.y);
    CGContextSetLineWidth(ctx,2*scale);

    NSColor *color = [NSColor blackColor];
    if(isBlack(selcolor)) {
        color = [NSColor whiteColor];
    }

    CGContextSetStrokeColorWithColor(ctx,[color CGColor]);
    CGContextAddPath(ctx,path);
    CGContextStrokePath(ctx);

    CGContextSetStrokeColorWithColor(ctx,[selcolor CGColor]);
    CGContextSetLineDash(ctx,phase ? 0 : line_dash[0],line_dash,2);
    CGContextAddPath(ctx,path);
    CGContextStrokePath(ctx);
    CGContextRestoreGState(ctx);
}

- (void)drawSelectUsingDimming:(NSRect)selectRect context:(CGContextRef)ctx
{
    CGContextSetFillColorWithColor(ctx,[[[SeaController seaPrefs] selectionColor:.75] CGColor]);

    int width = [[document contents] width];
    int height = [[document contents] height];

    CGContextFillRect(ctx, CGRectMake(0,0,width,height));
    CGContextSetBlendMode(ctx,kCGBlendModeDestinationOut);
    CGImageRef mask = [[document selection] maskImage];
    CGContextScaleCTM(ctx,1,-1);
    CGRect tx = CGRectMake(selectRect.origin.x,-selectRect.origin.y-selectRect.size.height,selectRect.size.width,selectRect.size.height);
    CGContextDrawImage(ctx,tx,mask);
}

- (void)drawSelectMask:(NSRect)selectRect
{
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(ctx);
    if([[SeaController seaPrefs] marchingAnts]) {
        [self drawMarchingAnts:selectRect path:[[document selection] maskPath] context:ctx withColor:[[SeaController seaPrefs] selectionColor:1.0]];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(drawSelectMaskTimer) object:nil];
        [self performSelector:@selector(drawSelectMaskTimer) withObject:nil afterDelay:.5];
    } else {
        [self drawSelectUsingDimming:selectRect context:ctx];
    }
    CGContextRestoreGState(ctx);
}

- (void)drawLayerBoundaries
{
    NSRect tempRect;
    NSBezierPath *tempPath;

    SeaContent *contents = [document contents];

    SeaLayer *layer = [contents activeLayer];

    if([[SeaController seaPrefs] layerBounds]) {
        tempRect = IntRectMakeNSRect([layer globalRect]);

        if([[SeaController seaPrefs] layerBoundaryLines]){
            if([[SeaController seaPrefs] whiteLayerBounds]){
                [[NSColor colorWithDeviceWhite:1.0 alpha:1.0] set];
            }else{
                [[[SeaController seaPrefs] selectionColor:1.0] set];
            }

            tempPath = [NSBezierPath bezierPathWithRect:tempRect];
            [tempPath setLineWidth:2/[[document scrollView] magnification]];
            [tempPath setLineDash: line_dash count: 2 phase: 0.0];
            [tempPath stroke];
        } else {
            if([[SeaController seaPrefs] whiteLayerBounds]){
                [[NSColor colorWithDeviceWhite:1.0 alpha:0.4] set];
            }else{
                [[[SeaController seaPrefs] selectionColor:0.4] set];
            }
            // draw by shading non-layer
            tempPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, [contents width],[contents height])];

            // First step is to draw the layer bounds
            [tempPath appendBezierPathWithRect:tempRect];
            [tempPath setWindingRule:NSEvenOddWindingRule];

            if([[SeaController seaPrefs] whiteLayerBounds]){
                [[NSColor colorWithDeviceWhite:1.0 alpha:0.4] set];
                [tempPath fill];
            }else{
                [[[SeaController seaPrefs] selectionColor:0.4] set];
                [tempPath fill];
            }
        }
    }
}

- (void)drawSelectBoundaries
{
    NSRect tempRect;
    IntRect tempSelectRect;
    BOOL useSelection, special, intermediate;
    AbstractTool* curTool = [document currentTool];
    int curToolIndex = [curTool toolId];
    NSBezierPath *tempPath;
    int radius = 0;

    SeaContent *contents = [document contents];
    SeaLayer *layer = [contents activeLayer];

    useSelection = [[document selection] active];
    int xoff = [layer xoff];
    int yoff = [layer yoff];

    // The selection rectangle
    if (useSelection){
        NSRect selectRect = IntRectMakeNSRect([[document selection] maskRect]);
        [self drawSelectMask:selectRect];
        // If the currently selected tool is a selection tool, draw the handles
        if(curToolIndex >= kFirstSelectionTool && curToolIndex <= kLastSelectionTool){
            [self drawDragHandles: selectRect type: kSelectionHandleType];
        }
    }

    // Get the data for drawing rounded rectangular selections
    special = NO;
    if (curToolIndex == kRectSelectTool) {
        radius = [(RectSelectOptions *)[[document currentTool] getOptions] radius];
        tempSelectRect = [(RectSelectTool *)curTool selectionRect];
        special = tempSelectRect.size.width < 2 * radius && tempSelectRect.size.height < 2 * radius;
    }

    // Check to see if the user is currently dragging a selection
    intermediate = NO;
    if(curToolIndex >= kFirstSelectionTool && curToolIndex <= kLastSelectionTool){
        intermediate =  [(AbstractScaleTool *)curTool intermediate] && ! [(AbstractScaleTool *)curTool isMovingOrScaling];
    }

    if(curToolIndex == kZoomTool && [(ZoomTool *)curTool intermediate]) {
        tempSelectRect = [(ZoomTool*)curTool zoomRect];
        tempRect = IntRectMakeNSRect(tempSelectRect);
        tempRect = NSIntegralRectWithOptions(tempRect,NSAlignAllEdgesInward);
        tempPath = [NSBezierPath  bezierPathWithRect:tempRect];
        [self strokePath:tempPath];
    } else if (intermediate && (curToolIndex == kEllipseSelectTool || special)) {
        // The ellipse tool is currently being dragged, so draw its marching ants
        tempSelectRect = [(EllipseSelectTool *)curTool selectionRect];
        tempRect = IntRectMakeNSRect(tempSelectRect);
        tempRect = NSIntegralRectWithOptions(tempRect,NSAlignAllEdgesInward);
        tempPath = [NSBezierPath bezierPathWithOvalInRect:tempRect];

        [self strokePath:tempPath];
    }
    else if (curToolIndex == kRectSelectTool && intermediate) {

        // The rectangle tool is being dragged, so draw its marching ants
        tempSelectRect = [(RectSelectTool *)curTool selectionRect];
        tempRect = IntRectMakeNSRect(tempSelectRect);
        tempRect = NSIntegralRectWithOptions(tempRect,NSAlignAllEdgesInward);

        // The corners have a rounding
        if (radius) {
            tempPath = [NSBezierPath bezierPathWithRoundedRect:tempRect xRadius:radius yRadius:radius];
        }
        else {
            tempPath = [NSBezierPath bezierPathWithRect:tempRect];
        }

        [self strokePath:tempPath];
    }else if((curToolIndex == kLassoTool || curToolIndex == kPolygonLassoTool) && intermediate){
        // Finally, draw the marching ants for the lasso or polygon lasso tools
        tempPath = [NSBezierPath bezierPath];

        LassoPoints lassoPoints;
        NSPoint start;
        lassoPoints = [(LassoTool *)curTool currentPoints];
        start = NSMakePoint((lassoPoints.points[0].x + xoff), (lassoPoints.points[0].y + yoff));

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
            [tempPath lineToPoint:NSMakePoint((thisPoint.x + xoff), (thisPoint.y + yoff))];
        }

        [self strokePath:tempPath];
    }
}

- (void)drawDragHandles:(NSRect) rect type: (int)type
{
    [self drawHandle: rect.origin type: type index: 0];
    rect.origin.x += rect.size.width / 2;
    [self drawHandle: rect.origin type: type index: 1];
    rect.origin.x += rect.size.width / 2;
    [self drawHandle: rect.origin type: type index: 2];
    rect.origin.y += rect.size.height / 2;
    [self drawHandle: rect.origin type: type index: 3];
    rect.origin.y += rect.size.height / 2;
    [self drawHandle: rect.origin type: type index: 4];
    rect.origin.x -= rect.size.width / 2;
    [self drawHandle: rect.origin type: type index: 5];
    rect.origin.x -= rect.size.width / 2;
    [self drawHandle: rect.origin type: type index: 6];
    rect.origin.y -= rect.size.height / 2;
    [self drawHandle: rect.origin type: type index: 7];
}

- (void)drawHandle:(NSPoint)origin type: (int)type index:(int) index
{
    float width = 8.0;
    width /= [[document scrollView] magnification];

    NSPoint p=origin;
    NSRect r = NSMakeRect(p.x-width/2,p.y-width/2,width,width);

    NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:r];
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
        case kTextHandleType:
            [[NSColor greenColor] set];
            break;
        case kGradientStartType:
            [[NSColor whiteColor] set];
            break;
        case kGradientEndType:
            [[NSColor whiteColor] set];
            break;
        case kPolygonalLassoType:
            [[NSColor blackColor] set];
            break;
        case kPositionType:
            [[NSColor blueColor] set];
//            [[[SeaController seaPrefs] guideColor: 1.0] set];
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
    [path fill];

    switch (type) {
        case kSelectionHandleType:
            [[NSColor grayColor] set];
            break;
        case kCropHandleType:
            [[NSColor redColor] set];
            break;
        case kTextHandleType:
            [[NSColor greenColor] set];
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
            [[NSColor whiteColor] set];
            break;
        default:
            NSLog(@"Handle type not understood.");
            break;
    }
    [shadow set];
    [path stroke];
    [[(SeaPrefs *)[SeaController seaPrefs] guideColor: 1.0] set];

    if(type==kPositionType){
        if(index==0 || index==6) {
            [self drawRotationArrow:r direction:-1];
        }
        if(index==2 || index==4) {
            [self drawRotationArrow:r direction:1];
        }
    }

    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawRotationArrow:(NSRect)r direction:(int)direction
{
    float width = 8;
    width /= [[document scrollView] magnification];

    width = width/2;

    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(0,0)];
    [path appendBezierPathWithArcFromPoint:NSMakePoint(width,0) toPoint:NSMakePoint(width,width) radius:width];

    NSBezierPath *arrow = [NSBezierPath bezierPath];
    float awidth = width/2;
    [arrow moveToPoint:NSMakePoint(0,0)];
    [arrow lineToPoint:NSMakePoint(awidth,0)];
    [arrow lineToPoint:NSMakePoint(awidth/2,awidth)];
    [arrow closePath];

    NSAffineTransform *tx = [NSAffineTransform transform];
    [tx translateXBy:width-awidth/2 yBy:width];
    [arrow transformUsingAffineTransform:tx];

    [path appendBezierPath:arrow];

    tx = [NSAffineTransform transform];
    [tx translateXBy:r.origin.x+r.size.width/2 yBy:r.origin.y+r.size.height/2];
    [tx scaleXBy:direction yBy:1];
    [path transformUsingAffineTransform:tx];


    [[NSColor whiteColor] set];
    [path stroke];
}

- (void)drawDragLine:(id<DraggableTool>)tool
{
    SeaLayer *layer = [[document contents] activeLayer];

    int xoff = [layer xoff];
    int yoff = [layer yoff];

    // Draw the connecting line
    [[[SeaController seaPrefs] guideColor: 1.0] set];

    NSPoint startNS = IntPointMakeNSPoint(IntOffsetPoint([tool start],xoff,yoff));
    NSPoint currentNS = IntPointMakeNSPoint(IntOffsetPoint([tool current],xoff,yoff));

    NSBezierPath *tempPath = [NSBezierPath bezierPath];
    [tempPath moveToPoint:startNS];
    [tempPath lineToPoint:currentNS];
    [tempPath stroke];

    float size = [self scaledSize:6];

    [[NSBezierPath bezierPathWithOvalInRect:NSGrowRect(NSEmptyRect(startNS),size)] fill];
    [[NSBezierPath bezierPathWithOvalInRect:NSGrowRect(NSEmptyRect(currentNS),size)] fill];
}


- (void)drawExtras
{
    int curToolIndex = [[document toolboxUtility] tool];
    EffectTool *effectTool = [[document tools] getTool:kEffectTool];
    CloneTool *cloneTool = [[document tools] getTool:kCloneTool];

    SeaLayer *layer = [[document contents] activeLayer];

    if(layer==NULL){
        return;
    }

    // Fill out various variables
    int xoff = [layer xoff];
    int yoff = [layer yoff];

    float magnification = [[document scrollView] magnification];

    if([(SeaPrefs *)[SeaController seaPrefs] guides] && magnification > 8){
        NSBezierPath *tempPath = [NSBezierPath bezierPath];

        [tempPath setLineWidth:1/magnification];

        [[[SeaController seaPrefs] guideColor:.25] set];
        int i, j;

        int w = [[document contents] width];
        int h = [[document contents] height];

        for(i = 0; i < w; i++){
            [tempPath moveToPoint:NSMakePoint(i, 0)];
            [tempPath lineToPoint:NSMakePoint(i, h)];
        }

        for(j = 0; j < h; j++){
            [tempPath moveToPoint:NSMakePoint(0, j)];
            [tempPath lineToPoint:NSMakePoint(w, j)];
        }
        [tempPath stroke];
    }

    if(curToolIndex == kPositionTool /* && [(SeaPrefs *)[SeaController seaPrefs] guides] */){
        // everything already drawn in boundaries
    }else if(curToolIndex == kCloneTool){
        // Draw source point
        if ([cloneTool fadeLevel]) {
            IntPoint sourcePoint = [cloneTool sourcePoint:NO];
            NSImage *crossImage = [NSImage imageNamed:@"cross"];
            NSPoint outPoint = IntPointMakeNSPoint(sourcePoint);
            float size = [self scaledSize:25];
            [crossImage drawInRect:NSGrowRect(NSEmptyRect(outPoint),size) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:[cloneTool fadeLevel] respectFlipped:TRUE hints:NULL];
        }
    }else if (curToolIndex == kEffectTool){
        NSImage *crossImage = [NSImage imageNamed:@"cross"];
        if([effectTool shouldDrawPoints]) {
            for (int i = 0; i < [(EffectTool*)effectTool clickCount]; i++) {
                NSPoint outPoint = IntPointMakeNSPoint(IntOffsetPoint([effectTool point:i],xoff,yoff));
                float size = [self scaledSize:25];
                [crossImage drawInRect:NSGrowRect(NSEmptyRect(outPoint),size) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:TRUE hints:NULL];
            }
        }
    }else if (curToolIndex == kGradientTool) {
        GradientTool *tool = [[document tools] getTool:kGradientTool];

        if([tool intermediate]){
            // Draw the connecting line
            [[[SeaController seaPrefs] guideColor: 1.0] set];

            NSPoint startNS = IntPointMakeNSPoint(IntOffsetPoint([tool start],xoff,yoff));
            NSPoint currentNS = IntPointMakeNSPoint(IntOffsetPoint([tool current],xoff,yoff));

            NSBezierPath *tempPath = [NSBezierPath bezierPath];
            [tempPath moveToPoint:startNS];
            [tempPath lineToPoint:currentNS];
            [tempPath stroke];

            // The handles are the appropriate color of the gradient.
            [self drawHandle:startNS type:kGradientStartType index: -1];
            [self drawHandle:currentNS type:kGradientEndType index: -1];
        }
    }else if (curToolIndex == kWandTool){
        WandTool *tool = (WandTool*)[[document tools] getTool: curToolIndex];
        if([tool intermediate] && ![tool isMovingOrScaling] && ![tool isPreviewing]){
            [self drawDragLine:tool];
        }
    }else if (curToolIndex == kBucketTool){
        BucketTool *tool = (BucketTool*)[[document tools] getTool: curToolIndex];
        if([tool intermediate]){
            [self drawDragLine:tool];
        }
    }
}


@end

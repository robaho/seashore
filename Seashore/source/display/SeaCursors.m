#import "SeaCursors.h"
#import "SeaTools.h"
#import "AbstractOptions.h"
#import "AbstractSelectOptions.h"
#import "SeaSelection.h"
#import "SeaController.h"
#import "SeaDocument.h"
#import "SeaView.h"
#import "ToolboxUtility.h"
#import "SeaLayer.h"
#import "SeaContent.h"
#import "OptionsUtility.h"
#import "BrushOptions.h"
#import "PencilOptions.h"
#import "PositionTool.h"
#import "CropTool.h"
#import "PositionOptions.h"
#import "SeaPrefs.h"
#import "LassoTool.h"

@implementation SeaCursors

- (id)initWithDocument:(id)newDocument andView:(id)newView
{
	document = newDocument;
	view = newView;

    // tool specific cursors
	_crosspointCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-cursor"] hotSpot:NSMakePoint(7, 7)];
	_wandCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"wand-cursor"] hotSpot:NSMakePoint(8, 8)];
	_zoomCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"zoom-cursor"] hotSpot:NSMakePoint(9, 9)];
	_pencilCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"pencil-cursor"] hotSpot:NSMakePoint(2, 2)];
	_brushCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"brush-cursor"] hotSpot:NSMakePoint(2, 2)];
    _cloneCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"clone-cursor"] hotSpot:NSMakePoint(12, 4)];
	_bucketCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"bucket-cursor"] hotSpot:NSMakePoint(3, 17)];
	_eyedropCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"eyedrop-cursor"] hotSpot:NSMakePoint(2, 2)];
	_moveCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"move-cursor"] hotSpot:NSMakePoint(11, 11)];

	_eraserCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"eraser-cursor"] hotSpot:NSMakePoint(7, 7)];
	_smudgeCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"smudge-cursor"] hotSpot:NSMakePoint(12, 1)];
	_effectCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"effect-cursor"] hotSpot:NSMakePoint(3, 3)];
    _noopCursor = [NSCursor operationNotAllowedCursor];
	
	// Additional Cursors
	_addCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-add-cursor"] hotSpot:NSMakePoint(7, 7)];
	_subtractCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-subtract-cursor"] hotSpot:NSMakePoint(7, 7)];
	_closeCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-close-cursor"] hotSpot:NSMakePoint(7, 7)];
	_resizeCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"resize-cursor"] hotSpot:NSMakePoint(12, 12)];
	
	// View Generic Cursors
	_handCursor = [NSCursor openHandCursor];
	_grabCursor = [NSCursor closedHandCursor];

	lrCursor = [NSCursor resizeLeftRightCursor];
	udCursor = [NSCursor resizeUpDownCursor];
    urdlCursor = _resizeCursor;
    uldrCursor = _resizeCursor;
	
	handleCursors[0]  = uldrCursor;
	handleCursors[1] = udCursor;
	handleCursors[2] = urdlCursor;
	handleCursors[3] = lrCursor;
	handleCursors[4] = uldrCursor;
	handleCursors[5] = udCursor;
	handleCursors[6] = urdlCursor;
	handleCursors[7] = lrCursor;
	
	return self;
}

- (IntRect)handleRect:(IntPoint)p
{
    int width = 8 / currentScale;
    return IntMakeRect(p.x-width/2,p.y-width/2,width,width);
}

- (void)updateCursor:(NSEvent*)event
{
    SeaLayer *layer = [[document contents] activeLayer];
    if(layer==NULL)
        return;

    NSPoint pw = [event locationInWindow];

    currentScale = [[document scrollView] magnification];
    IntPoint p = NSPointMakeIntPoint([view convertPoint:pw fromView:NULL]);

    AbstractTool *tool = [document currentTool];
    [tool updateCursor:p cursors:self];
    return;
}

- (void)handleRectCursors:(IntRect)rect point:(IntPoint)p cursor:(NSCursor*)cursor
{
   if (!IntRectIsEmpty(rect)) {
        int handle = getHandle(p, rect, currentScale);
        if(handle>=0) {
            handleCursors[handle].set;
            return;
        }
        if(IntPointInRect(p, rect)) {
            _handCursor.set;
            return;
        }
    }
    [cursor set];
}

- (BOOL)usePreciseCursor
{
    return [(SeaPrefs*)[SeaController seaPrefs] preciseCursor];
}

@end

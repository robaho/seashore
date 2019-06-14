#import "SeaCursors.h"
#import "SeaTools.h"
#import "AbstractOptions.h"
#import "AbstractSelectOptions.h"
#import "SeaSelection.h"
#import "SeaController.h"
#import "SeaDocument.h"
#import "SeaView.h"
#import "UtilitiesManager.h"
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

@implementation SeaCursors

- (id)initWithDocument:(id)newDocument andView:(id)newView
{
	document = newDocument;
	view = newView;
	/* Set-up the cursors */
	// Tool Specific Cursors
	crosspointCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-cursor"] hotSpot:NSMakePoint(7, 7)];
	wandCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"wand-cursor"] hotSpot:NSMakePoint(8, 8)];
	zoomCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"zoom-cursor"] hotSpot:NSMakePoint(9, 9)];
	pencilCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"pencil-cursor"] hotSpot:NSMakePoint(2, 2)];
	brushCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"brush-cursor"] hotSpot:NSMakePoint(2, 2)];
    cloneCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"clone-cursor"] hotSpot:NSMakePoint(12, 4)];
	bucketCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"bucket-cursor"] hotSpot:NSMakePoint(3, 17)];
	eyedropCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"eyedrop-cursor"] hotSpot:NSMakePoint(2, 2)];
	moveCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"move-cursor"] hotSpot:NSMakePoint(11, 11)];

	eraserCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"eraser-cursor"] hotSpot:NSMakePoint(7, 7)];
	smudgeCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"smudge-cursor"] hotSpot:NSMakePoint(12, 1)];
	effectCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"effect-cursor"] hotSpot:NSMakePoint(3, 3)];
    noopCursor = [NSCursor operationNotAllowedCursor];
	
	// Additional Cursors
	addCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-add-cursor"] hotSpot:NSMakePoint(7, 7)];
	subtractCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-subtract-cursor"] hotSpot:NSMakePoint(7, 7)];
	closeCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-close-cursor"] hotSpot:NSMakePoint(7, 7)];
	resizeCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"resize-cursor"] hotSpot:NSMakePoint(12, 12)];
	
	// View Generic Cursors
	handCursor = [NSCursor openHandCursor];
	grabCursor = [NSCursor closedHandCursor];
	lrCursor = [NSCursor resizeLeftRightCursor];
	udCursor = [NSCursor resizeUpDownCursor];
    urdlCursor = resizeCursor;
    uldrCursor = resizeCursor;
	
	handleCursors[0]  = uldrCursor;
	handleCursors[1] = udCursor;
	handleCursors[2] = urdlCursor;
	handleCursors[3] = lrCursor;
	handleCursors[4] = uldrCursor;
	handleCursors[5] = udCursor;
	handleCursors[6] = urdlCursor;
	handleCursors[7] = lrCursor;
	
	scrollingMode = NO;
	scrollingMouseDown = NO;
	
	return self;
}

- (void)addCursorRect:(NSRect)rect cursor:(NSCursor *)cursor
{
	NSScrollView *scrollView = (NSScrollView *)[[view superview] superview];
	
	// Convert to the scrollview's origin
	rect.origin = [scrollView convertPoint: rect.origin fromView: view];
	
	// Clip to the centering clipview
	NSRect clippedRect = NSIntersectionRect([[view superview] frame], rect);

	// Convert the point back to the seaview
	clippedRect.origin = [view convertPoint: clippedRect.origin fromView: scrollView];
	[view addCursorRect:clippedRect cursor:cursor];
}

- (void)resetCursorRects
{
	if(scrollingMode){
		if(scrollingMouseDown)
			[self addCursorRect:[view frame] cursor:grabCursor];
		else
			[self addCursorRect:[view frame] cursor:handCursor];
		return;
	}
	
	int tool = [[[SeaController utilitiesManager] toolboxUtilityFor:document] tool];
	SeaLayer *activeLayer = [[document contents] activeLayer];
    
    if(activeLayer==NULL)
        return;
    
	float xScale = [[document contents] xscale];
	float yScale = [[document contents] yscale];
	NSRect operableRect;
	IntRect operableIntRect;
	
	operableIntRect = IntMakeRect([activeLayer xoff] * xScale, [activeLayer yoff] * yScale, [activeLayer width] * xScale, [activeLayer height] *yScale);
	operableRect = IntRectMakeNSRect(IntConstrainRect(NSRectMakeIntRect([view frame]), operableIntRect));
    
    bool preciseCursor = [(SeaPrefs*)[SeaController seaPrefs] preciseCursor];

	if(tool >= kFirstSelectionTool && tool <= kLastSelectionTool){
		// Find out what the selection mode is
		int selectionMode = [(AbstractSelectOptions *)[[[SeaController utilitiesManager] optionsUtilityFor:document] getOptions:tool] selectionMode];
		
		if(selectionMode == kAddMode){
			[self addCursorRect:operableRect cursor:addCursor];
		}else if (selectionMode == kSubtractMode) {
			[self addCursorRect:operableRect cursor:subtractCursor];
		}else if(selectionMode != kDefaultMode){
			[self addCursorRect:operableRect cursor:crosspointCursor];
		}else{
			[self addCursorRect:operableRect cursor:crosspointCursor];
			
			// Now we need the handles and the hand
			if([[document selection] active]){
				NSRect selectionRect = IntRectMakeNSRect([[document selection] globalRect]);
				selectionRect = NSMakeRect(selectionRect.origin.x * xScale, selectionRect.origin.y * yScale, selectionRect.size.width * xScale, selectionRect.size.height * yScale);

				[self addCursorRect:NSConstrainRect(selectionRect,[view frame]) cursor:handCursor];
				int i;
				for(i = 0; i < 8; i++){
					[self addCursorRect:handleRects[i] cursor:handleCursors[i]];
				}
				
			}
		}
		
		if(tool == kPolygonLassoTool && closeRect.size.width > 0 && closeRect.size.height > 0){
			[self addCursorRect:closeRect cursor: closeCursor];
		}
	}else if(tool == kCropTool){
		NSRect cropRect;
		IntRect origRect;
		[self addCursorRect:[view frame] cursor:crosspointCursor];
		
		origRect = [[document currentTool] cropRect];
		cropRect = NSMakeRect(origRect.origin.x * xScale, origRect.origin.y * yScale, origRect.size.width * xScale, origRect.size.height * yScale);
		
		if (cropRect.size.width != 0 && cropRect.size.height != 0){
				
			[self addCursorRect:NSConstrainRect(cropRect,[view frame]) cursor:handCursor];
			int i;
			for(i = 0; i < 8; i++){
				[self addCursorRect:handleRects[i] cursor:handleCursors[i]];
			}
		}
	}else if (tool == kPositionTool) {
		NSRect cropRect;
		IntRect origRect;

		[self addCursorRect:[view frame] cursor:moveCursor];
		
		origRect =IntConstrainRect(NSRectMakeIntRect([view frame]), operableIntRect);
		cropRect = NSMakeRect(origRect.origin.x * xScale, origRect.origin.y * yScale, origRect.size.width * xScale, origRect.size.height * yScale);
		
		if (cropRect.size.width != 0 && cropRect.size.height != 0){
			
			[self addCursorRect:NSConstrainRect(cropRect,[view frame]) cursor:handCursor];
			int i;
			for(i = 0; i < 8; i++){
				[self addCursorRect:handleRects[i] cursor:handleCursors[i]];
			}
		}
	}else{
        
		// If there is currently a selection, then users can operate in there only
		if([[document selection] active]){
			operableIntRect = [[document selection] globalRect];
			operableIntRect = IntMakeRect(operableIntRect.origin.x * xScale, operableIntRect.origin.y * yScale, operableIntRect.size.width * xScale, operableIntRect.size.height * yScale);
			operableRect = IntRectMakeNSRect(IntConstrainRect(NSRectMakeIntRect([view frame]), operableIntRect));
		
		}
		
		switch (tool) {
			case kZoomTool:
				[self addCursorRect:[view frame] cursor:zoomCursor];
				break;
			case kPencilTool:
                [self addCursorRect:operableRect cursor:(preciseCursor ? crosspointCursor :pencilCursor)];
				break;
			case kBrushTool:
                 [self addCursorRect:operableRect cursor:(preciseCursor ? crosspointCursor : brushCursor)];
				break;
			case kBucketTool:
                [self addCursorRect:operableRect cursor:(preciseCursor ? crosspointCursor :bucketCursor)];
				break;
			case kTextTool:
				[self addCursorRect:operableRect cursor:[NSCursor IBeamCursor]];
				break;
			case kEyedropTool:
                [self addCursorRect:[view frame] cursor:(preciseCursor ? crosspointCursor : eyedropCursor)];
				break;
			case kEraserTool:
                [self addCursorRect:operableRect cursor:(preciseCursor ? crosspointCursor : eraserCursor)];
				break;
			case kGradientTool:
				[self addCursorRect:[view frame] cursor:crosspointCursor];
				break;
			case kSmudgeTool:
                [self addCursorRect:[view frame] cursor:(preciseCursor ? crosspointCursor :smudgeCursor)];
				break;
			case kCloneTool:
                [self addCursorRect:[view frame] cursor:(preciseCursor ? crosspointCursor : cloneCursor)];
				break;
			case kEffectTool:
                [self addCursorRect:[view frame] cursor:(preciseCursor ? crosspointCursor : effectCursor)];
				break;
			default:
				[self addCursorRect:operableRect cursor:NULL];
				break;
		}
		
	}

	if(tool == kBrushTool && [(BrushOptions *)[[[SeaController utilitiesManager] optionsUtilityFor:document] getOptions:tool] brushIsErasing]){
		// Do we need this?
		//[view removeCursorRect:operableRect cursor:brushCursor];
        [self addCursorRect:operableRect cursor:(preciseCursor ? crosspointCursor : eraserCursor)];
	}else if (tool == kPencilTool && [(PencilOptions *)[[[SeaController utilitiesManager] optionsUtilityFor:document] getOptions:tool] pencilIsErasing]){
		// Do we need this?
		//[view removeCursorRect:operableRect cursor:pencilCursor];
		[self addCursorRect:operableRect cursor:(preciseCursor ? crosspointCursor : eraserCursor)];
	}
	
	
	// Some tools can operate outside of the selection rectangle
	if(tool != kZoomTool && tool != kEyedropTool && tool != kGradientTool && tool != kSmudgeTool && tool != kCloneTool && tool != kCropTool && tool != kEffectTool && tool != kPositionTool){
		// Now we need the noop section		
		if(operableRect.origin.x > 0){
			NSRect leftRect = NSMakeRect(0,0,operableRect.origin.x,[view frame].size.height);
			[self addCursorRect:leftRect cursor:noopCursor];
		}
		float rightX = operableRect.origin.x + operableRect.size.width; 
		if(rightX < [view frame].size.width){
			NSRect rightRect = NSMakeRect(rightX, 0, [view frame].size.width - rightX, [view frame].size.height);
			[self addCursorRect:rightRect cursor:noopCursor];
		}
		if(operableRect.origin.y > 0){
			NSRect bottomRect = NSMakeRect(0, 0, [view frame].size.width, operableRect.origin.y);
			[self addCursorRect:bottomRect cursor:noopCursor];
		}
		float topY = operableRect.origin.y + operableRect.size.height;
		if(topY < [view frame].size.height){
			NSRect topRect = NSMakeRect(0, topY, [view frame].size.width, [view frame].size.height - topY);
			[self addCursorRect:topRect cursor:noopCursor];
		}
	}
}

- (NSRect *)handleRectsPointer
{
	return handleRects;
}

- (void)setCloseRect:(NSRect)rect
{
	closeRect = rect;
}

- (void)setScrollingMode:(BOOL)inMode mouseDown:(BOOL)mouseDown
{
	scrollingMode = inMode;
	scrollingMouseDown = mouseDown;	
}

@end

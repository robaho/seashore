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

@implementation SeaCursors

- (id)initWithDocument:(id)newDocument andView:(id)newView
{
	document = newDocument;
	view = newView;
	/* Set-up the cursors */
	// Tool Specific Cursors
	crosspointCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-cursor"] hotSpot:NSMakePoint(7, 7)];
	[crosspointCursor setOnMouseEntered:YES];
	wandCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"wand-cursor"] hotSpot:NSMakePoint(2, 2)];
	[wandCursor setOnMouseEntered:YES];
	zoomCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"zoom-cursor"] hotSpot:NSMakePoint(5, 6)];
	[zoomCursor setOnMouseEntered:YES];
	pencilCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"pencil-cursor"] hotSpot:NSMakePoint(3, 15)];
	[pencilCursor setOnMouseEntered:YES];
	brushCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"brush-cursor"] hotSpot:NSMakePoint(1, 14)];
	[brushCursor setOnMouseEntered:YES];
	bucketCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"bucket-cursor"] hotSpot:NSMakePoint(14, 14)];
	[bucketCursor setOnMouseEntered:YES];
	eyedropCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"eyedrop-cursor"] hotSpot:NSMakePoint(1, 14)];
	[eyedropCursor setOnMouseEntered:YES];
	moveCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"move-cursor"] hotSpot:NSMakePoint(7, 7)];
	[moveCursor setOnMouseEntered:YES];
	eraserCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"eraser-cursor"] hotSpot:NSMakePoint(2, 12)];
	[eraserCursor setOnMouseEntered:YES];
	smudgeCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"smudge-cursor"] hotSpot:NSMakePoint(1, 15)];
	[smudgeCursor setOnMouseEntered:YES];
	effectCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"effect-cursor"] hotSpot:NSMakePoint(1, 1)];
	[smudgeCursor setOnMouseEntered:YES];
	noopCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"noop-cursor"] hotSpot:NSMakePoint(7, 7)];
	[noopCursor setOnMouseEntered:YES];
	
	// Additional Cursors
	addCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-add-cursor"] hotSpot:NSMakePoint(7, 7)];
	[addCursor setOnMouseEntered:YES];
	subtractCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-subtract-cursor"] hotSpot:NSMakePoint(7, 7)];
	[subtractCursor setOnMouseEntered:YES];
	closeCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-close-cursor"] hotSpot:NSMakePoint(7, 7)];
	[closeCursor setOnMouseEntered:YES];
	resizeCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"resize-cursor"] hotSpot:NSMakePoint(7, 7)];
	[resizeCursor setOnMouseEntered:YES];
	rotateCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"rotate-cursor"] hotSpot:NSMakePoint(7, 7)];
	[rotateCursor setOnMouseEntered:YES];
	anchorCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"anchor-cursor"] hotSpot:NSMakePoint(7, 7)];
	[anchorCursor setOnMouseEntered:YES];
	
	// View Generic Cursors
	handCursor = [NSCursor openHandCursor];
	[handCursor setOnMouseEntered:YES];
	grabCursor = [NSCursor closedHandCursor];
	[grabCursor setOnMouseEntered:YES];
	lrCursor = [NSCursor resizeLeftRightCursor];
	[lrCursor setOnMouseEntered:YES];
	udCursor = [NSCursor resizeUpDownCursor];
	[udCursor setOnMouseEntered:YES];
	urdlCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"resize-ne-sw-cursor"] hotSpot:NSMakePoint(7, 7)];
	[urdlCursor setOnMouseEntered:YES];
	uldrCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"resize-nw-se-cursor"] hotSpot:NSMakePoint(7, 7)];
	[uldrCursor setOnMouseEntered:YES];
	
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

- (void)dealloc
{
	if (crosspointCursor) [crosspointCursor autorelease];
	if (wandCursor) [wandCursor autorelease];
	if (zoomCursor) [zoomCursor autorelease];
	if (pencilCursor) [pencilCursor autorelease];
	if (brushCursor) [brushCursor autorelease];
	if (bucketCursor) [bucketCursor autorelease];
	if (eyedropCursor) [eyedropCursor autorelease];
	if (moveCursor) [moveCursor autorelease];
	if (eraserCursor) [eraserCursor autorelease];
	if (smudgeCursor) [smudgeCursor autorelease];
	if (noopCursor) [noopCursor autorelease];
	if (addCursor) [addCursor autorelease];
	if (subtractCursor) [subtractCursor autorelease];
	if (closeCursor) [closeCursor autorelease];
	if (resizeCursor) [resizeCursor autorelease];
	if (rotateCursor) [rotateCursor autorelease];
	if (anchorCursor) [anchorCursor autorelease];
	if (urdlCursor) [urdlCursor autorelease];
	if (urdlCursor) [urdlCursor autorelease];
	[super dealloc];
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
	float xScale = [[document contents] xscale];
	float yScale = [[document contents] yscale];
	NSRect operableRect;
	IntRect operableIntRect;
	
	operableIntRect = IntMakeRect([activeLayer xoff] * xScale, [activeLayer yoff] * yScale, [activeLayer width] * xScale, [activeLayer height] *yScale);
	operableRect = IntRectMakeNSRect(IntConstrainRect(NSRectMakeIntRect([view frame]), operableIntRect));

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
		
		origRect = [(CropTool *)[[document tools] currentTool] cropRect];
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
				[self addCursorRect:operableRect cursor:pencilCursor];
				break;
			case kBrushTool:
				[self addCursorRect:operableRect cursor:brushCursor];
				break;
			case kBucketTool:
				[self addCursorRect:operableRect cursor:bucketCursor];
				break;
			case kTextTool:
				[self addCursorRect:operableRect cursor:[NSCursor IBeamCursor]];
				break;
			case kEyedropTool:
				[self addCursorRect:[view frame] cursor:eyedropCursor];
				break;
			case kEraserTool:
				[self addCursorRect:operableRect cursor:eraserCursor];
				break;
			case kGradientTool:
				[self addCursorRect:[view frame] cursor:crosspointCursor];
				break;
			case kSmudgeTool:
				[self addCursorRect:[view frame] cursor:smudgeCursor];
				break;
			case kCloneTool:
				[self addCursorRect:[view frame] cursor:brushCursor];
				break;
			case kEffectTool:
				[self addCursorRect:[view frame] cursor:effectCursor];
				break;
			default:
				[self addCursorRect:operableRect cursor:NULL];
				break;
		}
		
	}

	if(tool == kBrushTool && [(BrushOptions *)[[[SeaController utilitiesManager] optionsUtilityFor:document] getOptions:tool] brushIsErasing]){
		// Do we need this?
		//[view removeCursorRect:operableRect cursor:brushCursor];
		[self addCursorRect:operableRect cursor:eraserCursor];
	}else if (tool == kPencilTool && [(PencilOptions *)[[[SeaController utilitiesManager] optionsUtilityFor:document] getOptions:tool] pencilIsErasing]){
		// Do we need this?
		//[view removeCursorRect:operableRect cursor:pencilCursor];
		[self addCursorRect:operableRect cursor:eraserCursor];
	}/*else if (tool == kPositionTool){
		PositionOptions *options = (PositionOptions *)[[[SeaController utilitiesManager] optionsUtilityFor:document] getOptions:tool];
		if([options toolFunction] == kScalingLayer){
			[self addCursorRect:[view frame] cursor:resizeCursor];
		}else if([options toolFunction] == kRotatingLayer){
			[self addCursorRect:[view frame] cursor:rotateCursor];
		}else if([options toolFunction] == kMovingLayer){
			[self addCursorRect:[view frame] cursor:moveCursor];
		}
	}*/
	
	
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

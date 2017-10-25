#import "ToolboxUtility.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "SeaView.h"
#import "OptionsUtility.h"
#import "ColorSelectView.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "UtilitiesManager.h"
#import "SeaTools.h"
#import "SeaHelpers.h"
#import "SeaPrefs.h"
#import "SeaProxy.h"
#import "InfoUtility.h"
#import "AbstractOptions.h"
#import "SeaToolbarItem.h"
#import "ImageToolbarItem.h"
#import "StatusUtility.h"
#import "SeaWindowContent.h"
#import "WarningsUtility.h"

static NSString*	DocToolbarIdentifier 	= @"Document Toolbar Instance Identifier";

static NSString*	SelectionIdentifier 	= @"Selection  Item Identifier";
static NSString*	DrawIdentifier 	= @"Draw Item Identifier";
static NSString*    EffectIdentifier = @"Effect Item Identifier";
static NSString*    TransformIdentifier = @"Transform Item Identifier";
static NSString*	ColorsIdentifier = @"Colors Item Identifier";

// Additional (Non-default) toolbar items
static NSString*	ZoomInToolbarItemIdentifier = @"Zoom In Toolbar Item Identifier";
static NSString*	ZoomOutToolbarItemIdentifier = @"Zoom Out Toolbar Item Identifier";
static NSString*	ActualSizeToolbarItemIdentifier = @"Actual Size Toolbar Item Identifier";
static NSString*	NewLayerToolbarItemIdentifier = @"New Layer Toolbar Item Identifier";
static NSString*	DuplicateLayerToolbarItemIdentifier = @"Duplicate Layer Toolbar Item Identifier";
static NSString*	ForwardToolbarItemIdentifier = @"Move Layer Forward  Toolbar Item Identifier";
static NSString*	BackwardToolbarItemIdentifier = @"Move Layer Backward Toolbar Item Identifier";
static NSString*	DeleteLayerToolbarItemIdentifier = @"Delete Layer Toolbar Item Identifier";
static NSString*	ToggleLayersToolbarItemIdentifier = @"Show/Hide Layers Item Identifier";
static NSString*	InspectorToolbarItemIdentifier = @"Show/Hide Inspector Toolbar Item Identifier";
static NSString*	FloatAnchorToolbarItemIdentifier = @"Float/Anchor Toolbar Item Identifier";
static NSString*	DuplicateSelectionToolbarItemIdentifier = @"Duplicate Selection Toolbar Item Identifier";
static NSString*	SelectNoneToolbarItemIdentifier = @"Select None Toolbar Item Identifier";
static NSString*	SelectAllToolbarItemIdentifier = @"Select All Toolbar Item Identifier";
static NSString*	SelectInverseToolbarItemIdentifier = @"Select Inverse Toolbar Item Identifier";
static NSString*	SelectAlphaToolbarItemIdentifier = @"Select Alpha Toolbar Item Identifier";

@implementation ToolboxUtility

- (id)init
{
	foreground = [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0] retain];
	background = [[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0] retain];
	delay_timer = NULL;
	tool = -1;
	oldTool = -1;
	selectionTools = [[NSArray arrayWithObjects: 
					  [NSNumber numberWithInt: kRectSelectTool],
					  [NSNumber numberWithInt: kEllipseSelectTool],
					  [NSNumber numberWithInt: kLassoTool],
					  [NSNumber numberWithInt: kPolygonLassoTool],
					  [NSNumber numberWithInt: kWandTool],
					  nil] retain];
	drawTools =	[[NSArray arrayWithObjects: 
				 [NSNumber numberWithInt: kPencilTool],
				 [NSNumber numberWithInt: kBrushTool],
				 [NSNumber numberWithInt: kTextTool],
				 [NSNumber numberWithInt: kEraserTool],
				 [NSNumber numberWithInt: kBucketTool],
				 [NSNumber numberWithInt: kGradientTool],
				 nil] retain];
	effectTools =	[[NSArray arrayWithObjects: 
				 [NSNumber numberWithInt: kEffectTool],
				 [NSNumber numberWithInt: kSmudgeTool],
				 [NSNumber numberWithInt: kCloneTool],
				 nil] retain];
	transformTools = [[NSArray arrayWithObjects: 
					 [NSNumber numberWithInt: kEyedropTool],
					 [NSNumber numberWithInt: kCropTool],
					 [NSNumber numberWithInt: kZoomTool],
					 [NSNumber numberWithInt: kPositionTool],
					   nil] retain];
	
	
	return self;
}

- (void)awakeFromNib
{

	// Create the toolbar instance, and attach it to our document window 
    toolbar = [[[NSToolbar alloc] initWithIdentifier: DocToolbarIdentifier] autorelease];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
	[toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
	
    // We are the delegate
    [toolbar setDelegate: self];
	
    // Attach the toolbar to the document window 
    [[document window] setToolbar: toolbar];
	
	[[SeaController utilitiesManager] setToolboxUtility: self for:document];
}

- (void)dealloc
{
	[super dealloc];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
	SeaToolbarItem *toolbarItem = nil;
	
    if ([itemIdent isEqual: SelectionIdentifier]) {
        toolbarItem = [[SeaToolbarItem alloc] initWithItemIdentifier:SelectionIdentifier];
		[toolbarItem setView:selectionTBView];
		[toolbarItem setLabel:@"Selection Tools"];
		[toolbarItem setPaletteLabel:@"Selection Tools"];
		[toolbarItem setMenuFormRepresentation:selectionMenu];
		// set sizes
		[toolbarItem setMinSize: [selectionTBView frame].size];
		[toolbarItem setMaxSize: [selectionTBView frame].size];
	}else if([itemIdent isEqual:DrawIdentifier]){
		toolbarItem = [[SeaToolbarItem alloc] initWithItemIdentifier:DrawIdentifier];
		[toolbarItem setView: drawTBView];
		[toolbarItem setLabel:@"Draw Tools"];
		[toolbarItem setPaletteLabel:@"Draw Tools"];
		[toolbarItem setMenuFormRepresentation:drawMenu];
		[toolbarItem setMinSize: [drawTBView frame].size];
		[toolbarItem setMaxSize: [drawTBView frame].size];
	}else if([itemIdent isEqual:EffectIdentifier]){
		toolbarItem =[[SeaToolbarItem alloc] initWithItemIdentifier:EffectIdentifier];
		[toolbarItem setView:effectTBView];
		[toolbarItem setLabel:	@"Effect Tools"];
		[toolbarItem setPaletteLabel:@"Effect Tools"];
		[toolbarItem setMenuFormRepresentation:effectMenu];
		[toolbarItem setMinSize: [effectTBView frame].size];
		[toolbarItem setMaxSize: [effectTBView frame].size];
	}else if([itemIdent isEqual:TransformIdentifier]){
		toolbarItem = [[SeaToolbarItem alloc] initWithItemIdentifier:TransformIdentifier];
		[toolbarItem setView:transformTBView];
		[toolbarItem setLabel:@"Transform Tools"];
		[toolbarItem setPaletteLabel:@"TransformTools"];
		[toolbarItem setMenuFormRepresentation:transformMenu];
		[toolbarItem setMinSize: [transformTBView frame].size];
		[toolbarItem setMaxSize: [transformTBView frame].size];
	}else if([itemIdent isEqual:ColorsIdentifier]){
		toolbarItem = [[SeaToolbarItem alloc] initWithItemIdentifier:ColorsIdentifier];
		[toolbarItem setView:colorSelectView];
		[toolbarItem setLabel:@"Colors"];
		[toolbarItem setPaletteLabel:@"Colors"];
		[toolbarItem setMenuFormRepresentation:colorsMenu];
		[toolbarItem setMinSize: [colorSelectView frame].size];
		[toolbarItem setMaxSize: [colorSelectView frame].size];
	} else if ([itemIdent isEqual: NewLayerToolbarItemIdentifier]) {
        toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: NewLayerToolbarItemIdentifier label: LOCALSTR(@"new", @"New") image: @"new-tb" toolTip: LOCALSTR(@"new tooltip", @"Add a new layer to the image") target: [[SeaController utilitiesManager] pegasusUtilityFor:document] selector: @selector(addLayer:)] autorelease];
	} else if ([itemIdent isEqual: DuplicateLayerToolbarItemIdentifier]) {
		toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: DuplicateLayerToolbarItemIdentifier label: LOCALSTR(@"duplicate", @"Duplicate") image: @"duplicate-tb" toolTip: LOCALSTR(@"duplicate tooltip", @"Duplicate the current layer") target: [[SeaController utilitiesManager] pegasusUtilityFor:document]  selector: @selector(duplicateLayer:)] autorelease];
	} else if ([itemIdent isEqual: ForwardToolbarItemIdentifier]) {
        toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: ForwardToolbarItemIdentifier label: LOCALSTR(@"forward", @"Forward") image: @"forward-tb" toolTip: LOCALSTR(@"forward tooltip", @"Move the current layer forward") target: [[SeaController utilitiesManager] pegasusUtilityFor:document]  selector: @selector(forward:)] autorelease];
	} else if ([itemIdent isEqual: BackwardToolbarItemIdentifier]) {
        toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: BackwardToolbarItemIdentifier label: LOCALSTR(@"backward", @"Backward") image: @"backward-tb" toolTip: LOCALSTR(@"backward tooltip", @"Move the current layer backward") target: [[SeaController utilitiesManager] pegasusUtilityFor:document]  selector: @selector(backward:)] autorelease];
	} else if ([itemIdent isEqual: DeleteLayerToolbarItemIdentifier]) {
        toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: DeleteLayerToolbarItemIdentifier label: LOCALSTR(@"delete", @"Delete") image: @"delete-tb" toolTip: LOCALSTR(@"delete tooltip", @"Delete the current layer") target: [[SeaController utilitiesManager] pegasusUtilityFor:document]  selector: @selector(deleteLayer:)] autorelease];
	} else if ([itemIdent isEqual: ZoomInToolbarItemIdentifier]) {
        toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: ZoomInToolbarItemIdentifier label: LOCALSTR(@"zoom in", @"Zoom In") image: @"zoomIn" toolTip: LOCALSTR(@"zoom in tooltip", @"Zoom in on the current view") target: [document docView] selector: @selector(zoomIn:)] autorelease];
	} else if ([itemIdent isEqual: ZoomOutToolbarItemIdentifier]) {
        toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: ZoomOutToolbarItemIdentifier label: LOCALSTR(@"zoom out", @"Zoom Out") image: @"zoomOut" toolTip: LOCALSTR(@"zoom out tooltip", @"Zoom out from the current view") target: [document docView] selector: @selector(zoomOut:)] autorelease];
	} else if ([itemIdent isEqual: ActualSizeToolbarItemIdentifier]) {
        toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: ActualSizeToolbarItemIdentifier label: LOCALSTR(@"actual size", @"Actual Size") image: @"actualSize" toolTip: LOCALSTR(@"actual size tooltip", @"View the document at its actual size") target: [document docView] selector: @selector(zoomNormal:)] autorelease];
	} else if ([itemIdent isEqual: ToggleLayersToolbarItemIdentifier]) {
		toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: ToggleLayersToolbarItemIdentifier label: LOCALSTR(@"toggle layers", @"Layers") image: @"showhidelayers" toolTip: LOCALSTR(@"toggle layers tooltip", @"Show or hide the layers list view") target: [[SeaController utilitiesManager] pegasusUtilityFor:document] selector: @selector(toggleLayers:)] autorelease];
	} else if ([itemIdent isEqual: InspectorToolbarItemIdentifier]) {
        toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: InspectorToolbarItemIdentifier label: LOCALSTR(@"information", @"Information") image: @"inspector" toolTip: LOCALSTR(@"information tooltip", @"Show or hide point information") target: [[SeaController utilitiesManager] infoUtilityFor:document]  selector: @selector(toggle:)] autorelease];
	} else if ([itemIdent isEqual: FloatAnchorToolbarItemIdentifier]) {
        toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: FloatAnchorToolbarItemIdentifier label: LOCALSTR(@"float", @"Float") image: @"float-tb" toolTip: LOCALSTR(@"float tooltip", @"Float or anchor the current selection") target: [document contents] selector: @selector(toggleFloatingSelection)] autorelease];
	} else if ([itemIdent isEqual: DuplicateSelectionToolbarItemIdentifier]) {
        toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: DuplicateSelectionToolbarItemIdentifier label: LOCALSTR(@"duplicate", @"Duplicate") image: @"duplicatesel-tb" toolTip: LOCALSTR(@"duplicate tooltip", @"Duplicate the current selection") target: [document contents] selector: @selector(duplicate:)] autorelease];
	} else if ([itemIdent isEqual: SelectNoneToolbarItemIdentifier]) {
        toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: SelectNoneToolbarItemIdentifier label: LOCALSTR(@"select none", @"None") image: @"none-tb" toolTip: LOCALSTR(@"select none tooltip", @"Select nothing") target: [document docView]  selector: @selector(selectNone:)] autorelease];
	} else if ([itemIdent isEqual: SelectAllToolbarItemIdentifier]) {
        toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: SelectAllToolbarItemIdentifier label: LOCALSTR(@"select all", @"All") image: @"selectall" toolTip: LOCALSTR(@"select All tooltip", @"Select all of the current layer") target: [document docView]  selector: @selector(selectAll:)] autorelease];
	} else if ([itemIdent isEqual: SelectInverseToolbarItemIdentifier]) {
        toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: SelectInverseToolbarItemIdentifier label: LOCALSTR(@"select none", @"Inverse") image: @"selectinverse" toolTip: LOCALSTR(@"select inverse tooltip", @"Select the inverse of the current selection") target: [document docView]  selector: @selector(selectInverse:)] autorelease];
	} else if ([itemIdent isEqual: SelectAlphaToolbarItemIdentifier]) {
        toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: SelectAlphaToolbarItemIdentifier label: LOCALSTR(@"select alpha", @"Alpha") image: @"selectalpha" toolTip: LOCALSTR(@"select alpha tooltip", @"Select a copy of the alpha transparency channel") target: [document docView]  selector: @selector(selectOpaque:)] autorelease];
    }
	
	return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects: 
			NSToolbarFlexibleSpaceItemIdentifier,
			SelectionIdentifier,
			DrawIdentifier,
			EffectIdentifier,
			TransformIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			ColorsIdentifier,
			nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
	return [NSArray arrayWithObjects:
			SelectionIdentifier,
			DrawIdentifier,
			EffectIdentifier,
			TransformIdentifier,
			ColorsIdentifier,
			//NewLayerToolbarItemIdentifier,
			//DuplicateLayerToolbarItemIdentifier,
			//ForwardToolbarItemIdentifier,
			//BackwardToolbarItemIdentifier,
			//DeleteLayerToolbarItemIdentifier,
			//ToggleLayersToolbarItemIdentifier,
			ZoomInToolbarItemIdentifier,
			ZoomOutToolbarItemIdentifier,
			ActualSizeToolbarItemIdentifier,
			//InspectorToolbarItemIdentifier,
			FloatAnchorToolbarItemIdentifier,
			DuplicateSelectionToolbarItemIdentifier,
			SelectNoneToolbarItemIdentifier,		
			SelectAllToolbarItemIdentifier,		
			SelectInverseToolbarItemIdentifier,		
			SelectAlphaToolbarItemIdentifier,		
			NSToolbarCustomizeToolbarItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarSeparatorItemIdentifier,
			nil];
}

- (NSColor *)foreground
{
	return foreground;
}

- (NSColor *)background
{
	return background;
}

- (void)setForeground:(NSColor *)color
{
	[foreground autorelease];
	foreground = [color retain];
	if (delay_timer) {
		[delay_timer invalidate];
		[delay_timer autorelease];
	}
	delay_timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:[[document tools] getTool:kTextTool]  selector:@selector(preview:) userInfo:NULL repeats:NO];
	[delay_timer retain];
	[(StatusUtility *)[[SeaController utilitiesManager] statusUtilityFor:document] updateQuickColor];
}

- (void)setBackground:(NSColor *)color
{
	[background autorelease];
	background = [color retain];
}

- (id)colorView
{
	return colorSelectView;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return YES;
}

- (void)activate
{
	if(tool == -1)
		[self changeToolTo:kRectSelectTool];
	// Set the document appropriately
	[colorSelectView setDocument:document];
		
	// Then pretend a tool change
	[self update:YES];
}

- (void)deactivate
{
	int i;
	
	[colorSelectView setDocument:document];
	for (i = kFirstSelectionTool; i <= kLastSelectionTool; i++) {
		[[toolbox cellWithTag:i] setEnabled:YES];
	}
}

- (void)update:(BOOL)full
{
	int i;
	
	if (full) {
		/* Disable or enable the tool */
		if ([[document selection] floating]) {
			for (i = kFirstSelectionTool; i <= kLastSelectionTool; i++) {
				[[selectionTBView cellAtRow:0 column:i] setEnabled:NO ];				
			}
			[selectionMenu setEnabled:NO];
		}
		else {
			for (i = kFirstSelectionTool; i <= kLastSelectionTool; i++) {
				[[selectionTBView cellAtRow:0 column: i] setEnabled:YES];
			}
			[selectionMenu setEnabled:YES];
		}
		// Implement the change
		[[document docView] setNeedsDisplay:YES];
		[optionsUtility update];
		[[SeaController seaHelp] updateInstantHelp:tool];

	}
	[colorSelectView update];
}

- (int)tool
{
	return tool;
}

- (IBAction)selectToolUsingTag:(id)sender
{
	[self changeToolTo:[sender tag] % 100];
}

- (IBAction)selectToolFromSender:(id)sender
{
	[self changeToolTo:[[sender selectedCell] tag] % 100];
}

- (void)changeToolTo:(int)newTool
{
	BOOL updateCrop = NO;
	
	[[document helpers] endLineDrawing];
	if (tool == kCropTool || newTool == kCropTool) {
		updateCrop = YES;
		[[document docView] setNeedsDisplay:YES];
	}
	if (tool == newTool && [[NSApp currentEvent] type] == NSLeftMouseUp && [[NSApp currentEvent] clickCount] > 1) {
		[[[SeaController utilitiesManager] optionsUtilityFor:document] show:NULL];
	} else {
		tool = newTool;
		// Deselect the old tool
		int i;
		for(i = 0; i < [selectionTools count]; i++)
			[[selectionTBView cellAtRow:0 column:i] setImage:[NSImage imageNamed:[NSString stringWithFormat:@"%d-%@", [[selectionTBView cellAtRow:0 column:i] tag] % 100, ([[selectionTBView cellAtRow:0 column:i] tag] % 100 == tool ? @"sel" : @"not" )]]] ;
		for(i = 0; i < [drawTools count]; i++)
			[[drawTBView cellAtRow:0 column:i] setImage:[NSImage imageNamed:[NSString stringWithFormat:@"%d-%@", [[drawTBView cellAtRow:0 column:i] tag] % 100, ([[drawTBView cellAtRow:0 column:i] tag] % 100 == tool ? @"sel" : @"not" )]]] ;
		for(i = 0; i < [effectTools count]; i++)
			[[effectTBView cellAtRow:0 column:i] setImage:[NSImage imageNamed:[NSString stringWithFormat:@"%d-%@", [[effectTBView cellAtRow:0 column:i] tag] % 100, ([[effectTBView cellAtRow:0 column:i] tag] % 100 == tool ? @"sel" : @"not" )]]] ;
		for(i = 0; i < [transformTools count]; i++)
			[[transformTBView cellAtRow:0 column:i] setImage:[NSImage imageNamed:[NSString stringWithFormat:@"%d-%@", [[transformTBView cellAtRow:0 column:i] tag] % 100, ([[transformTBView cellAtRow:0 column:i] tag] % 100 == tool ? @"sel" : @"not" )]]] ;

		[self update:YES];
	}
	if (updateCrop) [[[SeaController utilitiesManager] infoUtilityFor:document] update];
}

-(void)floatTool
{
	// Show the banner
	[[document warnings] showFloatBanner];
	
	oldTool = tool;
	[self changeToolTo: kPositionTool];
}

-(void)anchorTool
{
	// Hide the banner
	[[document warnings] hideFloatBanner];
	if (oldTool != -1) [self changeToolTo: oldTool];
}

- (void)setEffectEnabled:(BOOL)enable
{
	[[effectTBView cellAtRow: 0 column: kEffectTool] setEnabled: enable];
}

- (BOOL)validateMenuItem:(id)menuItem
{	
	if ([menuItem tag] >= 600 && [menuItem tag] < 700) {
		[menuItem setState:([menuItem tag] == tool + 600)];
	}
	
	return YES;
}


@end

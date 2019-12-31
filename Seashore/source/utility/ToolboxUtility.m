#import "ToolboxUtility.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "SeaView.h"
#import "ColorSelectView.h"
#import "SeaController.h"
#import "SeaHelp.h"
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
#import "AbstractTool.h"

static NSString*	DocToolbarIdentifier 	= @"Document Toolbar Instance Identifier";

static NSString*	SelectionIdentifier 	= @"Selection  Item Identifier";
static NSString*	DrawIdentifier 	= @"Draw Item Identifier";
static NSString*    EffectIdentifier = @"Effect Item Identifier";
static NSString*    TransformIdentifier = @"Transform Item Identifier";
static NSString*	ColorsIdentifier = @"Colors Item Identifier";

static NSString*    SelectionEditIdentifier = @"Selection Edit Identifier";

@implementation ToolboxUtility

- (id)init
{
    foreground = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    background = [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0];
	delay_timer = NULL;
	tool = -1;
	oldTool = -1;
	selectionTools = [NSArray arrayWithObjects:
					  [NSNumber numberWithInt: kRectSelectTool],
					  [NSNumber numberWithInt: kEllipseSelectTool],
					  [NSNumber numberWithInt: kLassoTool],
					  [NSNumber numberWithInt: kPolygonLassoTool],
					  [NSNumber numberWithInt: kWandTool],
                      nil];
	drawTools =	[NSArray arrayWithObjects:
				 [NSNumber numberWithInt: kPencilTool],
				 [NSNumber numberWithInt: kBrushTool],
				 [NSNumber numberWithInt: kTextTool],
				 [NSNumber numberWithInt: kEraserTool],
				 [NSNumber numberWithInt: kBucketTool],
				 [NSNumber numberWithInt: kGradientTool],
                 nil];
	effectTools =	[NSArray arrayWithObjects:
				 [NSNumber numberWithInt: kEffectTool],
				 [NSNumber numberWithInt: kSmudgeTool],
				 [NSNumber numberWithInt: kCloneTool],
                     nil];
	transformTools = [NSArray arrayWithObjects:
					 [NSNumber numberWithInt: kEyedropTool],
					 [NSNumber numberWithInt: kCropTool],
					 [NSNumber numberWithInt: kZoomTool],
					 [NSNumber numberWithInt: kPositionTool],
                      nil];
	
	
	return self;
}

- (void)awakeFromNib
{

	// Create the toolbar instance, and attach it to our document window 
    toolbar = [[NSToolbar alloc] initWithIdentifier: DocToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
	[toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];

    // We are the delegate
    [toolbar setDelegate: self];
	
    // Attach the toolbar to the document window 
    [[document window] setToolbar: toolbar];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    
	NSToolbarItem *toolbarItem = nil;
	
    if ([itemIdent isEqual: SelectionIdentifier]) {
        toolbarItem = [[SeaToolbarItem alloc] initWithItemIdentifier:SelectionIdentifier];
		[toolbarItem setView:selectionTBView];
        [toolbarItem setLabel:@"Selection Tools"];
		[toolbarItem setPaletteLabel:@"Selection Tools"];
		[toolbarItem setMenuFormRepresentation:selectionMenu];
	}else if([itemIdent isEqual:DrawIdentifier]){
		toolbarItem = [[SeaToolbarItem alloc] initWithItemIdentifier:DrawIdentifier];
		[toolbarItem setView: drawTBView];
        [toolbarItem setLabel:@"Draw Tools"];
		[toolbarItem setPaletteLabel:@"Draw Tools"];
		[toolbarItem setMenuFormRepresentation:drawMenu];
	}else if([itemIdent isEqual:EffectIdentifier]){
		toolbarItem =[[SeaToolbarItem alloc] initWithItemIdentifier:EffectIdentifier];
		[toolbarItem setView:effectTBView];
        [toolbarItem setLabel:    @"Effect Tools"];
		[toolbarItem setPaletteLabel:@"Effect Tools"];
		[toolbarItem setMenuFormRepresentation:effectMenu];
	}else if([itemIdent isEqual:TransformIdentifier]){
		toolbarItem = [[SeaToolbarItem alloc] initWithItemIdentifier:TransformIdentifier];
		[toolbarItem setView:transformTBView];
        [toolbarItem setLabel:@"Transform Tools"];
		[toolbarItem setPaletteLabel:@"Transform Tools"];
		[toolbarItem setMenuFormRepresentation:transformMenu];
        [toolbarItem setEnabled:YES];
    }else if([itemIdent isEqual:SelectionEditIdentifier]){
        toolbarItem = [[SeaToolbarItem alloc] initWithItemIdentifier:SelectionEditIdentifier];
        [toolbarItem setView:selectioneditTBView];
        [toolbarItem setLabel:@"Selection Mode"];
        [toolbarItem setPaletteLabel:@"Selection Mode"];
        [toolbarItem setMenuFormRepresentation:selectioneditMenu];
        [toolbarItem setEnabled:YES];
	}else if([itemIdent isEqual:ColorsIdentifier]){
        toolbarItem = [[SeaToolbarItem alloc] initWithItemIdentifier:ColorsIdentifier];
        [toolbarItem setView:colorSelectView];
        [toolbarItem setLabel:@"Colors"];
        [toolbarItem setPaletteLabel:@"Colors"];
        [toolbarItem setMenuFormRepresentation:colorsMenu];
        [toolbarItem setMinSize:NSMakeSize(42,24)];
        [toolbarItem setMaxSize:NSMakeSize(42,24)];
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
			SelectionEditIdentifier,
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
    foreground = color;
	if (delay_timer) {
		[delay_timer invalidate];
	}
	delay_timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:[[document tools] getTool:kTextTool]  selector:@selector(preview:) userInfo:NULL repeats:NO];
}

- (void)setBackground:(NSColor *)color
{
    background = color;
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
	if (full) {
		/* Disable or enable the tool */
		if ([[document selection] floating]) {
			[selectionMenu setEnabled:NO];
		}
		else {
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
    int tag = (int)[sender tag];
	[self changeToolTo:(tag % 100)];
}

- (IBAction)selectToolUsingSegmentTag:(id)sender
{
    int segment = (int)[sender selectedSegment];
    if(segment<0)
        return;
    int tag = (int)[[sender cell] tagForSegment:segment];
    [self changeToolTo:(tag % 100)];
}

- (IBAction)switchSelectionMode:(id)sender {
    int segment = (int)[sender selectedSegment];
    if(segment<0)
        return;
    int tag = (int)[[sender cell] tagForSegment:segment];
    switch(tag) {
        case 271:
            [[document docView] selectNone:sender];
            break;
        case 272:
            [[document docView] selectInverse:sender];
            break;
        case 273:
            [[document docView] selectOpaque:sender];
            break;
        case 270:
            [[document docView] selectAll:sender];
            break;
    }
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
		[[document optionsUtility] show:NULL];
	} else {
        [selectionTBView setSelectedSegment:-1];
        [drawTBView setSelectedSegment:-1];
        [effectTBView setSelectedSegment:-1];
        [transformTBView setSelectedSegment:-1];

		tool = newTool;
        [selectionTBView selectSegmentWithTag:tool];
        [drawTBView selectSegmentWithTag:tool];
        [effectTBView selectSegmentWithTag:tool];
        [transformTBView selectSegmentWithTag:tool];
		[self update:YES];
	}
	if (updateCrop) [[document infoUtility] update];
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
    for(int i=0;i<[effectTBView segmentCount];i++){
        int tag = (int)[[effectTBView cell] tagForSegment:i];
        if(tag==kEffectTool){
            [effectTBView setEnabled:enable forSegment:(NSInteger)i];
        }
    }
}

- (BOOL)validateMenuItem:(id)menuItem
{	
	if ([menuItem tag] >= 600 && [menuItem tag] < 700) {
		[menuItem setState:([menuItem tag] == tool + 600)];
	}
	
	return YES;
}
@end

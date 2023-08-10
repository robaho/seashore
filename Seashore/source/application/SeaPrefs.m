#import "SeaPrefs.h"
#import "SeaDocument.h"
#import "SeaController.h"
#import "InfoUtility.h"
#import "SeaView.h"
#import "Units.h"
#import "ImageToolbarItem.h"
#import "SeaHelpers.h"
#import <IOKit/graphics/IOGraphicsLib.h>
#import <SeaLibrary/SeaLibrary.h>

static NSString*	PrefsToolbarIdentifier 	= @"Preferences Toolbar Instance Identifier";

static NSString*	GeneralPrefsIdentifier 	= @"General Preferences Item Identifier";
static NSString*	NewPrefsIdentifier 	= @"New Preferences Item Identifier";
static NSString*  ColorPrefsIdentifier = @"Color Preferences Item Identifier";

static int GetIntFromDictionaryForKey(CFDictionaryRef desc, CFStringRef key)
{
    CFNumberRef value;
    int num = 0;
    
	if ((value = CFDictionaryGetValue(desc, key)) == NULL || CFGetTypeID(value) != CFNumberGetTypeID())
        return 0;
    CFNumberGetValue(value, kCFNumberIntType, &num);
    
	return num;
}

static NSColor* colorEnumToColor(int colorEnum,float alpha){
    NSColor *result;
    switch (colorEnum) {
        case kCyanColor:
            result = [NSColor colorWithDeviceCyan:1.0 magenta:0.0 yellow:0.0 black:0.0 alpha:alpha];
            break;
        case kMagentaColor:
            result = [NSColor colorWithDeviceCyan:0.0 magenta:1.0 yellow:0.0 black:0.0 alpha:alpha];
            break;
        case kYellowColor:
            result = [NSColor colorWithDeviceCyan:0.0 magenta:0.0 yellow:1.0 black:0.0 alpha:alpha];
            break;
        case kGrayColor:
            result = [NSColor colorWithDeviceRed:.5 green:.5 blue:.5 alpha:alpha];
            break;
        case kWhiteColor:
            result = [NSColor colorWithDeviceRed:1 green:1 blue:1 alpha:alpha];
            break;
        default:
            result = [NSColor colorWithCalibratedWhite:0.0 alpha:alpha];
            break;
    }
    return result;
}

CGDisplayErr GetMainDisplayDPI(float *horizontalDPI, float *verticalDPI)
{
    
    long width = CGDisplayPixelsWide(kCGDirectMainDisplay);
    long height = CGDisplayPixelsHigh(kCGDirectMainDisplay);
    
    CGSize size = CGDisplayScreenSize(kCGDirectMainDisplay);

    const double mmPerInch = 25.4;
    double horizontalSizeInInches = size.width / mmPerInch;
    double verticalSizeInInches = size.height / mmPerInch;

    if (verticalSizeInInches==0 || horizontalSizeInInches==0){
        *horizontalDPI = 72;
        *horizontalDPI = 72;
        return CGDisplayNoErr;
    }
    // Now we can calculate the actual DPI
    // with information from the displayModeDict
    *horizontalDPI = (float)width / horizontalSizeInInches;
    *verticalDPI = (float)height / verticalSizeInInches;
	
    return CGDisplayNoErr;
}

@implementation SeaPrefs 

- (id)init
{
	NSData *tempData;
	float xdpi, ydpi;
	
	// Get bounderies from preferences
	if ([gUserDefaults objectForKey:@"boundaries"] && [gUserDefaults boolForKey:@"boundaries"])
		layerBounds = YES;
	else
		layerBounds = NO;

	// Get bounderies from preferences
	if ([gUserDefaults objectForKey:@"guides"] && ![gUserDefaults boolForKey:@"guides"])
		guides = NO;
	else
		guides = YES;
	
	// Get rulers from preferences
	if ([gUserDefaults objectForKey:@"rulers"] && [gUserDefaults boolForKey:@"rulers"])
		rulers = YES;
	else
		rulers = NO;
	

	// Get the use of the checkerboard pattern
	if ([gUserDefaults objectForKey:@"useCheckerboard"])
		useCheckerboard = [gUserDefaults boolForKey:@"useCheckerboard"];
	else
		useCheckerboard = YES;
	
	//  Get the smartInterpolation
	if ([gUserDefaults objectForKey:@"smartInterpolation"])
		smartInterpolation = [gUserDefaults boolForKey:@"smartInterpolation"];
	else
		smartInterpolation = YES;
	
	//  Get the openUntitled
	if ([gUserDefaults objectForKey:@"openUntitled"])
		openUntitled = [gUserDefaults boolForKey:@"openUntitled"];
	else
		openUntitled = YES;

    //  Get the openUntitled
    if ([gUserDefaults objectForKey:@"zoomToFit"])
        zoomToFitAtOpen = [gUserDefaults boolForKey:@"zoomToFit"];
    else
        zoomToFitAtOpen = YES;

	// Get the selection colour
	selectionColor = kBlackColor;
	if ([gUserDefaults objectForKey:@"selectionColor"])
		selectionColor = [gUserDefaults integerForKey:@"selectionColor"];
	if (selectionColor < 0 || selectionColor >= kMaxColor)
		selectionColor = kBlackColor;

    if ([gUserDefaults objectForKey:@"marchingAnts"])
        marchingAnts = [gUserDefaults boolForKey:@"marchingAnts"];
    else
        marchingAnts = NO;

    if ([gUserDefaults objectForKey:@"layerBoundaryLines"])
        layerBoundaryLines = [gUserDefaults boolForKey:@"layerBoundaryLines"];
    else
        layerBoundaryLines = NO;

	// If the layer bounds are white (the alternative is the selection color)
	whiteLayerBounds = YES;
	if ([gUserDefaults objectForKey:@"whiteLayerBounds"])
		whiteLayerBounds = [gUserDefaults boolForKey:@"whiteLayerBounds"];

	// Get the guide colour
	guideColor = kYellowColor;
	if ([gUserDefaults objectForKey:@"guideColor"])
		guideColor = [gUserDefaults integerForKey:@"guideColor"];
	if (guideColor < 0 || guideColor >= kMaxColor)
		guideColor = kYellowColor;
	
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    
	// Determine the initial color (from preferences if possible)
	if ([gUserDefaults objectForKey:@"windowBackColor"] == NULL) {
        if(osxMode && [osxMode isEqualToString:@"@Dark"]){
            windowBackColor = [NSColor windowBackgroundColor];
        } else {
            windowBackColor = [NSColor controlShadowColor];
        }
	}
	else {
		tempData = [gUserDefaults dataForKey:@"windowBackColor"];
		if (tempData != nil)
            windowBackColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:tempData];
	}
    
    // Determine the initial color (from preferences if possible)
    if ([gUserDefaults objectForKey:@"transparency color data"] == NULL) {
        // use reverse defaults from window back
        if(osxMode && ![osxMode isEqualToString:@"@Dark"]){
            transparencyColor = [NSColor windowBackgroundColor];
        } else {
            transparencyColor = [NSColor controlShadowColor];
        }
    }
    else {
        tempData = [gUserDefaults dataForKey:@"transparency color data"];
        if (tempData != nil)
            transparencyColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:tempData];
    }
	
	// Get the default document size
	width = 512;
	if ([gUserDefaults objectForKey:@"width"])
		width = [gUserDefaults integerForKey:@"width"];
	height = 384;
	if ([gUserDefaults objectForKey:@"height"])
		height = [gUserDefaults integerForKey:@"height"];
	
	// The resolution for new documents
	resolution = 72;
	if ([gUserDefaults objectForKey:@"resolution"])
		resolution = [gUserDefaults integerForKey:@"resolution"];
	if (resolution != 72 && resolution != 96 && resolution != 150 && resolution != 300)
		resolution = 72;
	
	// Units used in the new document
	newUnits = kPixelUnits;
	if ([gUserDefaults objectForKey:@"units"])
		newUnits = [gUserDefaults integerForKey:@"units"];
	
	// Mode used for the new document
	mode = 0;
	if ([gUserDefaults objectForKey:@"mode"])
		mode = [gUserDefaults integerForKey:@"mode"];

	if ([gUserDefaults objectForKey:@"transparentBackground"])
		transparentBackground = [gUserDefaults boolForKey:@"transparentBackground"];
	else
		transparentBackground = NO;

	// Get the mouseCoalescing
	if ([gUserDefaults objectForKey:@"newMouseCoalescing"])
		mouseCoalescing = [gUserDefaults boolForKey:@"newMouseCoalescing"];
	else
		mouseCoalescing = YES;
		
	// Get the preciseCursor
	if ([gUserDefaults objectForKey:@"preciseCursor"])
		preciseCursor = [gUserDefaults boolForKey:@"preciseCursor"];
	else
		preciseCursor = NO;

    // Get the preciseCursor
    if ([gUserDefaults objectForKey:@"undoLevels"])
        undoLevels = [gUserDefaults integerForKey:@"undoLevels"];
    else
        undoLevels = 0;


    // Get the preciseCursor
    if ([gUserDefaults objectForKey:@"canvasShadow"])
        showCanvasShadow = [gUserDefaults boolForKey:@"canvasShadow"];
    else
        showCanvasShadow = TRUE;

    useLargerFonts = [gUserDefaults boolForKey:@"useLargerFonts"];
    defaultControlSize = [self controlSize];

	// Get the main screen resolution
	if (GetMainDisplayDPI(&xdpi, &ydpi)) {
		xdpi = ydpi = 72.0;
		NSLog(@"Error finding screen resolution.");
	}
	mainScreenResolution.x = (int)roundf(xdpi);
	mainScreenResolution.y = (int)roundf(ydpi);

	return self;
}

- (void)awakeFromNib
{
	NSString *fontName;
	float fontSize;
	
	// Get the font name and size
	if ([gUserDefaults objectForKey:@"fontName"] && [gUserDefaults objectForKey:@"fontSize"]) {
		fontName = [gUserDefaults objectForKey:@"fontName"];
		fontSize = [gUserDefaults floatForKey:@"fontSize"];
		[[NSFontManager sharedFontManager] setSelectedFont:[NSFont fontWithName:fontName size:fontSize] isMultiple:NO];
	}
	else {
		[[NSFontManager sharedFontManager] setSelectedFont:[NSFont messageFontOfSize:0] isMultiple:NO];
	}

    if ([gUserDefaults objectForKey:@"rightButtonDrawsBGColor"])
        [rightButtonDrawsBGColorCheckbox setState:[gUserDefaults boolForKey:@"rightButtonDrawsBGColor"]];
    else
        [rightButtonDrawsBGColorCheckbox setState:FALSE];

    if ([gUserDefaults objectForKey:@"useLargerFonts"])
        [useLargerFontsCheckbox setState:[gUserDefaults boolForKey:@"useLargerFonts"]];
    else
        [useLargerFontsCheckbox setState:FALSE];

	// Create the toolbar instance, and attach it to our document window
    toolbar = [[NSToolbar alloc] initWithIdentifier: PrefsToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];

    // We are the delegate
    [toolbar setDelegate: self];

    // Attach the toolbar to the document window 
    [panel setToolbar: toolbar];
	[toolbar setSelectedItemIdentifier:GeneralPrefsIdentifier];
	[(NSPanel *)panel setContentView: generalPrefsView];

	// Register to recieve the terminate message when Seashore quits
	[controller registerForTermination:self];
}

- (void)terminate
{
	NSFont *font = [[NSFontManager sharedFontManager] selectedFont];

	// For some unknown reason NSColorListMode causes a crash on boot
	NSColorPanel* colorPanel = [NSColorPanel sharedColorPanel];
	if([colorPanel mode] == NSColorListModeColorPanel){
		[colorPanel setMode:NSWheelModeColorPanel];
	}
	
	[gUserDefaults setObject:(guides ? @"YES" : @"NO") forKey:@"guides"];
	[gUserDefaults setObject:(layerBounds ? @"YES" : @"NO") forKey:@"boundaries"];
	[gUserDefaults setObject:(rulers ? @"YES" : @"NO") forKey:@"rulers"];
	[gUserDefaults setObject:(smartInterpolation ? @"YES" : @"NO") forKey:@"smartInterpolation"];
	[gUserDefaults setObject:(openUntitled ? @"YES" : @"NO") forKey:@"openUntitled"];
    [gUserDefaults setObject:(zoomToFitAtOpen ? @"YES" : @"NO") forKey:@"zoomToFit"];
	[gUserDefaults setObject:(mouseCoalescing ? @"YES" : @"NO") forKey:@"newMouseCoalescing"];
	[gUserDefaults setObject:(preciseCursor ? @"YES" : @"NO") forKey:@"preciseCursor"];
	[gUserDefaults setObject:(transparentBackground ? @"YES" : @"NO") forKey:@"transparentBackground"];
	[gUserDefaults setObject:(useCheckerboard ? @"YES" : @"NO") forKey:@"useCheckerboard"];
	[gUserDefaults setObject:[NSArchiver archivedDataWithRootObject:windowBackColor] forKey:@"windowBackColor"];
    [gUserDefaults setObject:[NSArchiver archivedDataWithRootObject:transparencyColor] forKey:@"transparency color data"];
	[gUserDefaults setInteger:selectionColor forKey:@"selectionColor"];
    [gUserDefaults setBool:marchingAnts forKey:@"marchingAnts"];
    [gUserDefaults setBool:layerBoundaryLines forKey:@"layerBoundaryLines"];
	[gUserDefaults setObject:(whiteLayerBounds ? @"YES" : @"NO") forKey:@"whiteLayerBounds"];
	[gUserDefaults setInteger:guideColor forKey:@"guideColor"];
	[gUserDefaults setInteger:width forKey:@"width"];
	[gUserDefaults setInteger:height forKey:@"height"];
	[gUserDefaults setInteger:resolution forKey:@"resolution"];
	[gUserDefaults setInteger:newUnits forKey:@"units"];
	[gUserDefaults setInteger:mode forKey:@"mode"];
    [gUserDefaults setInteger:undoLevels forKey:@"undoLevels"];
	[gUserDefaults setObject:[font fontName] forKey:@"fontName"];
	[gUserDefaults setFloat:[font pointSize] forKey:@"fontSize"];
    [gUserDefaults setBool:showCanvasShadow forKey:@"canvasShadow"];
    [gUserDefaults setBool:[rightButtonDrawsBGColorCheckbox state] forKey:@"rightButtonDrawsBGColor"];
    [gUserDefaults setBool:[useLargerFontsCheckbox state] forKey:@"useLargerFonts"];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
	NSToolbarItem *toolbarItem = nil;

    if ([itemIdent isEqual: GeneralPrefsIdentifier]) {
        toolbarItem = [[ImageToolbarItem alloc] initWithItemIdentifier: GeneralPrefsIdentifier label: LOCALSTR(@"general", @"General") image: @"GeneralPrefsIcon" toolTip: LOCALSTR(@"general prefs tooltip", @"General application settings") target: self selector: @selector(generalPrefs)];
	} else if ([itemIdent isEqual: NewPrefsIdentifier]) {
        toolbarItem = [[ImageToolbarItem alloc] initWithItemIdentifier: NewPrefsIdentifier label: LOCALSTR(@"new images", @"New Images") image: @"NewPrefsIcon" toolTip: LOCALSTR(@"new prefs tooltip", @"Settings for new images") target: self selector: @selector(newPrefs)];
	} else if ([itemIdent isEqual: ColorPrefsIdentifier]) {
        toolbarItem = [[ImageToolbarItem alloc] initWithItemIdentifier: ColorPrefsIdentifier label: LOCALSTR(@"color", @"Colors") image: @"ColorPrefsIcon" toolTip: LOCALSTR(@"color prefs tooltip", @"Display colors") target: self selector: @selector(colorPrefs)];
	}
	return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects: GeneralPrefsIdentifier, NewPrefsIdentifier, ColorPrefsIdentifier, nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
	return [NSArray arrayWithObjects: GeneralPrefsIdentifier, NewPrefsIdentifier, ColorPrefsIdentifier, NSToolbarCustomizeToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers: (NSToolbar *) toolbar;
{
    return [NSArray arrayWithObjects: GeneralPrefsIdentifier, NewPrefsIdentifier, ColorPrefsIdentifier, nil];
}

- (void) generalPrefs {
	[(NSPanel *)panel setContentView: generalPrefsView];
}

- (void) newPrefs {
	[(NSPanel *)panel setContentView: newPrefsView];
}

- (void) colorPrefs {
    [(NSPanel *)panel setContentView: colorPrefsView];
}

- (IBAction)show:(id)sender
{
	// Set the existing settings
	[newUnitsMenu selectItemAtIndex: newUnits];
	[heightValue setStringValue:StringFromPixels(height, newUnits, resolution)];
	[widthValue setStringValue:StringFromPixels(width, newUnits, resolution)];
	[heightUnits setStringValue:UnitsString(newUnits)];
	[resolutionMenu selectItemAtIndex:[resolutionMenu indexOfItemWithTag:resolution]];
	[modeMenu selectItemAtIndex: mode];
	[checkerboardMatrix selectCellAtRow: useCheckerboard column: 0];
	[layerBoundsMatrix selectCellAtRow: whiteLayerBounds column: 0];
	[windowBackWell setColor:windowBackColor];
    [transparencyColorWell setColor:transparencyColor];
	[transparentBackgroundCheckbox setState:transparentBackground];
	[smartInterpolationCheckbox setState:smartInterpolation];
	[openUntitledCheckbox setState:openUntitled];
    [zoomToFitAtOpenCheckbox setState:zoomToFitAtOpen];
	[coalescingCheckbox setState:mouseCoalescing];
	[preciseCursorCheckbox setState:preciseCursor];
	[selectionColorMenu selectItemAtIndex:selectionColor];
    [marchingAntsCheckbox setState:marchingAnts];
    [layerBoundaryLinesCheckbox setState:layerBoundaryLines];
	[guideColorMenu selectItemAtIndex:guideColor];
    [undoLevelsInput setIntValue:undoLevels];
    [canvasShadowCheckbox setState:showCanvasShadow];

	// Display the preferences dialog
	[panel center];
	[panel makeKeyAndOrderFront: self];
}

-(IBAction)setWidth:(id)sender
{
	int newWidth = PixelsFromFloat([widthValue floatValue],newUnits,resolution);
	
	// Don't accept rediculous widths
	if (newWidth < kMinImageSize || newWidth > kMaxImageSize) { 
		NSBeep(); 
		[widthValue setStringValue:StringFromPixels(width, newUnits, resolution)];
	}
	else {
		width = newWidth;
	}

    [self settingsChanged:sender];
}

-(IBAction)setHeight:(id)sender
{
	int newHeight =  PixelsFromFloat([heightValue floatValue],newUnits,resolution);

	// Don't accept rediculous heights
	if (newHeight < kMinImageSize || newHeight > kMaxImageSize) { 
		NSBeep(); 
		[heightValue setStringValue:StringFromPixels(height, newUnits, resolution)];
	}
	else {
		height = newHeight;
	}

    [self settingsChanged:sender];
}

-(IBAction)setNewUnits:(id)sender
{
	newUnits = [sender tag] % 10;
	[heightValue setStringValue:StringFromPixels(height, newUnits, resolution)];
	[widthValue setStringValue:StringFromPixels(width, newUnits, resolution)];	
	[heightUnits setStringValue:UnitsString(newUnits)];
    [self settingsChanged:sender];
}

-(IBAction)changeUnits:(id)sender
{
	SeaDocument *document = gCurrentDocument;
	[document changeMeasuringStyle:[sender tag] % 10];
	[[document scrollView] updateRulers];
	[[document infoUtility] update];
	[[document statusUtility] update];
}

-(IBAction)setResolution:(id)sender
{
	resolution = [[resolutionMenu selectedItem] tag];
	width =  PixelsFromFloat([widthValue floatValue],newUnits,resolution);
	height =  PixelsFromFloat([heightValue floatValue],newUnits,resolution);
    [self settingsChanged:sender];
}

-(IBAction)setMode:(id)sender
{
	mode = [[modeMenu selectedItem] tag];
    [self settingsChanged:sender];
}

-(IBAction)setTransparentBackground:(id)sender
{
	transparentBackground = [transparentBackgroundCheckbox state];
    [self settingsChanged:sender];
}

-(IBAction)setSmartInterpolation:(id)sender
{
	smartInterpolation = [smartInterpolationCheckbox state];
    [self settingsChanged:sender];
}

-(IBAction)setOpenUntitled:(id)sender
{
	openUntitled = [openUntitledCheckbox state];
    [self settingsChanged:sender];
}

-(IBAction)setZoomToFitAtOpen:(id)sender
{
    zoomToFitAtOpen = [zoomToFitAtOpenCheckbox state];
    [self settingsChanged:sender];
}

-(IBAction)setMouseCoalescing:(id)sender
{
	mouseCoalescing = [coalescingCheckbox state];
    [self settingsChanged:sender];
}

-(IBAction)setPreciseCursor:(id)sender
{
	preciseCursor = [preciseCursorCheckbox state];
    [self settingsChanged:sender];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	if ([panel isVisible]) {
		[self setWidth: self];
		[self setHeight: self];
	}
}

- (BOOL)layerBounds
{
	return layerBounds;
}

- (int)undoLevels
{
    return undoLevels;
}

- (BOOL)guides
{
	return guides;
}

- (BOOL)rulers
{
	return rulers;
}

- (BOOL)smartInterpolation
{
	return smartInterpolation;
}

- (IBAction)toggleBoundaries:(id)sender
{
	layerBounds = !layerBounds;
    [self settingsChanged:sender];
}

- (IBAction)toggleGuides:(id)sender
{
	guides = !guides;
    [self settingsChanged:sender];
}
		
- (IBAction)toggleRulers:(id)sender
{
	rulers = !rulers;
    [self settingsChanged:sender];
}

- (IBAction)checkerboardChanged:(id)sender
{
	useCheckerboard = [sender selectedRow];
    [self settingsChanged:sender];
}

- (BOOL) useCheckerboard
{
	return useCheckerboard;
}

- (IBAction)defaultWindowBack:(id)sender
{
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    if(osxMode && [osxMode isEqualToString:@"@Dark"]){
        windowBackColor = [NSColor windowBackgroundColor];
    } else {
        windowBackColor = [NSColor controlShadowColor];
    }

	[windowBackWell setColor:windowBackColor];
    [self settingsChanged:sender];
}

- (IBAction)windowBackChanged:(id)sender
{
    windowBackColor = [windowBackWell color];
    [self settingsChanged:sender];
}

- (IBAction)transparencyColorChanged:(id)sender
{
    transparencyColor = [transparencyColorWell color];
    [self settingsChanged:sender];
}

- (IBAction)undoLevelsChanged:(id)sender {
    undoLevels = [undoLevelsInput intValue];
    [self settingsChanged:sender];
}

- (NSColor *)windowBack
{
	return windowBackColor;
}

- (NSColor *)transparencyColor
{
    return transparencyColor;
}

- (NSColor *)selectionColor:(float)alpha
{	
    NSColor *result = colorEnumToColor(selectionColor,alpha);
	result = [result colorUsingColorSpace:MyRGBCS];
	
	return result;
}

-(BOOL)marchingAnts
{
    return marchingAnts;
}

-(BOOL)layerBoundaryLines
{
    return layerBoundaryLines;
}

-(BOOL)showCanvasShadow
{
    return showCanvasShadow;
}

- (int)selectionColorIndex
{
	return selectionColor;
}

- (IBAction)selectionColorChanged:(id)sender
{
    marchingAnts = [marchingAntsCheckbox state];
    layerBoundaryLines = [layerBoundaryLinesCheckbox state];
	selectionColor = [selectionColorMenu indexOfSelectedItem];
    showCanvasShadow = [canvasShadowCheckbox state];
    [self settingsChanged:sender];
}

- (BOOL)whiteLayerBounds
{
	return whiteLayerBounds;
}

- (IBAction)layerBoundsColorChanged:(id)sender
{
	whiteLayerBounds = [sender selectedRow];
    [self settingsChanged:sender];
}

- (NSColor *)guideColor:(float)alpha
{	
    NSColor *result = colorEnumToColor(guideColor,alpha);
	result = [result colorUsingColorSpace:MyRGBCS];
	
	return result;
}

- (int)guideColorIndex
{
	return guideColor;
}

- (IBAction)guideColorChanged:(id)sender
{
	guideColor = [guideColorMenu indexOfSelectedItem];
    [self settingsChanged:sender];
}

- (IBAction)rotateSelectionColor:(id)sender
{
	selectionColor = (selectionColor + 1) % kMaxColor;
	// Set the selection colour correctly
	[selectionColorMenu selectItemAtIndex:selectionColor];

    [self settingsChanged:sender];
}

- (IBAction)settingsChanged:(id)sender
{
    NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
    for (SeaDocument *doc in documents) {
        [[doc docView] setNeedsDisplay:YES];
        [[[[doc docView] enclosingScrollView] contentView] setNeedsDisplay:TRUE];
    }
}
- (BOOL)mouseCoalescing
{
	return mouseCoalescing;
}

- (BOOL)preciseCursor
{
	return preciseCursor;
}

- (IntSize)size
{
	IntSize result = IntMakeSize(width, height);
	
	return result;
}

- (BOOL)rightButtonDrawsBGColor {
    return [rightButtonDrawsBGColorCheckbox state];
}

- (BOOL)useLargerFonts {
    return [useLargerFontsCheckbox state];
}

- (NSControlSize)controlSize {
    return useLargerFonts ? NSControlSizeSmall : NSControlSizeMini;
}

- (int)resolution
{
	switch (resolution) {
		case 72:
			return 0;
		break;
		case 96:
			return 1;
		break;
		case 150:
			return 2;
		break;
		case 300:
			return 3;
		break;
		default:
			return 0;
		break;
	}
}

- (int) newUnits
{
	return newUnits;
}

- (int)mode
{
	return mode;
}

- (IntPoint)screenResolution
{
    return mainScreenResolution;
}

- (BOOL)transparentBackground
{
	return transparentBackground;
}

- (BOOL)openUntitled
{
	return openUntitled;
}

- (BOOL)zoomToFitAtOpen
{
    return zoomToFitAtOpen;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	// Set the boundaries menu item appropriately
	if ([menuItem tag] == 225) {
		if (layerBounds)
			[menuItem setTitle:LOCALSTR(@"hide boundaries", @"Hide Layer Bounds")];
		else
			[menuItem setTitle:LOCALSTR(@"show boundaries", @"Show Layer Bounds")];
	}

	// Set the position guides menu item appropriately
	if ([menuItem tag] == 371) {
		if (guides)
			[menuItem setTitle:LOCALSTR(@"hide guides", @"Hide Guides")];
		else
			[menuItem setTitle:LOCALSTR(@"show guides", @"Show Guides")];
	}
	
	// Set the rulers menu item appropriately
	if ([menuItem tag] == 370) {
		if (rulers)
			[menuItem setTitle:LOCALSTR(@"hide rulers", @"Hide Rulers")];
		else
			[menuItem setTitle:LOCALSTR(@"show rulers", @"Show Rulers")];
	}

	if ([menuItem tag] >= 710 && [menuItem tag] < 720) {		
		[menuItem setState:[gCurrentDocument measureStyle] + 710 == [menuItem tag]];
	}
	
	return YES;
}

@end

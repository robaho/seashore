#import "SeaPrefs.h"
#import "SeaDocument.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "InfoUtility.h"
#import "SeaWarning.h"
#import "SeaView.h"
#import "Units.h"
#import "ImageToolbarItem.h"
#import "WindowBackColorWell.h"
#import "SeaHelpers.h"
#import <IOKit/graphics/IOGraphicsLib.h>

enum {
	kIgnoreResolution,
	kUse72dpiResolution,
	kUseScreenResolution
};

int memoryCacheSize;

IntPoint gScreenResolution;

static NSString*	PrefsToolbarIdentifier 	= @"Preferences Toolbar Instance Identifier";

static NSString*	GeneralPrefsIdentifier 	= @"General Preferences Item Identifier";
static NSString*	NewPrefsIdentifier 	= @"New Preferences Item Identifier";
static NSString*    ColorPrefsIdentifier = @"Color Preferences Item Identifier";

static int GetIntFromDictionaryForKey(CFDictionaryRef desc, CFStringRef key)
{
    CFNumberRef value;
    int num = 0;
    
	if ((value = CFDictionaryGetValue(desc, key)) == NULL || CFGetTypeID(value) != CFNumberGetTypeID())
        return 0;
    CFNumberGetValue(value, kCFNumberIntType, &num);
    
	return num;
}

CGDisplayErr GetMainDisplayDPI(float *horizontalDPI, float *verticalDPI)
{
    CGDisplayErr err = kCGErrorFailure;
    io_connect_t displayPort;
    CFDictionaryRef displayDict;
	CFDictionaryRef displayModeDict;
	CGDirectDisplayID displayID;
	
	// Get the main display
	displayModeDict = CGDisplayCurrentMode(kCGDirectMainDisplay);
	displayID = kCGDirectMainDisplay;
	
    // Grab a connection to IOKit for the requested display
    displayPort = CGDisplayIOServicePort( displayID );
    if ( displayPort != MACH_PORT_NULL ) {
	
        // Find out what IOKit knows about this display
        displayDict = IOCreateDisplayInfoDictionary(displayPort, 0);
        if ( displayDict != NULL ) {
            const double mmPerInch = 25.4;
            double horizontalSizeInInches = (double)GetIntFromDictionaryForKey(displayDict, CFSTR(kDisplayHorizontalImageSize)) / mmPerInch;
            double verticalSizeInInches = (double)GetIntFromDictionaryForKey(displayDict, CFSTR(kDisplayVerticalImageSize)) / mmPerInch;

            // Make sure to release the dictionary we got from IOKit
            CFRelease(displayDict);

            // Now we can calculate the actual DPI
            // with information from the displayModeDict
            *horizontalDPI = (float)GetIntFromDictionaryForKey( displayModeDict, kCGDisplayWidth ) / horizontalSizeInInches;
            *verticalDPI = (float)GetIntFromDictionaryForKey( displayModeDict, kCGDisplayHeight ) / verticalSizeInInches;
            err = CGDisplayNoErr;
        }
		
    }
	
    return err;
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
	
	// Determine if this is our first run from preferences
	if ([gUserDefaults objectForKey:@"version"] == NULL)  {
		firstRun = YES;
		[gUserDefaults setObject:@"0.1.9" forKey:@"version"];
	}
	else {
		if ([[gUserDefaults stringForKey:@"version"] isEqualToString:@"0.1.9"]) {
			firstRun = NO;
		}
		else {
			firstRun = YES;
			[gUserDefaults setObject:@"0.1.9" forKey:@"version"];
		}
	}
	
	// Get run count
	if (firstRun) {
		runCount = 1;
	}
	else {
		if ([gUserDefaults objectForKey:@"runCount"])
			runCount =  [gUserDefaults integerForKey:@"runCount"] + 1;
		else
			runCount = 1;
	}

	// Get memory cache size from preferences
	memoryCacheSize = 4096;
	if ([gUserDefaults objectForKey:@"memoryCacheSize"])
		memoryCacheSize = [gUserDefaults integerForKey:@"memoryCacheSize"];
	if (memoryCacheSize < 128 || memoryCacheSize > 32768)
		memoryCacheSize = 4096;

	// Get the use of the checkerboard pattern
	if ([gUserDefaults objectForKey:@"useCheckerboard"])
		useCheckerboard = [gUserDefaults boolForKey:@"useCheckerboard"];
	else
		useCheckerboard = YES;
	
	// Get the fewerWarnings
	if ([gUserDefaults objectForKey:@"fewerWarnings"])
		fewerWarnings = [gUserDefaults boolForKey:@"fewerWarnings"];
	else
		fewerWarnings = NO;
		
	//  Get the effectsPanel
	if ([gUserDefaults objectForKey:@"effectsPanel"])
		effectsPanel = [gUserDefaults boolForKey:@"effectsPanel"];
	else
		effectsPanel = NO;
	
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
		
	// Get the selection colour
	selectionColor = kBlackColor;
	if ([gUserDefaults objectForKey:@"selectionColor"])
		selectionColor = [gUserDefaults integerForKey:@"selectionColor"];
	if (selectionColor < 0 || selectionColor >= kMaxColor)
		selectionColor = kBlackColor;
	
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
	
	// Determine the initial color (from preferences if possible)
	if ([gUserDefaults objectForKey:@"windowBackColor"] == NULL) {
		windowBackColor = [[NSColor colorWithCalibratedRed:0.6667 green:0.6667 blue:0.6667 alpha:1.0] retain];
	}
	else {
		tempData = [gUserDefaults dataForKey:@"windowBackColor"];
		if (tempData != nil)
			windowBackColor = [(NSColor *)[NSUnarchiver unarchiveObjectWithData:tempData] retain];
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

	// Mode used for the new document
	resolutionHandling = kUse72dpiResolution;
	if ([gUserDefaults objectForKey:@"resolutionHandling"])
		resolutionHandling = [gUserDefaults integerForKey:@"resolutionHandling"];

	//  Get the multithreaded
	if ([gUserDefaults objectForKey:@"transparentBackground"])
		transparentBackground = [gUserDefaults boolForKey:@"transparentBackground"];
	else
		transparentBackground = NO;

	//  Get the multithreaded
	if ([gUserDefaults objectForKey:@"multithreaded"])
		multithreaded = [gUserDefaults boolForKey:@"multithreaded"];
	else
		multithreaded = YES;
		
	//  Get the ignoreFirstTouch
	if ([gUserDefaults objectForKey:@"ignoreFirstTouch"])
		ignoreFirstTouch = [gUserDefaults boolForKey:@"ignoreFirstTouch"];
	else
		ignoreFirstTouch = NO;
		
	// Get the mouseCoalescing
	if ([gUserDefaults objectForKey:@"newMouseCoalescing"])
		mouseCoalescing = [gUserDefaults boolForKey:@"newMouseCoalescing"];
	else
		mouseCoalescing = YES;
		
	// Get the checkForUpdates
	if ([gUserDefaults objectForKey:@"checkForUpdates"]) {
		checkForUpdates = [gUserDefaults boolForKey:@"checkForUpdates"];
		lastCheck = [[gUserDefaults objectForKey:@"lastCheck"] doubleValue];
	}
	else {
		checkForUpdates = YES;
		lastCheck = [[NSDate date] timeIntervalSinceReferenceDate];
	}
	
	// Get the preciseCursor
	if ([gUserDefaults objectForKey:@"preciseCursor"])
		preciseCursor = [gUserDefaults boolForKey:@"preciseCursor"];
	else
		preciseCursor = NO;

	// Get the useCoreImage
	if ([gUserDefaults objectForKey:@"useCoreImage"])
		useCoreImage = [gUserDefaults boolForKey:@"useCoreImage"];
	else
		useCoreImage = YES;
		
	// Get the main screen resolution
	if (GetMainDisplayDPI(&xdpi, &ydpi)) {
		xdpi = ydpi = 72.0;
		NSLog(@"Error finding screen resolution.");
	}
	mainScreenResolution.x = (int)roundf(xdpi);
	mainScreenResolution.y = (int)roundf(ydpi);
#ifdef DEBUG
	// NSLog(@"Screen resolution (dpi): %d x %d", mainScreenResolution.x, mainScreenResolution.y);
#endif
	gScreenResolution = [self screenResolution];

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

	// Create the toolbar instance, and attach it to our document window 
    toolbar = [[[NSToolbar alloc] initWithIdentifier: PrefsToolbarIdentifier] autorelease];
    
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
	[gUserDefaults setInteger:memoryCacheSize forKey:@"memoryCacheSize"];
	[gUserDefaults setObject:(fewerWarnings ? @"YES" : @"NO") forKey:@"fewerWarnings"];
	[gUserDefaults setObject:(effectsPanel ? @"YES" : @"NO") forKey:@"effectsPanel"];
	[gUserDefaults setObject:(smartInterpolation ? @"YES" : @"NO") forKey:@"smartInterpolation"];
	[gUserDefaults setObject:(openUntitled ? @"YES" : @"NO") forKey:@"openUntitled"];
	[gUserDefaults setObject:(multithreaded ? @"YES" : @"NO") forKey:@"multithreaded"];
	[gUserDefaults setObject:(ignoreFirstTouch ? @"YES" : @"NO") forKey:@"ignoreFirstTouch"];
	[gUserDefaults setObject:(mouseCoalescing ? @"YES" : @"NO") forKey:@"newMouseCoalescing"];
	[gUserDefaults setObject:(checkForUpdates ? @"YES" : @"NO") forKey:@"checkForUpdates"];
	[gUserDefaults setObject:(preciseCursor ? @"YES" : @"NO") forKey:@"preciseCursor"];
	[gUserDefaults setObject:(useCoreImage ? @"YES" : @"NO") forKey:@"useCoreImage"];
	[gUserDefaults setObject:(transparentBackground ? @"YES" : @"NO") forKey:@"transparentBackground"];
	[gUserDefaults setObject:(useCheckerboard ? @"YES" : @"NO") forKey:@"useCheckerboard"];
	[gUserDefaults setObject:[NSArchiver archivedDataWithRootObject:windowBackColor] forKey:@"windowBackColor"];
	[gUserDefaults setInteger:selectionColor forKey:@"selectionColor"];
	[gUserDefaults setObject:(whiteLayerBounds ? @"YES" : @"NO") forKey:@"whiteLayerBounds"];
	[gUserDefaults setInteger:guideColor forKey:@"guideColor"];
	[gUserDefaults setInteger:width forKey:@"width"];
	[gUserDefaults setInteger:height forKey:@"height"];
	[gUserDefaults setInteger:resolution forKey:@"resolution"];
	[gUserDefaults setInteger:newUnits forKey:@"units"];
	[gUserDefaults setInteger:mode forKey:@"mode"];
	[gUserDefaults setInteger:resolutionHandling forKey:@"resolutionHandling"];
	[gUserDefaults setInteger:runCount forKey:@"runCount"];
	[gUserDefaults setObject:[font fontName] forKey:@"fontName"];
	[gUserDefaults setFloat:[font pointSize] forKey:@"fontSize"];
	[gUserDefaults setObject:[NSString stringWithFormat:@"%f", lastCheck] forKey:@"lastCheck"];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
	NSToolbarItem *toolbarItem = nil;

    if ([itemIdent isEqual: GeneralPrefsIdentifier]) {
        toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: GeneralPrefsIdentifier label: LOCALSTR(@"general", @"General") image: @"GeneralPrefsIcon" toolTip: LOCALSTR(@"general prefs tooltip", @"General application settings") target: self selector: @selector(generalPrefs)] autorelease];
	} else if ([itemIdent isEqual: NewPrefsIdentifier]) {
		toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: NewPrefsIdentifier label: LOCALSTR(@"new images", @"New Images") image: @"NewPrefsIcon" toolTip: LOCALSTR(@"new prefs tooltip", @"Settings for new images") target: self selector: @selector(newPrefs)] autorelease];
	} else if ([itemIdent isEqual: ColorPrefsIdentifier]) {
		toolbarItem = [[[ImageToolbarItem alloc] initWithItemIdentifier: ColorPrefsIdentifier label: LOCALSTR(@"color", @"Colors") image: @"ColorPrefsIcon" toolTip: LOCALSTR(@"color prefs tooltip", @"Display colors") target: self selector: @selector(colorPrefs)] autorelease];
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
	[checkerboardMatrix	selectCellAtRow: useCheckerboard column: 0];
	[layerBoundsMatrix selectCellAtRow: whiteLayerBounds column: 0];
	[windowBackWell setInitialColor:windowBackColor];
	[transparentBackgroundCheckbox setState:transparentBackground];
	[fewerWarningsCheckbox setState:fewerWarnings];
	[effectsPanelCheckbox setState:effectsPanel];
	[smartInterpolationCheckbox setState:smartInterpolation];
	[openUntitledCheckbox setState:openUntitled];
	[multithreadedCheckbox setState:multithreaded];
	[ignoreFirstTouchCheckbox setState:ignoreFirstTouch];
	[coalescingCheckbox setState:mouseCoalescing];
	[checkForUpdatesCheckbox setState:checkForUpdates];
	[preciseCursorCheckbox setState:preciseCursor];	
	[useCoreImageCheckbox setState:useCoreImage];
	if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3) {
		[useCoreImageCheckbox setState:NO];
		[useCoreImageCheckbox setEnabled:NO];
	}
	if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_2) {
		[multithreadedCheckbox setState:NO];
		[multithreadedCheckbox setEnabled:NO];
	}
	[selectionColorMenu selectItemAtIndex:[selectionColorMenu indexOfItemWithTag:selectionColor + 280]];
	[guideColorMenu selectItemAtIndex:[guideColorMenu indexOfItemWithTag:guideColor + 290]];
	[resolutionHandlingMenu selectItemAtIndex:[resolutionHandlingMenu indexOfItemWithTag:resolutionHandling]];
	
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
	
	[self apply: self];
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
	
	[self apply: self];
}

-(IBAction)setNewUnits:(id)sender
{
	newUnits = [sender tag] % 10;
	[heightValue setStringValue:StringFromPixels(height, newUnits, resolution)];
	[widthValue setStringValue:StringFromPixels(width, newUnits, resolution)];	
	[heightUnits setStringValue:UnitsString(newUnits)];
	[self apply: self];
}

-(IBAction)changeUnits:(id)sender
{
	SeaDocument *document = gCurrentDocument;
	[document changeMeasuringStyle:[sender tag] % 10];
	[[document docView] updateRulers];
	[[[SeaController utilitiesManager] infoUtilityFor:document] update];
	[[[SeaController utilitiesManager] statusUtilityFor:document] update];
}

-(IBAction)setResolution:(id)sender
{
	resolution = [[resolutionMenu selectedItem] tag];
	width =  PixelsFromFloat([widthValue floatValue],newUnits,resolution);
	height =  PixelsFromFloat([heightValue floatValue],newUnits,resolution);
	[self apply: self];
}

-(IBAction)setMode:(id)sender
{
	mode = [[modeMenu selectedItem] tag];
	[self apply: self];
}

-(IBAction)setTransparentBackground:(id)sender
{
	transparentBackground = [transparentBackgroundCheckbox state];
	[self apply: self];
}

-(IBAction)setFewerWarnings:(id)sender
{
	fewerWarnings = [fewerWarningsCheckbox state];
	[self apply: self];
}
	
-(IBAction)setEffectsPanel:(id)sender
{
	effectsPanel = [effectsPanelCheckbox state];
	[self apply: self];
}

-(IBAction)setSmartInterpolation:(id)sender
{
	smartInterpolation = [smartInterpolationCheckbox state];
	[self apply: self];
}

-(IBAction)setOpenUntitled:(id)sender
{
	openUntitled = [openUntitledCheckbox state];
	[self apply: self];
}

-(IBAction)setMultithreaded:(id)sender
{
	multithreaded = [multithreadedCheckbox state];
	[self apply: self];
}

-(IBAction)setIgnoreFirstTouch:(id)sender
{
	ignoreFirstTouch = [ignoreFirstTouchCheckbox state];
	[self apply: self];
}

-(IBAction)setMouseCoalescing:(id)sender
{
	mouseCoalescing = [coalescingCheckbox state];
	[self apply: self];
}	


-(IBAction)setCheckForUpdates:(id)sender
{
	checkForUpdates = [checkForUpdatesCheckbox state];
	[self apply: self];
}

-(IBAction)setPreciseCursor:(id)sender
{
	preciseCursor = [preciseCursorCheckbox state];
	[self apply: self];
}

- (IBAction)setUseCoreImage:(id)sender
{
	useCoreImage = [useCoreImageCheckbox state];
	[self apply: self];	
}

-(IBAction)setResolutionHandling:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;

	resolutionHandling = [[resolutionHandlingMenu selectedItem] tag];
	gScreenResolution = [self screenResolution];
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] helpers] resolutionChanged];
	}
}

- (IBAction)apply:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	// Call for all documents' views to respond to the change
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
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

- (BOOL)guides
{
	return guides;
}

- (BOOL)rulers
{
	return rulers;
}

- (BOOL)firstRun
{
	return firstRun;
}

- (int)memoryCacheSize
{
	return memoryCacheSize;
}

- (int)warningLevel
{
	return (fewerWarnings) ? kModerateImportance : kVeryLowImportance;
}

- (BOOL)effectsPanel
{
	return effectsPanel;
}

- (BOOL)smartInterpolation
{
	return smartInterpolation;
}

- (BOOL)useTextures
{
	return useTextures;
}

- (void)setUseTextures:(BOOL)value
{
	useTextures = value;
}

- (IBAction)toggleBoundaries:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	layerBounds = !layerBounds;
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
}

- (IBAction)toggleGuides:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	guides = !guides;
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
}
		
- (IBAction)toggleRulers:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	rulers = !rulers;
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] updateRulersVisiblity];
	}
	[[gCurrentDocument docView] checkMouseTracking];
}

- (IBAction)checkerboardChanged:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;

	useCheckerboard = [sender selectedRow];
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
}

- (BOOL) useCheckerboard
{
	return useCheckerboard;
}

- (IBAction)defaultWindowBack:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;

	[windowBackColor autorelease];
	windowBackColor = [[NSColor colorWithCalibratedRed:0.6667 green:0.6667 blue:0.6667 alpha:1.0] retain];
	[windowBackWell setInitialColor:windowBackColor];
	for (i = 0; i < [documents count]; i++) {
		[[documents objectAtIndex:i] updateWindowColor];
		[[[[documents objectAtIndex:i] docView] superview] setNeedsDisplay:YES];
	}
}

- (IBAction)windowBackChanged:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;

	[windowBackColor autorelease];
	windowBackColor = [[windowBackWell color] retain];
	for (i = 0; i < [documents count]; i++) {
		[[documents objectAtIndex:i] updateWindowColor];
		[[[[documents objectAtIndex:i] docView] superview] setNeedsDisplay:YES];
	}
}

- (NSColor *)windowBack
{
	return windowBackColor;
}

- (NSColor *)selectionColor:(float)alpha
{	
	NSColor *result;
	//float alpha = light ? 0.20 : 0.40;
	
	switch (selectionColor) {
		case kCyanColor:
			result = [NSColor colorWithDeviceCyan:1.0 magenta:0.0 yellow:0.0 black:0.0 alpha:alpha];
		break;
		case kMagentaColor:
			result = [NSColor colorWithDeviceCyan:0.0 magenta:1.0 yellow:0.0 black:0.0 alpha:alpha];
		break;
		case kYellowColor:
			result = [NSColor colorWithDeviceCyan:0.0 magenta:0.0 yellow:1.0 black:0.0 alpha:alpha];
		break;
		default:
			result = [NSColor colorWithCalibratedWhite:0.0 alpha:alpha];
		break;
	}
	result = [result colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	
	return result;
}

- (int)selectionColorIndex
{
	return selectionColor;
}

- (IBAction)selectionColorChanged:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	selectionColor = [sender tag] - 280;
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
}

- (BOOL)whiteLayerBounds
{
	return whiteLayerBounds;
}

- (IBAction)layerBoundsColorChanged:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;

	whiteLayerBounds = [sender selectedRow];
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
}

- (NSColor *)guideColor:(float)alpha
{	
	NSColor *result;
	//float alpha = light ? 0.20 : 0.40;
	
	switch (guideColor) {
		case kCyanColor:
			result = [NSColor colorWithDeviceCyan:1.0 magenta:0.0 yellow:0.0 black:0.0 alpha:alpha];
			break;
		case kMagentaColor:
			result = [NSColor colorWithDeviceCyan:0.0 magenta:1.0 yellow:0.0 black:0.0 alpha:alpha];
			break;
		case kYellowColor:
			result = [NSColor colorWithDeviceCyan:0.0 magenta:0.0 yellow:1.0 black:0.0 alpha:alpha];
			break;
		default:
			result = [NSColor colorWithCalibratedWhite:0.0 alpha:alpha];
			break;
	}
	result = [result colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	
	return result;
}

- (int)guideColorIndex
{
	return guideColor;
}

- (IBAction)guideColorChanged:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	guideColor = [sender tag] - 290;
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
}

- (IBAction)rotateSelectionColor:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	selectionColor = (selectionColor + 1) % kMaxColor;
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
	
	// Set the selection colour correctly
	[selectionColorMenu selectItemAtIndex:[selectionColorMenu indexOfItemWithTag:selectionColor + 280]];
}

- (BOOL)multithreaded
{
/*
	BOOL good_os;
	
	good_os = !(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_2);

	return multithreaded && good_os;
*/
	return NO;
}

- (BOOL)ignoreFirstTouch
{
	return ignoreFirstTouch;
}

- (BOOL)mouseCoalescing
{
	return mouseCoalescing;
}

- (BOOL)checkForUpdates
{
	if ([[NSDate date] timeIntervalSinceReferenceDate] - lastCheck > 7.0 * 24.0 * 60.0 * 60.0) {
		lastCheck = [[NSDate date] timeIntervalSinceReferenceDate];
		return checkForUpdates;
	}
	
	return NO;
}

- (BOOL)preciseCursor
{
	return preciseCursor;
}

- (BOOL)useCoreImage
{
	return useCoreImage;
}

- (BOOL)delayOverlay
{
	return NO;
}

- (IntSize)size
{
	IntSize result = IntMakeSize(width, height);
	
	return result;
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
	switch (resolutionHandling) {
		case kIgnoreResolution:
			return IntMakePoint(0, 0);
		break;
		case kUse72dpiResolution:
			return IntMakePoint(72, 72);
		break;
		case kUseScreenResolution:
			return mainScreenResolution;
		break;
	}

	return IntMakePoint(72, 72);
}

- (BOOL)transparentBackground
{
	return transparentBackground;
}

- (int)runCount
{
	return runCount;
}

- (BOOL)openUntitled
{
	return openUntitled;
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

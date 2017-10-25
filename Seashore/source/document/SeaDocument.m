#import "XCFContent.h"
#import "CocoaContent.h"
#import "XBMContent.h"
#import "SVGContent.h"
#import "SeaDocument.h"
#import "SeaView.h"
#ifdef USE_CENTERING_CLIPVIEW
#import "CenteringClipView.h"
#endif
#import "SeaController.h"
#import "SeaWarning.h"
#import "SeaWhiteboard.h"
#import "UtilitiesManager.h"
#import "TIFFExporter.h"
#import "XCFExporter.h"
#import "PNGExporter.h"
#import "JPEGExporter.h"
#import "SeaPrefs.h"
#import "SeaSelection.h"
#import "SeaLayer.h"
#import "SeaHelpers.h"
#import "PegasusUtility.h"
#import "SeaPrintView.h"
#import "SeaDocumentController.h"
#import "Units.h"
#import "OptionsUtility.h"
#import "SeaWindowContent.h"

extern int globalUniqueDocID;

extern IntPoint gScreenResolution;

extern BOOL globalReadOnlyWarning;

enum {
	kNoStart = 0,
	kNormalStart = 1,
	kOpenStart = 2,
	kPasteboardStart = 3,
	kPlugInStart = 4
};

@implementation SeaDocument

- (id)init
{
	int dtype, dwidth, dheight, dres;
	BOOL dopaque;
	
	// Initialize superclass first
	if (![super init])
		return NULL;
	
	// Reset uniqueLayerID
	uniqueLayerID = -1;
	uniqueFloatingLayerID = 4999;
	
	// Get a unique ID for this document
	uniqueDocID = globalUniqueDocID;
	globalUniqueDocID++;
	
	// Set data members appropriately
	whiteboard = NULL;
	restoreOldType = NO;
	current = YES;
	specialStart = kNormalStart;
	
	// Set the measure style
	measureStyle = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] units];
	
	// Create contents
	dtype = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] type];
	dwidth = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] width];
	dheight = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] height];
	dres = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] resolution];
	dopaque = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] opaque];
	contents = [[SeaContent alloc] initWithDocument:self type:dtype width:dwidth height:dheight res:dres opaque:dopaque];
	
	return self;
}

- (id)initWithPasteboard
{
	// Initialize superclass first
	if (![super init])
		return NULL;
	
	// Reset uniqueLayerID
	uniqueLayerID = -1;
	uniqueFloatingLayerID = 4999;
	
	// Get a unique ID for this document
	uniqueDocID = globalUniqueDocID;
	globalUniqueDocID++;
	
	// Set data members appropriately
	whiteboard = NULL;
	restoreOldType = NO;
	current = YES;
	specialStart = kPasteboardStart;
	
	// Set the measure style
	measureStyle = [(SeaPrefs *)[SeaController seaPrefs] newUnits];
	
	// Create contents
	contents = [[SeaContent alloc] initFromPasteboardWithDocument:self];
	
	// Mark document as dirty
	[self updateChangeCount:NSChangeDone];
	
	return self;
}

- (id)initWithContentsOfFile:(NSString *)path ofType:(NSString *)type
{
	// Initialize superclass first
	if (![super init])
		return NULL;
	
	// Reset uniqueLayerID
	uniqueLayerID = -1;
	uniqueFloatingLayerID = 4999;
	
	// Get a unique ID for this document
	uniqueDocID = globalUniqueDocID;
	globalUniqueDocID++;
	
	// Set data members appropriately
	whiteboard = NULL;
	restoreOldType = NO;
	current = YES;
	specialStart = kOpenStart;
	
	// Set the measure style
	measureStyle = [(SeaPrefs *)[SeaController seaPrefs] newUnits];
	
	// Do required work
	if ([self readFromFile:path ofType:type]) {
		[self setFileName:path];
		[self setFileType:type];
	}
	else {
		[self autorelease];
		return NULL;
	}
	
	return self;
}

- (id)initWithData:(unsigned char *)data type:(int)type width:(int)width height:(int)height
{
	// Initialize superclass first
	if (![super init])
		return NULL;
	
	// Reset uniqueLayerID
	uniqueLayerID = -1;
	uniqueFloatingLayerID = 4999;
	
	// Get a unique ID for this document
	uniqueDocID = globalUniqueDocID;
	globalUniqueDocID++;
	
	// Set data members appropriately
	whiteboard = NULL;
	restoreOldType = NO;
	current = YES;
	contents = [[SeaContent alloc] initWithDocument:self data:data type:type width:width height:height res:72];
	specialStart = kPlugInStart;

	// Set the measure style
	measureStyle = [(SeaPrefs *)[SeaController seaPrefs] newUnits];

	// Increment change count
	[self updateChangeCount:NSChangeDone];
	
	return self;
}

- (void)awakeFromNib
{
	id seaView;
	#ifdef USE_CENTERING_CLIPVIEW
	id newClipView;
	#endif
	
	// Believe it or not sometimes this function is called after it has already run
	if (whiteboard == NULL) {
		exporters = [NSArray arrayWithObjects:
					 gifExporter,
					 jpegExporter,
					 jp2Exporter,
					 pngExporter,
					 tiffExporter,
					 xcfExporter,
					 NULL];
		[exporters retain];
		
		// Create a fresh whiteboard and selection manager
		whiteboard = [[SeaWhiteboard alloc] initWithDocument:self];
		selection = [[SeaSelection alloc] initWithDocument:self];
		[whiteboard update];
		
		// Setup the view to display the whiteboard
		seaView = [[SeaView alloc] initWithDocument:self];
		#ifdef USE_CENTERING_CLIPVIEW
		newClipView = [[CenteringClipView alloc] initWithFrame:[[view contentView] frame]];
		[(NSScrollView *)view setContentView:newClipView];
		[newClipView autorelease];
		#endif
		[view setDocumentView:seaView];
		[seaView autorelease];
		[view setDrawsBackground:NO];
		
		// set the frame of the window
		[docWindow setFrame:[self standardFrame] display:YES];
		
		// Finally, if the doc has any warnings we are ready for them
		[(SeaWarning *)[SeaController seaWarning] triggerQueue: self];
	}
	
	[docWindow setAcceptsMouseMovedEvents:YES];
}

- (void)dealloc
{
	// Then get rid of stuff that's no longer needed
	if (selection) [selection autorelease];
	if (whiteboard) [whiteboard autorelease];
	if (contents) [contents autorelease];
	if (exporters) [exporters autorelease];
		
	// Finally call the super
	[super dealloc];
}

- (IBAction)saveDocument:(id)sender
{
	current = YES;
	[super saveDocument:sender];
}

- (IBAction)saveDocumentAs:(id)sender
{
	current = YES;
	[super saveDocumentAs:sender];
}

- (id)contents
{
	return contents;
}

- (id)whiteboard
{
	return whiteboard;
}

- (id)selection
{
	return selection;
}

- (id)operations
{
	return operations;
}

- (id)tools
{
	return tools;
}

- (id)helpers
{
	return helpers;
}

- (id)warnings
{
	return warnings;
}

- (id)pluginData
{
	return pluginData;
}

- (id)docView
{
	return [view documentView];
}

- (id)window
{
	return docWindow;
}

- (void)updateWindowColor
{
	[view setBackgroundColor:[[SeaController seaPrefs] windowBack]];
}

- (id)textureExporter
{
	return textureExporter;
}

- (BOOL)readFromFile:(NSString *)path ofType:(NSString *)type
{	
	BOOL readOnly = NO;
	
	// Determine which document we have and act appropriately
	if ([XCFContent typeIsEditable: type]) {
		
		// Load a GIMP or XCF document
		contents = [[XCFContent alloc] initWithDocument:self contentsOfFile:path];
		if (contents == NULL) {
			return NO;
		}
		
	} else if ([CocoaContent typeIsEditable: type forDoc: self]) {
		
		// Load a PNG, TIFF, JPEG document
		// Or a GIF or JP2 document
		contents = [[CocoaContent alloc] initWithDocument:self contentsOfFile:path];
		if (contents == NULL) {
			return NO;
		}
		
	} else if ([CocoaContent typeIsViewable: type forDoc: self]) {
	
		// Load a PDF, PCT, BMP document
		contents = [[CocoaContent alloc] initWithDocument:self contentsOfFile:path];
		if (contents == NULL) {
			return NO;
		}
		readOnly = YES;
			
	} else if ([XBMContent typeIsEditable: type]) {
	
		// Load a X bitmap document
		contents = [[XBMContent alloc] initWithDocument:self contentsOfFile:path];
		if (contents == NULL) {
			return NO;
		}
		readOnly = YES;
		
	} else if ([SVGContent typeIsViewable: type]) {
	
		// Load a SVG document
		contents = [[SVGContent alloc] initWithDocument:self contentsOfFile:path];
		if (contents == NULL) {
			return NO;
		}
		readOnly = YES;
		
	} else {
		// Handle an unknown document type
		NSLog(@"Unknown type passed to readFromFile:<%@>ofType:<%@>", path, type);
		return NO;
	}
	
	if (readOnly && !globalReadOnlyWarning) {
		[[SeaController seaWarning] addMessage:LOCALSTR(@"read only message", @"This file is in a read-only format, as such you cannot save this file. This warning will not be displayed for subsequent files in a read-only format.") forDocument: self level:kLowImportance];
		globalReadOnlyWarning = YES;
	}
	
	return YES;
}

- (BOOL)writeToFile:(NSString *)path ofType:(NSString *)type
{
	BOOL result = NO;
	int i;
	
	for (i = 0; i < [exporters count]; i++) {
		if ([[SeaDocumentController sharedDocumentController]
			 type: type
			 isContainedInDocType:[[exporters objectAtIndex:i] title]
			 ]) {
			[[exporters objectAtIndex:i] writeDocument:self toFile:path];
			result = YES;
		}
	}
	
	if (!result){
		NSLog(@"Unknown type passed to writeToFile:<%@>ofType:<%@>", path, type);
	}
	return result;
}

- (void)printShowingPrintPanel:(BOOL)showPanels
{
	SeaPrintView *printView;
	NSPrintOperation *op;
    
	// Create a print operation for the given view
	printView = [[SeaPrintView alloc] initWithDocument:self];
	op = [NSPrintOperation printOperationWithView:printView printInfo:[self printInfo]];
	
	// Insist the view be scaled to fit
	[op setShowPanels:showPanels];
    [self runModalPrintOperation:op delegate:NULL didRunSelector:NULL contextInfo:NULL];

	// Release print view
	[printView autorelease];
}


- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
	int i, exporterIndex = -1;
	
	// Implement the view that allows us to select layers
	[savePanel setAccessoryView:accessoryView];
	
	// Find the default exporter's index
	for (i = 0; i < [exporters count]; i++) {
		if ([[SeaDocumentController sharedDocumentController]
			 type: [self fileType]
			 isContainedInDocType:[[exporters objectAtIndex:i] title]
			 ]) {
			exporterIndex = i;
			break;
		}
	}
	
	// Deal with the rare case where we don't find one
	if (exporterIndex == -1) {
		exporterIndex = [exporters count] - 1;
		[self setFileType:[[exporters objectAtIndex:[exporters count] - 1] title]];
	}
	
	// Add in our exporters
	[exportersPopUp removeAllItems];
	for (i = 0; i < [exporters count]; i++)
		[exportersPopUp addItemWithTitle:[[exporters objectAtIndex:i] title]];
	[exportersPopUp selectItemAtIndex:exporterIndex];
	[savePanel setRequiredFileType:[[exporters objectAtIndex:exporterIndex] extension]];
	
	// Finally set the options button state appropriately
	[optionsButton setEnabled:[[exporters objectAtIndex:[exportersPopUp indexOfSelectedItem]] hasOptions]];
	[optionsSummary setStringValue:[[exporters objectAtIndex:[exportersPopUp indexOfSelectedItem]] optionsString]];
	
	return YES;
}

- (IBAction)showExporterOptions:(id)sender
{
	[[exporters objectAtIndex:[exportersPopUp indexOfSelectedItem]] showOptions:self];
	[optionsSummary setStringValue:[[exporters objectAtIndex:[exportersPopUp indexOfSelectedItem]] optionsString]];
}

- (IBAction)exporterChanged:(id)sender
{
	[(NSSavePanel *)[exportersPopUp window] setRequiredFileType:[[exporters objectAtIndex:[exportersPopUp indexOfSelectedItem]] extension]];
	[self setFileType:[[exporters objectAtIndex:[exportersPopUp indexOfSelectedItem]] title]];
	[optionsButton setEnabled:[[exporters objectAtIndex:[exportersPopUp indexOfSelectedItem]] hasOptions]];
	[optionsSummary setStringValue:[[exporters objectAtIndex:[exportersPopUp indexOfSelectedItem]] optionsString]];
}

- (void)windowWillBeginSheet:(NSNotification *)notification
{
	[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:self] setEnabled:NO];
}

- (void)windowDidEndSheet:(NSNotification *)notification
{
	[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:self] setEnabled:YES];
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
	NSPoint point;
	
	[(UtilitiesManager *)[SeaController utilitiesManager] activate:self];
	if ([docWindow attachedSheet])
		[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:self] setEnabled:NO];
	else
		[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:self] setEnabled:YES];
	point = [docWindow mouseLocationOutsideOfEventStream];
	[[self docView] updateRulerMarkings:point andStationary:NSMakePoint(-256e6, -256e6)];
	[(OptionsUtility *)[(UtilitiesManager *)[SeaController utilitiesManager] optionsUtilityFor:self] viewNeedsDisplay];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
	NSPoint point;
	
	[helpers endLineDrawing];
	if ([docWindow attachedSheet])
		[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:self] setEnabled:NO];
	else
		[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:self] setEnabled:YES];
	point = NSMakePoint(-256e6, -256e6);
	[[self docView] updateRulerMarkings:point andStationary:point];
	[(OptionsUtility *)[(UtilitiesManager *)[SeaController utilitiesManager] optionsUtilityFor:self] viewNeedsDisplay];
	[gColorPanel orderOut:self];
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	[[self docView] clearScrollingMode];
}

- (NSRect) windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
	// I don't know what would call this besides the doc window
	if(sender != docWindow){
		NSLog(@"An unknown window (%@) has attempted to zoom.", sender);
		return NSZeroRect;
	}
	return [self standardFrame];
}

- (NSRect)standardFrame
{
	NSRect frame;
	float xScale, yScale;
	NSRect rect;
	
	// Get the old frame so we can preserve the top-left origin
	frame = [docWindow frame];
	float minHeight = 480;

	// Store the initial conditions of the window 
	rect.origin.x = frame.origin.x;
	rect.origin.y = frame.origin.y;
	xScale = [contents xscale];
	yScale = [contents yscale];
	rect.size.width = [(SeaContent *)contents width]  * xScale;
	rect.size.height = [(SeaContent *)contents height] * yScale;
		
	 // Remember the rulers have dimension
	 if([[SeaController seaPrefs] rulers]){
		 rect.size.width += 22;
		 rect.size.height += 31;
	 }
	// Titlebar
	rect.size.height += 22;
	minHeight += 22;
	// Toolbar
	if([[docWindow toolbar] isVisible]){
		// This is innacurate because the toolbar can actually change in height,
		// depending on settings (labels, small etc...)
		rect.size.height += 35;
		minHeight += 35;
	}
	// Options Bar
	rect.size.height += [[docWindow contentView] sizeForRegion: kOptionsBar];
	 // Status Bar
	rect.size.height += [[docWindow contentView] sizeForRegion: kStatusBar];
	
	 // Layers
	rect.size.width += [[docWindow contentView] sizeForRegion: kSidebar];
	
	// Disallow ridiculously small or large windows
	NSRect defaultFrame = [[docWindow screen] frame];
	if (rect.size.width > defaultFrame.size.width) rect.size.width = defaultFrame.size.width;
	if (rect.size.height > defaultFrame.size.height) rect.size.height = defaultFrame.size.height;
	if (rect.size.width < 724) rect.size.width = 724;
	if (rect.size.height < minHeight) rect.size.height = minHeight;
	
	// Reset the origin's y-value to keep the titlebar level
	rect.origin.y = rect.origin.y - rect.size.height + frame.size.height;
	
	return rect;
}

- (void)close
{
	[[SeaController utilitiesManager] shutdownFor:self];

	// Then call our supervisor
	[super close];
}

- (BOOL)current
{
	return current;
}

- (void)setCurrent:(BOOL)value
{
	current = value;
}

- (int)uniqueLayerID
{
	uniqueLayerID++;
	return uniqueLayerID;
}

- (int)uniqueFloatingLayerID
{
	uniqueFloatingLayerID++;
	return uniqueFloatingLayerID;
}

- (int)uniqueDocID
{
	return uniqueDocID;
}

- (NSString *)windowNibName
{
    return @"SeaDocument";
}

- (IBAction)customUndo:(id)sender
{
	[[self undoManager] undo];
}

- (IBAction)customRedo:(id)sender
{
	[[self undoManager] redo];
}

- (void)changeMeasuringStyle:(int)aStyle
{
	measureStyle = aStyle;
}

- (int)measureStyle
{
	return measureStyle;
}

- (BOOL)locked
{
	return locked || ([docWindow attachedSheet] != NULL);
}

- (void)lock
{
	locked = YES;
}

- (void)unlock
{
	locked = NO;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	id type = [self fileType];
	
	[helpers endLineDrawing];
	if ([menuItem tag] == 171) {
		if ([type isEqualToString:@"PDF Document"] || [type isEqualToString:@"PICT Document"] || [type isEqualToString:@"Graphics Interchange Format Image"] || [type isEqualToString:@"Windows Bitmap Image"])
			return NO;
		if ([self isDocumentEdited] == NO)
			return NO;
	}
	
	if ([menuItem tag] == 180)
		return ![self locked] && [[self undoManager] canUndo];
	if ([menuItem tag] == 181)
		return ![self locked] && [[self undoManager] canRedo];

	return YES;
}

- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo
{
	// Remember the old type
	oldType = [self fileType];
	[oldType retain];
	if (saveOperation == NSSaveToOperation) {
		restoreOldType = YES;
	}
	
	// Check we're not meant to call someone
	if (delegate)
		NSLog(@"Delegate specified for save panel");
	
	// Run the super's method calling our custom
	[super runModalSavePanelForSaveOperation:saveOperation delegate:self didSaveSelector:@selector(document:didSave:contextInfo:) contextInfo:NULL];
	
}

- (void)document:(NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo
{
	// Restore the old type
	if (restoreOldType && didSave) {
		[self setFileType:oldType];
		[oldType autorelease];
		restoreOldType = NO;
	}
	else if (!didSave) {
		[self setFileType:oldType];
		[oldType autorelease];
		restoreOldType = NO;
	}
}

- (NSString *)fileTypeFromLastRunSavePanel
{
	return [self fileType];
}


- (NSScrollView *)scrollView
{
	return (NSScrollView *)view;
}

- (id)dataSource
{
	return dataSource;
}

@end

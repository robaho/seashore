#import "XCFContent.h"
#import "CocoaContent.h"
#import "XBMContent.h"
#import "SVGContent.h"
#import "SeaDocument.h"
#import "SeaView.h"
#import "CenteringClipView.h"
#import "SeaController.h"
#import "SeaWhiteboard.h"
#import "TIFFExporter.h"
#import "XCFExporter.h"
#import "PNGExporter.h"
#import "JPEGExporter.h"
#import "SeaPrefs.h"
#import "SeaSelection.h"
#import "SeaLayer.h"
#import "SeaHelpers.h"
#import "LayersUtility.h"
#import "SeaPrintView.h"
#import "SeaDocumentController.h"
#import "Units.h"
#import "OptionsUtility.h"
#import "SeaWindowContent.h"
#import "SeaPrintOptionsController.h"
#import "ToolboxUtility.h"
#import "SeaTools.h"
#import "AbstractTool.h"
#import "SeaScrollView.h"

@implementation SeaDocument

- (id)init
{
	// Initialize superclass first
	if (![super init])
		return NULL;
	
	// Reset uniqueLayerID
	uniqueLayerID = -1;

	// Set data members appropriately
	whiteboard = NULL;
	
	// Set the measure style
	measureStyle = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] units];
	
	contents = [[SeaContent alloc] initWithDocument:self type:0 width:64 height:64 res:72 opaque:NO];
	
	return self;
}

- (id)initWithType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError
{
    int dtype, dwidth, dheight, dres;
    BOOL dopaque;
    
    // Initialize superclass first
    if (![super init])
        return NULL;
    
    [self setFileType:typeName];
    
    // Reset uniqueLayerID
    uniqueLayerID = -1;

    // Set data members appropriately
    whiteboard = NULL;
    
    // Set the measure style
    measureStyle = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] units];
    
    // Create contents
    dtype = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] type];
    dwidth = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] width];
    dheight = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] height];
    dopaque = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] opaque];
    dres = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] resolution];

    contents = [[SeaContent alloc] initWithDocument:self type:dtype width:dwidth height:dheight res:dres opaque:dopaque];
    
    outError = NULL;
    
    return self;
}

- (id)initWithPasteboard
{
    id pboard = [NSPasteboard generalPasteboard];
    NSPasteboardType ptype = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSURLPboardType,NSTIFFPboardType,nil]];
    if([ptype isEqualToString:NSURLPboardType]){
        NSURL *url = [NSURL URLFromPasteboard:pboard];
        if([url isFileURL]) {
            NSString *path = [url path];
            NSString *extension = [path pathExtension];
            return [self initWithContentsOfFile:path ofType:extension];
        } else {
            // we'll try the image types below
        }
    }
    
	// Initialize superclass first
	if (![super init])
		return NULL;
	
	// Reset uniqueLayerID
	uniqueLayerID = -1;

	// Set data members appropriately
	whiteboard = NULL;
	
	// Set the measure style
	measureStyle = [(SeaPrefs *)[SeaController seaPrefs] newUnits];
	
	// Create contents
	contents = [[SeaContent alloc] initFromPasteboardWithDocument:self];
	
	// Mark document as dirty
	[self updateChangeCount:NSChangeDone];
	
	return self;
}

- (void)awakeFromNib
{
    if (@available(macOS 10.13.4, *)) {
        exporters = [NSArray arrayWithObjects:
                     gifExporter,
                     jpegExporter,
                     jp2Exporter,
                     pngExporter,
                     tiffExporter,
                     xcfExporter,
                     heicExporter,
                     NULL];
    } else {
        exporters = [NSArray arrayWithObjects:
                     gifExporter,
                     jpegExporter,
                     jp2Exporter,
                     pngExporter,
                     tiffExporter,
                     xcfExporter,
                     NULL];
    }

    [self setWindow:docWindow];
    
    // Create a fresh whiteboard and selection manager
    whiteboard = [[SeaWhiteboard alloc] initWithDocument:self];
    selection = [[SeaSelection alloc] initWithDocument:self];

    [whiteboard update];

    // Setup the view to display the whiteboard
    seaView = [[SeaView alloc] initWithDocument:self];
    scrollView = [[SeaScrollView alloc] initWithDocument:self andView:seaView andOverlay:[seaView extrasView]];
    
    [scrollView setFrameSize:[contentView frame].size];

    [contentView addSubview:scrollView];

    [docWindow setFrame:[self standardFrame] display:NO];

    if([[SeaController seaPrefs] zoomToFitAtOpen]) {
        [[self docView] zoomToFit:self];
    }

    [docWindow setIsVisible:TRUE];

    [[self undoManager] setLevelsOfUndo:[[SeaController seaPrefs] undoLevels]];
}

- (void) encodeRestorableStateWithCoder:(NSCoder *) coder {
    
    if (self.fileURL){
        [coder encodeInteger:1 forKey:@"restorable"];
    } else {
        [coder encodeInteger:0 forKey:@"restorable"];
    }
    [super encodeRestorableStateWithCoder:coder];
}

- (IBAction)saveDocument:(id)sender
{
	[super saveDocument:sender];
}

- (IBAction)saveDocumentAs:(id)sender
{
	[super saveDocumentAs:sender];
}

- (BOOL)shouldRunSavePanelWithAccessoryView
{
    return FALSE;
}

- (SeaContent*)contents
{
	return contents;
}

- (SeaWhiteboard*)whiteboard
{
	return whiteboard;
}

- (SeaSelection *)selection
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

- (AbstractTool*)currentTool
{
    int toolId = [[self toolboxUtility] tool];
    return [(SeaTools*)tools getTool:toolId];
}

- (int)currentToolId
{
    return [[self toolboxUtility] tool];
}

- (SeaHelpers*)helpers
{
	return helpers;
}

- (WarningsUtility*)warnings
{
	return warnings;
}

- (id)pluginData
{
	return pluginData;
}

- (SeaView*)docView
{
	return seaView;
}


- (id)window
{
	return docWindow;
}

- (void)updateWindowColor
{
    [[[self scrollView] contentView] setNeedsDisplay:YES];
}

- (id)textureExporter
{
	return textureExporter;
}

- (id)brushExporter
{
    return brushExporter;
}

- (BOOL)readFromFile:(NSString *)path ofType:(NSString *)type
{	
	BOOL readOnly = NO;

    @try {

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

        if (readOnly) {
            [warnings addMessage:LOCALSTR(@"read only message", @"This file is in a read-only format, so you must Save As/Export any changes.")  level:kLowImportance];
        }
        return YES;
    }
    @catch(NSException *exception) {
        NSLog(@"unable to open file %@ %@",exception,[exception callStackSymbols]);
        [NSAlert alertWithMessageText:@"Error Opening File" defaultButton:NULL alternateButton:NULL otherButton:NULL informativeTextWithFormat:@"%@",[exception reason]];
        return NO;
    }
	
}

- (NSString*)fileTypeFromLastRunSavePanel
{
    return selectedType;
}

- (BOOL)writeToFile:(NSString *)path ofType:(NSString *)type
{
	for (AbstractExporter *exporter in exporters) {
		if ([[SeaDocumentController sharedDocumentController] type:type isContainedInDocType:[exporter title]]) {
			return [exporter writeDocument:self toFile:path];
		}
	}
	
    NSLog(@"Unknown type passed to writeToFile:<%@>ofType:<%@>", path, type);
	return NO;
}

- (void)printShowingPrintPanel:(BOOL)showPanels
{
    SeaPrintView *printView;

    // Create a print operation for the given view
    printView = [[SeaPrintView alloc] initWithDocument:self];

    NSPrintInfo *copy = [self printInfo];

    [copy setTopMargin:0];
    [copy setBottomMargin:0];
    [copy setLeftMargin:0];
    [copy setRightMargin:0];

    [copy setVerticallyCentered:NO];
    [copy setHorizontallyCentered:NO];

    [copy setHorizontalPagination:NSClipPagination];
    [copy setVerticalPagination:NSClipPagination];
    [[copy dictionary] setValue:@TRUE forKey:NSPrintDetailedErrorReporting];

    SeaPrintOptionsController *accessoryController = [[SeaPrintOptionsController alloc] initWithDocument:self];
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:printView printInfo:copy];

    [op setShowsPrintPanel:showPanels];
    [op setShowsProgressPanel:showPanels];

    NSPrintPanel *pp = [NSPrintPanel printPanel];
    [pp setJobStyleHint:NSPrintPhotoJobStyleHint];

    NSPrintPanelOptions options = NSPrintPanelShowsOrientation | NSPrintPanelShowsPreview | NSPrintPanelShowsCopies | NSPrintPanelShowsPaperSize;
    [pp setOptions:options];

    [op setPrintPanel:pp];

    [pp addAccessoryController:accessoryController];

    [self runModalPrintOperation:op delegate:NULL didRunSelector:NULL contextInfo:NULL];
}

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
    int i, exporterIndex = -1;

    if(![super prepareSavePanel:savePanel])
        return false;

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
        exporterIndex = (int)[exporters count] - 1;
    }
    
    // Add in our exporters
    [exportersPopUp removeAllItems];
    for (i = 0; i < [exporters count]; i++)
        [exportersPopUp addItemWithTitle:[[exporters objectAtIndex:i] title]];
    
    [exportersPopUp selectItemAtIndex:exporterIndex];
    selectedType = [[exporters objectAtIndex:exporterIndex] title];
    
    [savePanel setAccessoryView:accessoryView];
    [savePanel setAllowsOtherFileTypes:NO];
    [savePanel setAllowedFileTypes:@[ [[exporters objectAtIndex:[exportersPopUp indexOfSelectedItem]] extension] ] ];
    
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
    NSSavePanel *savePanel = (NSSavePanel *)[exportersPopUp window];
    [savePanel setAllowedFileTypes:@[ [[exporters objectAtIndex:[exportersPopUp indexOfSelectedItem]] extension] ] ];
    selectedType = [[exporters objectAtIndex:[exportersPopUp indexOfSelectedItem]] title];
	[optionsButton setEnabled:[[exporters objectAtIndex:[exportersPopUp indexOfSelectedItem]] hasOptions]];
	[optionsSummary setStringValue:[[exporters objectAtIndex:[exportersPopUp indexOfSelectedItem]] optionsString]];
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
	[[self optionsUtility] viewNeedsDisplay];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
	[helpers endLineDrawing];
	[[self optionsUtility] viewNeedsDisplay];
	[gColorPanel orderOut:self];
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
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

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    [super restoreStateWithCoder:coder];

    if([[SeaController seaPrefs] zoomToFitAtOpen]) {
        [[self docView] zoomToFit:self];
    }
}

- (NSRect)standardFrame
{
	return [docWindow frame];
}

- (void)close
{
    [[self textureUtility] shutdown];
    [[self brushUtility] shutdown];
    [[self optionsUtility] shutdown];
    [[self infoUtility] shutdown];

	// Then call our supervisor
	[super close];
}

- (int)uniqueLayerID
{
	uniqueLayerID++;
	return uniqueLayerID;
}

- (NSString *)windowNibName
{
    return @"SeaDocument";
}

- (IBAction)customUndo:(id)sender
{
    [[self helpers] endLineDrawing];
	[[self undoManager] undo];
}

- (IBAction)customRedo:(id)sender
{
    [[self helpers] endLineDrawing];
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

- (BOOL)validateMenuItem:(id)menuItem
{
	id type = [self fileType];
	
	if ([menuItem tag] == 171) {
		if ([type isEqualToString:@"PDF Document"] ||
            [type isEqualToString:@"PICT Document"] ||
            [type isEqualToString:@"Graphics Interchange Format Image"] ||
            [type isEqualToString:@"Windows Bitmap Image"])
			return NO;
		if ([self isDocumentEdited] == NO)
			return NO;
	}
	
	if ([menuItem tag] == 180)
		return [[self undoManager] canUndo];
	if ([menuItem tag] == 181)
		return [[self undoManager] canRedo];

	return YES;
}

- (SeaScrollView*)scrollView
{
    return scrollView;
}

- (id)dataSource
{
	return dataSource;
}

- (void)maybeShowLayerWarning
{
    bool isGIMP = [[self fileType]  isEqual: @"org.gimp.xcf"];
    if(!layerWarningShown && contents.layerCount > 1 && !isGIMP) {
        [warnings
         addMessage:LOCALSTR(@"layers warning",
                             @"Layers are not supported by the current file format and cannot be saved. To save layers, use 'Save As'/'Export' and select Seashore/GIMP as the file format.")
         level:kLowImportance];
        layerWarningShown=YES;
    }
}

- (void) setDisplayName:(NSString *)displayNameOrNil
{
    if(displayNameOrNil && [contents layerCount]==1) {
        [[contents layer:0] setName:displayNameOrNil];
    }
    [super setDisplayName:displayNameOrNil];
}

@end

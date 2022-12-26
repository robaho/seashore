#import "Seashore.h"
#import "SeaContent.h"
#import "SeaWhiteboard.h"
#import "TextureUtility.h"
#import "BrushUtility.h"
#import "ToolboxUtility.h"
#import "OptionsUtility.h"
#import "InfoUtility.h"
#import "RecentsUtility.h"
#import "LayersUtility.h"
#import "StatusUtility.h"
#import "WarningsUtility.h"
#import "SeaView.h"
#import "AbstractTool.h"
#import "SeaScrollView.h"
#import "SeaHistogram.h"
#import "SeaPluginData.h"

/*!
	@class		SeaDocument
	@abstract	Represents a single Seashore document.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@class SeaHelpers;
@class SeaSelection;
@protocol PluginClass;

@interface SeaDocument : NSDocument {

	// The contents of the document (a subclass of SeaContent)
	SeaContent *contents;

	// The whiteboard that represents this document
	SeaWhiteboard *whiteboard;
	
	// The selection manager for this document
	id selection;
	
	// The operations manager for this document
	IBOutlet id operations;
	
	// The tools for this document
	IBOutlet id tools;
	
	// An outlet to the helpers of this document
	IBOutlet id helpers;
	
	// An outlet to the warnings utility for this document
	IBOutlet id warnings;
	
	// The plug-in data used by this document
	__weak IBOutlet SeaPluginData *pluginData;
	
	// An outlet to the view associated with this document
    IBOutlet id contentView;

    IBOutlet id histogram;

    SeaView *seaView;
    SeaScrollView *scrollView;

	// An outlet to the window associated with this document
	IBOutlet id docWindow;
	
	// The exporters
	IBOutlet id gifExporter, jpegExporter, jp2Exporter, pngExporter, tiffExporter, xcfExporter, heicExporter;
	
	IBOutlet id textureExporter;
    
    IBOutlet id brushExporter;
	
	// An array of all possible exporters
	id exporters;
	
	// The view to attach to the save panel
	IBOutlet id accessoryView;
	
	// A pop-up menu of all possible exporters
	IBOutlet id exportersPopUp;
	
	// The button showing the options for the exporter
	IBOutlet id optionsButton;
	
	// A summary of the export options
	IBOutlet id optionsSummary;
	
	// The Layer Data Source
	IBOutlet id dataSource;
	
	// The unique ID for layer
	int uniqueLayerID;
	
	// The document's measure style
	int measureStyle;
	
    NSString *selectedType;
    
    BOOL layerWarningShown;
}

@property (strong) IBOutlet RecentsUtility *recentsUtility;
@property (strong) IBOutlet TextureUtility *textureUtility;
@property (strong) IBOutlet BrushUtility *brushUtility;
@property (strong) IBOutlet LayersUtility *layersUtility;
@property (strong) IBOutlet ToolboxUtility *toolboxUtility;
@property (strong) IBOutlet OptionsUtility *optionsUtility;
@property (strong) IBOutlet InfoUtility *infoUtility;
@property (strong) IBOutlet StatusUtility *statusUtility;

@property (strong) id<PluginClass> lastPlugin;
@property (strong) NSObject *mutex;

// CREATION METHODS

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		initWithPasteboard
	@discussion	Initializes an instance of this class with a single pasteboard
				layer.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithPasteboard;

/*!
	@method		awakeFromNib
	@discussion	Prepares document for use.
*/
- (void)awakeFromNib;

/*!
	@method		saveDocument:
	@discussion Called to save a document (makes current).
	@param		sender
				Ignored.
*/
- (IBAction)saveDocument:(id)sender;

/*!
	@method		saveDocumentAs:
	@discussion Called to save a document as (makes current).
	@param		sender
				Ignored.
*/
- (IBAction)saveDocumentAs:(id)sender;

// GATEWAY METHODS

/*!
	@method		contents
	@discussion	Returns the contents of the document.
	@result		Returns an instance of SeaContent.
*/
- (SeaContent*)contents;

/*!
	@method		whiteboard
	@discussion	Returns the whiteboard of the document.
	@result		Returns an instance of SeaWhiteboard.
*/
- (SeaWhiteboard*)whiteboard;

/*!
	@method		selection
	@discussion	Returns the selection manager of the document.
	@result		Returns an instance of SeaSelection.
*/
- (SeaSelection*)selection;

- (SeaHistogram*)histogram;

/*!
	@method		operations
	@discussion	Returns the operation manager of the document.
	@result		Returns an instance of SeaSelection.
*/
- (id)operations;

/*!
	@method		tools
	@discussion	Returns the tools manager of the document.
	@result		Returns an instance of SeaTools.
*/
- (id)tools;

/*!
 @method        currentTool
 @result        Returns the instance of the current tool
 */
- (AbstractTool*)currentTool;

/*!
 @method        currentToolId
 @result        Returns the ithe current tool identifier
 */
- (int)currentToolId;

/*!
	@method		helpers
	@discussion	Returns an object containing various helper methods for the
				document.
	@result		Returns an instance of SeaHelpers.
*/
- (SeaHelpers*)helpers;

/*!
	@method		warnings
	@discussion	Returns an object contaning the warning related methods.
	@result		Returns an instance of WarningsUtility.
*/
- (WarningsUtility*)warnings;

/*!
	@method		pluginData
	@discussion	Returns the object shared between Seashore and most plug-ins.
	@result		Returns an instance of PluginData.
*/
- (SeaPluginData*)pluginData;

/*!
	@method		docView
	@discussion	Returns the document view of the document.
	@result		Returns an instance of SeaView.
*/
- (SeaView *)docView;

/*!
	@method		window
	@discussion	Returns the window of the document.
	@result		Returns an instance of NSWindow.
*/
- (id)window;

/*!
	@method		updateWindowColor
	@discussion	Updates the color of the window background
*/
- (void)updateWindowColor;

/*!
	@method		textureExporter
	@discussion	Returns the texture exporter.
	@result		Returns an instance of TextureExporter.
*/
- (id)textureExporter;

/*!
 @method        brushExporter
 @discussion    Returns the brush exporter.
 @result        Returns an instance of BrushExporter.
 */
- (id)brushExporter;

// DOCUMENT METHODS

/*!
	@method		readFromFile:ofType:
	@discussion	Reads a given file from disk.
	@param		path
				The path of the file to be read.
	@param		type
				The type of the file to be read.
	@result		Returns YES if the file is successfully read, NO otherwise.
*/
- (BOOL)readFromFile:(NSString *)path ofType:(NSString *)type;

/*!
	@method		writeToFile:ofType:
	@discussion	Writes the document's data to disk.
	@param		path
				The path of the file that the data should be written to.
	@param		type
				The type of the file that the data that should be written to.
	@result		Returns YES if the file is successfully written, NO otherwise.
*/
- (BOOL)writeToFile:(NSString *)filename ofType:(NSString *)ignore;

/*!
	@method		printShowingPrintPanel:
	@discussion	Prints the document, showing the print panel if requested.
	@param		showPanels
				YES if the method should show the associated print panels, NO
				otherwise.
*/
- (void)printShowingPrintPanel:(BOOL)showPanels;

/*!
	@method		prepareSavePanel:
	@discussion	Customizes the save panel, adding a pop-up menu through which
				the user can select a particular exporter.
	@param		savePanel
				The save panel to be adjusted.
	@result		Returns YES if the adjustment was successful, NO otherwise.
*/
- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel;

/*!
	@method		showExporterOptions:
	@discussion	Displays the options for the currently selected exporter.
	@param		sender
				Ignored.
*/
- (IBAction)showExporterOptions:(id)sender;

/*!
	@method		exporterChange:
	@discussion	Changes the active exporter for the document based upon the
				selection of the exportersPopUp.
	@param		sender
				Ignored.
*/
- (IBAction)exporterChanged:(id)sender;

// DOCUMENT EVENT METHODS

/*!
	@method 	close
	@discussion	Called to close the document.
*/
- (void)close;

/*!
	@method		windowDidBecomeMain:
	@discussion	Called when the document is activated.
	@param		notification
				Ignored.
*/
- (void)windowDidBecomeMain:(NSNotification *)notification;

/*!
	@method		windowDidResignMain:
	@discussion	Called when the document loses focus.
	@param		notification
				Ignored.
*/
- (void)windowDidResignMain:(NSNotification *)notification;

/*!
	@method		windowDidResignKey:
	@discussion	Called when the document loses key focus.
	@param		notification
				Ignored.
*/
- (void)windowDidResignKey:(NSNotification *)aNotification;

/*!
	@method		windowWillUseStandardFrame:defaultFrame:
	@discussion	Called when the document wants to zoom.
	@param		sender
				The window zooming
	@param		defaultFrame
				Ignored
	@result		Returns the new frame of the window
*/
- (NSRect) windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame;

/*!
	@method		standardFrame
	@discussion	For calculating the preferred size of the window.
	@result		Returns the rect of the new frame.
*/
- (NSRect) standardFrame;

// EXTRA METHODS

/*!
	@method		uniqueLayerID
	@discussion	Returns a unique ID for a given layer and then increments the
				uniqueLayerID instance variable so the next layer will recieve a
				unique ID. To ensure sequential numbering this method should
				only be called once by the intializer of SeaLayer and its result
				stored.
	@result		Returns an integer representing a new layer may assign to
				itself.
*/
- (int)uniqueLayerID;

/*!
	@method		windowNibName
	@discussion	Returns the name of the NIB file associated with this document's
				window for use by NSDocumentController.
	@result		Returns an NSString representing the name of the NIB file.
*/
- (NSString *)windowNibName;

// MENU RELATED

/*!
	@method		customUndo:
	@param		sender
				Ignored.
	@discussion	Undoes the last change.
*/
- (IBAction)customUndo:(id)sender;

/*!
	@method		customRedo:
	@param		sender
				Ignored.
	@discussion	Redoes the last change.
*/
- (IBAction)customRedo:(id)sender;

/*!
	@method		changeMeasuringStyle:
	@discussion	Changes the measuring style of the document.
	@param		aStyle
				An integer representing the measuring style (see
				Units.h).
*/
- (void)changeMeasuringStyle:(int)aStyle;

/*!
	@method		measureStyle
	@discussion	Returns the measuring style.
	@result		Returns an integer representing the measuring style (see
				Units.h).
*/
- (int)measureStyle;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled.
	@param		menuItem
				The menu item to be validated.
	@result		YES if the menu item should be enabled, NO otherwise.
*/
- (BOOL)validateMenuItem:(id)menuItem;

/*!
    @method     scrollView
	@result		Returns the document main view as a scroll view
*/

- (SeaScrollView *)scrollView;

/*!
	@method		dataSource
	@result		Returns the data source used by the layers view
*/
- (id) dataSource;

/*!
 @method maybeShowLayerWarning
 @discussion maybe show the warning that the current document does not
   support saving layers
*/
- (void)maybeShowLayerWarning;

@end

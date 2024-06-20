#import "Seashore.h"

typedef enum {
	kLayersUpdateAll,
	kLayersUpdateCurrent
} LayersUtilityUpdateEnum;

@class SeaDocument;

@interface LayersUtility : NSObject {
	
	// The LayersView which appears in this utility
	IBOutlet id layersView;
	
	// The panel responsible for layer settings
	IBOutlet id layerSettingsPanel;
	
	// The object for handling layer settings
	IBOutlet id layerSettings;
	
	// The colour select view (this needs to be updated when the channel is changed on an RGBA image)
	IBOutlet id colorSelectView;
	
	// The various layer buttons
	IBOutlet id newButton;
	IBOutlet id duplicateButton;
	IBOutlet id upButton;
	IBOutlet id downButton;
	IBOutlet id deleteButton;
	
	// The document which is the focus of this utility
	__weak IBOutlet SeaDocument *document;
	
	// Whether or not the utility is enabled
	BOOL enabled;

	// The Data Source used by the table that serves as the layers view.
	IBOutlet id dataSource;

    IBOutlet id layerInfoLabel;
}

/*!
	@method		awakeFromNib
	@discussion	Configures the utility's interface.
*/
- (void)awakeFromNib;

/*!
	@method		update:
	@discussion	Updates the utility.
	@param		updateCode
				A Pegasus update code indicating the part of the utility to
				update.
*/
- (void)update:(LayersUtilityUpdateEnum)updateCode;

/*!
	@method		layerSettings
	@discussion	Returns the layer settings manager associated with this object.
	@result		Returns an instance of LayerSettings representing the layer
				settings manager associated with this object.
*/
- (id)layerSettings;

/*!
	@method		show:
	@discussion	Shows the utility's window.
	@param		sender
				Ignored.
*/
- (IBAction)show:(id)sender;

/*!
	@method		hide:
	@discussion	Hides the utility's window.
	@param		sender
				Ignored.
*/
- (IBAction)hide:(id)sender;

/*!
	@method		setEnabled:
	@discussion	Enables or disables the utility.
	@param		value
				YES if the utility should be enabled, NO otherwise.
*/
- (void)setEnabled:(BOOL)value;

/*!
	@method		toggleLayers:
	@discussion	Toggles the visibility of the of the "Layers" tab of the Pegasus
				utility.
	@param		sender
				Ignored.
*/
- (IBAction)toggleLayers:(id)sender;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled and choses the correct menu item title for it if
				appropriate).
	@param		menuItem
				The menu item to be validated.
	@result		YES if the menu item should be enabled, NO otherwise.
*/
- (BOOL)validateMenuItem:(id)menuItem;

/*!
	@method		visible
	@discussion	Returns whether or not the utility's window is visible.
	@result		Returns YES if the utility's window is visible, NO otherwise.
*/
- (BOOL)visible;

// Proxy Actions
/*!
	@method		addLayer:
	@discussion	Adds a new layer to the document.
	@param		sender
				Ignored
*/
- (IBAction)addLayer:(id)sender;

/*!
	@method		duplicateLayer:
	@discussion	Duplicates the current layer in the document.
	@param		sender
				Ignored
*/
- (IBAction)duplicateLayer:(id)sender;

/*!
	@method		deleteLayer:
	@discussion	Deletes the currently selected layer in the document.
	@param		sender
				Ignored
 */
- (IBAction)deleteLayer:(id)sender;

- (IBAction)toggleAllVisibility:(id)sender;

- (void)updateLayerInfo;

@end

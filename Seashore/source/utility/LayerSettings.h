#import "Globals.h"

/*!
	@class		LayerSettings
	@abstract	Handles the panel that allows users to change the various
				settings of the various layers of Seashore.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/

@class SeaLayer;

@interface LayerSettings : NSObject {

	// The document in focus
	IBOutlet id document;
	
	// The PegasusUtility controlling us
	IBOutlet id pegasusUtility;

	// The settings panel
    IBOutlet id panel;
	
	// The text box for entering the layer's title
    IBOutlet id layerTitle;
	
	// The various values
    IBOutlet id leftValue;
    IBOutlet id topValue;
    IBOutlet id widthValue;
    IBOutlet id heightValue;
	
	// The various units
	IBOutlet id leftUnits;
	IBOutlet id topUnits;
	IBOutlet id widthUnits;
	IBOutlet id heightUnits;

	// The units for the panel
	int units;
	
	// The slider that indicates the opacity of the layer
	IBOutlet id opacitySlider;
	
	// The label that reflects the value of the slider
	IBOutlet id opacityLabel;
	
	// The pop-up menu that reflects the current mode of the layer
	IBOutlet id modePopup;
		
	// Whether or not this layer is linked
	IBOutlet id linkedCheckbox;
	
	// Whether or not the alpha layer is enabled
	IBOutlet id alphaEnabledCheckbox;
	
	// Channel editing
	IBOutlet id channelEditingMatrix;
	
	// The layer whose settings are currently being changed
	SeaLayer* settingsLayer;
}

/*!
	@method		activate
	@discussion	Activates the layer settings manager with the document.
*/
- (void)activate;

/*!
	@method		deactivate
	@discussion	Deactivates the layer settings manager.
*/
- (void)deactivate;

/*!
	@method		showSettings:from:
	@discussion	Presents the user with a modal dialog to alter the active
				layer's attributes.
	@param		layer
				The layer the settings are for.
	@param		point
				The point that the mouse was clicked to show the information.
				Used to position the window.
*/
- (void)showSettings:(SeaLayer *)layer from:(NSPoint)point;

/*!
	@method		apply:
	@discussion	Takes the settings from the panel and applies the necessary
				changes to the document.
	@param		sender
				Ignored.
*/
- (IBAction)apply:(id)sender;

/*!
	@method		cancel:
	@discussion	Closes the panel without applying the changes.
	@param		sender
				Ignored.
*/
- (IBAction)cancel:(id)sender;

/*!
	@method		setOffsetsLeft:top:index:
	@discussion	Adjusts the offsets of a given layer (handles updates and
				undos).
	@param		newName
				The name to which the layer should be renamed.
	@param		index
				The index of the layer to rename.
*/
- (void)setOffsetsLeft:(int)left top:(int)top index:(int)index;

/*!
	@method		setName:index:
	@discussion	Renames a given layer (handles updates and undos).
	@param		newName
				The name to which the layer should be renamed.
	@param		index
				The index of the layer to rename.
*/
- (void)setName:(NSString *)newName index:(int)index;

/*!
	@method		changeMode:
	@discussion	Called when the mode of a layer is changed.
	@param		sender
				Ignored.
*/
- (IBAction)changeMode:(id)sender;

/*!
	@method		undoOpacity:to:
	@discussion	Undoes a change in the mode of a layer (this method should only
				ever be called by the undo manager following a call to
				changeMode:).
	@param		index
				The index of the layer to undo the mode change for.
	@param		value
				The desired mode value after the undo.
*/
- (void)undoMode:(int)index to:(int)value;

/*!
	@method		changeOpacity:
	@discussion	Called when the opacity of a layer is changed.
	@param		sender
				Ignored.
*/
- (IBAction)changeOpacity:(id)sender;

/*!
	@method		undoOpacity:to:
	@discussion	Undoes a change in the opacity of a layer (this method should
				only ever be called by the undo manager following a call to
				changeOpacity:).
	@param		index
				The index of the layer to undo the opacity change for.
	@param		value
				The desired opacity value after the undo.
*/
- (void)undoOpacity:(int)index to:(int)value;

/*!
	@method		changeLinked:
	@discussion	Called when the linked checkbox is changed.
	@param		sender
				Ignored.
*/
- (IBAction)changeLinked:(id)sender;

/*!
	@method		changeEnabledAlpha:
	@discussion	Called when the alpha channel is enabled or disabled.
	@param		sender
				Ignored.
*/
- (IBAction)changeEnabledAlpha:(id)sender;

/*!
	@method		changeChannelEditing:
	@discussion	Called when the matrix for channel editing is changed.
	@param		sender
				Ignored.
*/
- (IBAction)changeChannelEditing:(id)sender;

@end

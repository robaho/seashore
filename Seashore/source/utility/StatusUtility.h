#import "Globals.h"

/*!
	@class		StatusUtility
	@abstract	Handles the status bar at the bottom of the window.
	@discussion	Includes channel control, zoom control, dimensions 
				and quick color control.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/

@interface StatusUtility : NSObject {
	// The document that owns the utility
	IBOutlet id document;
	
	// The pop-up men that reflect the currently active channel
	IBOutlet id channelSelectionPopup;
	
	// If this is checked, the user wants to see a normal view, not a channel specific one
	IBOutlet id trueViewCheckbox;

	// The label that displays at the center of the status bar
	IBOutlet id dimensionLabel;
	
	// The actual view that is the status bar
	IBOutlet id view;

	// The text fields that have the colors
	IBOutlet id redBox;
	IBOutlet id greenBox;
	IBOutlet id blueBox;
	IBOutlet id alphaBox;
	IBOutlet id redSlider;
	IBOutlet id greenSlider;
	IBOutlet id blueSlider;
	IBOutlet id alphaSlider;
	
	// The slider that controls the zoom
	IBOutlet id zoomSlider;
}

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
	@method		toggle:
	@discussion	Toggles the visibility of the options bar.
	@param		sender
				Ignored.
*/
- (IBAction)toggle:(id)sender;

/*!
	 @method		update
	 @discussion	Updates the utility to reflect the current cursor position and
					 associated data.
*/
- (void)update;

/*!
	@method		updateZoom
	@discussion	Updates the utility to reflect the current zoom
*/
- (void)updateZoom;

/*!
	@method		updateQuickColor
	@discussion	Updates the utility to reflect the current foreground color
*/
- (void)updateQuickColor;

/*!
	@method		changeChannel:
	@discussion	Called when the user wants to change the channels.
	@param		sender
				Must be the button sending the event.
*/
- (IBAction)changeChannel:(id)sender;

/*!
	@method		channelChanged:
	@discussion	Called when the user has selected a channel option.
	@param		sender
				Must be the menu item sending the event.
*/
- (IBAction)channelChanged:(id)sender;

/*!
	 @method		trueViewChanged:
	 @discussion	Called when the true view box is pressed.
	 @param			sender
					Ignored.
*/
- (IBAction)trueViewChanged:(id)sender;

/*!
	@method		quickColorChange:
	@discussion	Called when the text in the quickcolor boxes are changed.
	@param		sender
				Igonred.
*/
- (IBAction)quickColorChange:(id)sender;

/*!
	@method		changeZoom:
	@discussion	For when the zoom slider is changed.
	@param		sender
				Ignored.
*/
- (IBAction)changeZoom:(id)sender;

/*!
	@method		zoomIn:
	@discussion	For when the zoom in button is pressed.
	@param		sender
				Ignored.
*/
- (IBAction)zoomIn:(id)sender;

/*!
	@method		zoomOut:
	@discussion	For when the zoom out button is pressed.
	@param		sender
				Ignored.
*/
- (IBAction)zoomOut:(id)sender;

/*!
	@method		zoomNormal:
	@discussion	For when the zoom normal button is pressed.
	@param		sender
				Ignored.
*/
- (IBAction)zoomNormal:(id)sender;

@end

#import "Seashore.h"

/*!
	@class		StatusUtility
	@abstract	Handles the status bar at the bottom of the window.
	@discussion	Includes channel control, zoom control, dimensions 
				and quick color control.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/

@class SeaDocument;

@interface StatusUtility : NSObject {
	// The document that owns the utility
	__weak IBOutlet SeaDocument *document;
	
	// The pop-up men that reflect the currently active channel
	IBOutlet id channelSelectionPopup;
	
	// If this is checked, the user wants to see a normal view, not a channel specific one
	IBOutlet id trueViewCheckbox;

	// The label that displays at the center of the status bar
	IBOutlet id dimensionLabel;
	
	// The actual view that is the status bar
	IBOutlet id view;

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

- (void)shutdown;

/*!
	@method		updateZoom
	@discussion	Updates the utility to reflect the current zoom
*/
- (void)updateZoom;

/*!
 @method        channelClicked:
 @discussion    Called when the user has clicked the channels button.
 @param        sender
 Must be the menu item sending the event.
 */
- (IBAction)channelClicked:(id)sender;

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

/*!
    @method        zoomToFit:
    @discussion    For when the zoom to fit button is pressed.
    @param        sender
                Ignored.
*/
- (IBAction)zoomToFit:(id)sender;

@end

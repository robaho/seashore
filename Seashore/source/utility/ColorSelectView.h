#import "Seashore.h"

/*!
	@class		ColorSelectView
	@abstract	Represents the current colour selection to the user.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface ColorSelectView : NSView {
	// The document associated with this colour selection view
	__weak IBOutlet id document;
    __weak IBOutlet NSColorWell *fgWell;
    __weak IBOutlet NSColorWell *bgWell;
}

/*!
	@method		setDocument:
	@discussion	Sets the view and its associated panels to reflect the colours
				of the given document.
	@param		doc
				The document whose colours should be reflected.
*/
- (void)setDocument:(id)doc;

/*!
	@method		swapColors
	@discussion	Swaps the foreground and background colors.
	@param		sender
				Ignored.
*/
- (IBAction)swapColors:(id)sender;

/*!
	@method		defaultColors
	@discussion	Sets the foreground and background colors to their defaults.
	@param		sender
				Ignored.
*/
- (IBAction)defaultColors:(id)sender;

/*!
	@method		changeForegroundColor:
	@discussion	Called when the foreground colour is changed. Updates the view
				and active document.
	@param		sender
				The colour panel responsible for the change in colour.
*/
- (IBAction)changeForegroundColor:(id)sender;

/*!
	@method		changeBackgroundColor:
	@discussion	Called when the background colour is changed. Updates the view
				and active document.
	@param		sender
				The colour panel responsible for the change in colour.
*/
- (IBAction)changeBackgroundColor:(id)sender;

/*!
	@method		update
	@discussion	Updates the view and its associated panels to reflect the
				currently selected background and foreground colours.
*/
- (void)update;
@end

@interface ColorSelectViewColorWell : NSColorWell

@end

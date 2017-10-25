#import "Globals.h"

/*!
	@class		TransparentUtility
	@abstract	Allows the user to select the colour to be used for
				transparency.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface TransparentUtility : NSObject {

	// The current transparent color 
	NSColor *color;
	
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		toggle:
	@discussion	Toggles the visibility of the utility's window.
	@param		sender
				Ignored.
*/
- (IBAction)toggle:(id)sender;

/*!
	@method		changeColor:
	@discussion	Called when the transparency colour is changed. Updates the
				document view for all documents.
	@param		sender
				The colour panel responsible for the change in colour.
*/
- (void)changeColor:(id)sender;

/*!
	@method		color
	@discussion	Returns the current transparency colour.
	@result		Returns the current transparency colour.
*/
- (id)color;

@end

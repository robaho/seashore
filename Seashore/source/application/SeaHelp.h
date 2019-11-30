#import "Globals.h"

/*!
	@class		SeaHelp
	@abstract	Displays help on various matters for Seashore users.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaHelp : NSObject {
	
	// The instant help window
	IBOutlet id instantHelpWindow;
	
	// The label for displaying the instant help text
	IBOutlet id instantHelpLabel;
	
	// Should the user be advised if the download fails?
	BOOL adviseFailure;
	
}

/*!
	@method		openHelp:
	@discussion	Opens the Seashore help manual.
	@param		sender
				Ignored.
*/
- (IBAction)openHelp:(id)sender;

/*!
	@method		openEffectsHelp:
	@discussion	Opens the Seashore effects guide.
	@param		sender
				Ignored.
*/
- (IBAction)openEffectsHelp:(id)sender;

- (IBAction)reportAProblem:(id)sender;

- (IBAction)donateToSeashore:(id)sender;

/*!
	@method		updateInstantHelp:
	@discussion Updates the instant help window with the given string if and
				only if it is visible.
	@param		stringID
				The index of the string in the Instant.plist to be displayed.
*/
- (void)updateInstantHelp:(int)stringID;

@end

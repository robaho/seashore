#import "Globals.h"

/*!
	@class		NSTextViewRedirect
	@abstract	Forwards change font message to the text tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface NSTextViewRedirect : NSTextView {

}

/*!
	@method		changeSpecialFont:
	@discussion	Responds to a font change by fowarding the message to the
				text tool.
	@param		sender
				Ignored.
*/
- (IBAction)changeSpecialFont:(id)sender;

@end

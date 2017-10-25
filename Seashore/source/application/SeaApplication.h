#import "Globals.h"

/*!
	@class		SeaApplication
	@abstract	Handles customizations to NSApplication.
	@discussion	This is the last class in the responder chain, hence the need for the subclass.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2008 Mark Pazolli
*/

@interface SeaApplication : NSApplication {

}

/*!
	@method		validModesForFontPanel:
	@discussion	Returns valid modes for the font panel.
	@param		fontPanel
				The font panel in question.
	@result		Returns a 32-bit string indicating the valid modes for the font panel.
*/
- (unsigned int)validModesForFontPanel:(NSFontPanel *)fontPanel;

@end

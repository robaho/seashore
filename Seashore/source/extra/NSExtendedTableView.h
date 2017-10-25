#import "Globals.h"

/*!
	@class		NSExtendedTableView
	@abstract	Adds the ability to enable and disable table views.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2005 Paul Nelson and
				Copyright (c) 2005 Mark Pazolli
				<br><br>
				<i>See <a href="http://www.pnelsoncomposer.com/writings/NewbieFAQ.html">
				http://www.pnelsoncomposer.com/writings/NewbieFAQ.html</a>
				for the document from which this code came.</i>
*/

@interface NSExtendedTableView : NSTableView {

  NSMutableArray *saveTextColors;
  NSMutableArray *saveBackgroundColors;
  BOOL saveVerticalScrollerEnabled, saveHorizontalScrollerEnabled;

}

@end

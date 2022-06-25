#import "Seashore.h"

/*!
	@class      WarnigsUtility
	@abstract	    Handles messages to the user
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/
#import <Cocoa/Cocoa.h>

enum {
    kUIImportance,
    kHighImportance,
    kModerateImportance,
    kLowImportance,
    kVeryLowImportance
};

@class SeaDocument;

@interface WarningsUtility : NSObject <NSTableViewDataSource> {
	// The host for the utility
	__weak IBOutlet SeaDocument *document;
    __weak IBOutlet NSButton *alertButton;
    NSMutableArray *notices;
    __weak IBOutlet NSPanel *win;
    __weak IBOutlet NSTableView *noticesView;
}

/*!
	@method		addMessage
	@param		message
				The string to display
	@param		importance
				This affects the color
*/
- (void)addMessage:(NSString *)message level:(int)importance;
- (IBAction)showNotices:(id)sender;
@end

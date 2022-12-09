#import "Seashore.h"
#import <SeaComponents/BorderView.h>
#import <SeaComponents/Label.h>

/*!
	@class		OptionsUtility
	@abstract	Displays the options for the current tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/

@interface OptionsUtility : NSObject {
	// The options view
    __weak BorderView *view;
		
	// The last options view set 
	id lastView;

	// The document which is the focus of this utility
	__weak IBOutlet id document;
	
	// The view to show when no document is active
	NSView *blankView;

	// The toolbox utility object
	__weak IBOutlet id toolboxUtility;
	// The currently active tool - not a reliable indication (see code)
	int currentTool;
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		awakeFromNib
	@discussion	Configures the utility's interface.
*/
- (void)awakeFromNib;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

/*!
	@method		update
	@discussion	Updates the utility and the active options object.
*/
- (void)update;

- (id)getOptions:(int)toolId;

/*!
	@method		show:
	@discussion	Shows the options bar.
	@param		sender
				Ignored.
*/
- (IBAction)show:(id)sender;

/*!
	@method		hide:
	@discussion	Hides the options bar.
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
	@method		viewNeedsDisplay
	@discussion	Informs the view it needs display.
*/
- (void)viewNeedsDisplay;

/*!
	@method		visible
	@discussion	Returns whether or not the utility's window is visible.
	@result		Returns YES if the utility's window is visible, NO otherwise.
*/
- (BOOL)visible;

@end

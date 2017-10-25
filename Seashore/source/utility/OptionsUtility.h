#import "Globals.h"

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
    IBOutlet id view;
		
	// The last options view set 
	id lastView;

	// The document which is the focus of this utility
	IBOutlet id document;
	
	// The view to show when no document is active
	IBOutlet id blankView;
	
	// The various options objects
	IBOutlet id lassoOptions;
	IBOutlet id polygonLassoOptions;
	IBOutlet id positionOptions;
	IBOutlet id zoomOptions;
	IBOutlet id pencilOptions;
	IBOutlet id brushOptions;
    IBOutlet id bucketOptions;
	IBOutlet id textOptions;
	IBOutlet id eyedropOptions;
	IBOutlet id rectSelectOptions;
	IBOutlet id ellipseSelectOptions;
	IBOutlet id eraserOptions;
	IBOutlet id smudgeOptions;
	IBOutlet id gradientOptions;
	IBOutlet id wandOptions;
	IBOutlet id cloneOptions;
	IBOutlet id cropOptions;
	IBOutlet id effectOptions;
	
	// The toolbox utility object
	IBOutlet id toolboxUtility;
	
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
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		activate
	@discussion	Activates this utility with its document.
*/
- (void)activate;

/*!
	@method		deactivate
	@discussion	Deactivates this utility.
*/
- (void)deactivate;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

/*!
	@method		currentOptions
	@discussion	Returns the currently active options object.
	@result		Returns the currently active options object (NULL if none).
*/
- (id)currentOptions;

/*!
	@method		getOptions:
	@discussion	Returns the options object associated with a given tool.
	@param		whichTool
				The tool type whose options object you are seeking (see
				SeaTools).
	@result		Returns the options object associated with the given index.
*/
- (id)getOptions:(int)whichTool;

/*!
	@method		update
	@discussion	Updates the utility and the active options object.
*/
- (void)update;

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

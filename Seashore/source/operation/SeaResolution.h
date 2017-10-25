#import "Globals.h"

/*!
	@class		SeaResolution
	@abstract	Changes the resolution of a document according to user
				specifications.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaResolution : NSObject {

	// The document associated with this object
	IBOutlet id document;

	// The panel for changing the current document's resolution
    IBOutlet id sheet;
	
	// The object that handles our scaling
	IBOutlet id seaScale;
	
	// The horizontal and vertical resolution values
    IBOutlet id xValue;
	IBOutlet id yValue;
	
	// The options
	IBOutlet id forceSquare;
	IBOutlet id preserveSize;

}

/*!
	@method		run
	@discussion	Presents the user with a sheet allowing him to configure the
				document's resolution.
*/
- (void)run;

/*!
	@method		apply:
	@discussion	Takes the settings from the configuration sheet and applys the
				necessary changes to the document.
	@param		sender
				Ignored.
*/
- (IBAction)apply:(id)sender;

/*!
	@method		cancel:
	@discussion	Closes the configuration sheet without applying the changes.
	@param		sender
				Ignored.
*/
- (IBAction)cancel:(id)sender;

/*!
	@method		setResolution:
	@discussion	Sets the resolution of the document to the given value (handles
				updates and undos).
	@param		newRes
				The revised resolution.
*/
- (void)setResolution:(IntResolution)newRes;

/*!
	@method		toggleForceSquare:
	@discussion	Called after the user checks/unchecks the force square
				resolution checkbox disabling/enabling the vertical resolution
				text field as appropriate.
	@param		sender
				Ignored.
*/
- (IBAction)toggleForceSquare:(id)sender;

/*!
	@method		togglePreserveSize:
	@discussion	Called after the user checks/unchecks the preserve size checkbox
				enabling/disabling the interpolation pop-up menu as appropriate.
	@param		sender
				Ignored.
*/
- (IBAction)togglePreserveSize:(id)sender;

/*!
	@method		xValueChanged:
	@discussion	Called after the horizontal resolution value is changed in the
				configuration sheet in order to keep the vertical resolution
				value in check.
	@param		sender
				Ignored.
*/
- (IBAction)xValueChanged:(id)sender;

@end

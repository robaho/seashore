#import "Globals.h"

/*!
	@class		UtilitiesManager
	@abstract	Acts as a gateway to all of Seashore's utilities.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface UtilitiesManager : NSObject {
	
	// The controller object
	IBOutlet id controller;
	IBOutlet id transparentUtility;
	
	// Outlets to the various utilities of Seashore
    NSMutableDictionary *pegasusUtilities;
	NSMutableDictionary *transparentUtilities;
	NSMutableDictionary *toolboxUtilities;
	NSMutableDictionary *brushUtilities;
	NSMutableDictionary *optionsUtilities;
	NSMutableDictionary *textureUtilities;
	NSMutableDictionary *infoUtilities;
	NSMutableDictionary *statusUtilities;
	
	// Various choices
	int optionsChoice;
	BOOL infoChoice;
	BOOL colorChoice;
	
}

/*!
	@method		awakeFromNib
	@discussion	Shows or hides the utilities as required.
*/
- (void)awakeFromNib;

/*!
	@method		terminate
	@discussion	Remembers the visibilities of the utilities (if required) and
				shuts them down.
*/
- (void)terminate;

/*!
	@method		shutdownFor:
	@discussion	Shuts down the appropriate utilites for the given document
	@param		doc
				The document that is now closing.
*/
- (void)shutdownFor:(id)doc;

/*!
	@method		activate
	@discussion	Activates all utilities with the given document.
	@param		doc
				The document to activate the utilities with.
*/
- (void)activate:(id)sender;

/*!
	@method		pegasusUtilityFor:
	@discussion	Returns the Pegasus utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of PegasusUtility.
*/
- (id)pegasusUtilityFor:(id)doc;
- (void)setPegasusUtility:(id)util for:(id)doc;

/*!
	@method		transparentUtilityFor:
	@discussion	Returns the transparent colour utility.
	@result		Returns an instance of TransparentUtility.
*/
- (id)transparentUtility;

/*!
	@method		toolboxUtilityFor:
	@discussion	Returns the toolbox utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of ToolboxUtility.
*/
- (id)toolboxUtilityFor:(id)doc;
- (void)setToolboxUtility:(id)util for:(id)doc;

/*!
	@method		brushUtilityFor:
	@discussion	Returns the brush utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of BrushUtility.
*/
- (id)brushUtilityFor:(id)doc;
- (void)setBrushUtility:(id)util for:(id)doc;


/*!
	@method		textureUtilityFor:
	@discussion	Returns the texture utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of TextureUtility.
*/
- (id)textureUtilityFor:(id)doc;
- (void)setTextureUtility:(id)util for:(id)doc;

/*!
	@method		optionsUtilityFor:
	@discussion	Returns the options utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of OptionsUtility.
*/
- (id)optionsUtilityFor:(id)doc;
- (void)setOptionsUtility:(id)util for:(id)doc;

/*!
	@method		infoUtilityFor:
	@discussion	Returns the information utility.
	@param		doc
				The document that the utility is requested for.	
	@result		Returns an instance of InfoUtility.
*/
- (id)infoUtilityFor:(id)doc;
- (void)setInfoUtility:(id)util for:(id)doc;

/*!
	@method		statusUtilityFor:
	@discussion	Returns the status utility.
	@param		doc
				The document that the utility is requested for.	
	@result		Returns an instance of StatusUtility.
*/
- (id)statusUtilityFor:(id)doc;
- (void)setStatusUtility:(id)util for:(id)doc;


@end

#import "Seashore.h"
#import "AbstractScaleOptions.h"
#import "NSTextFieldRedirect.h"

/*!
	@class		TextOptions
	@abstract	Handles the options pane for the text tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface TextOptions : AbstractScaleOptions {

	// The proxy object
	IBOutlet id seaProxy;

	// The pop-up menu specifying the alignment to be used
	IBOutlet id alignmentControl;

	// The checkbox specifying the outline of the font
	IBOutlet id outlineCheckbox;

    // The slider specifying the outline of the font
	IBOutlet id outlineSlider;
		
	// A label specifying the font
	IBOutlet id fontLabel;

    IBOutlet NSTextFieldRedirect *textArea;
	
    __weak IBOutlet NSTextField *lineSpacingLabel;

    __weak IBOutlet NSSlider *lineSpacing;

    // The font manager associated with the text tool
	NSFontManager *fontManager;
	
    __weak IBOutlet NSButton *addNewLayerButton;
    __weak IBOutlet NSButton *mergeWithLayerButton;
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		showFonts:
	@discussion	Shows the fonts panel to select the font to be used for the
				text.
	@param		sender
				Ignored.
*/
- (IBAction)showFonts:(id)sender;

/*!
	@method		changeFont:
	@discussion	Handles a change in the selected font.
	@param		sender
				Ignored.
*/
- (IBAction)changeFont:(id)sender;

/*!
	@method		alignment
	@discussion	Returns the alignment to be used with the text tool.
	@result		Returns an NSTextAlignment representing an alignment type.
*/
- (NSTextAlignment)alignment;

/*!
	@method		outline
	@discussion	Returns the number of points the outline should be.
	@result		Returns an integer indicating the number of points the outline should be
				or zero if outline is disabled.
*/
- (int)outline;

/*!
	@method		useTextures
	@discussion	Returns whether or not the tool should use textures.
	@result		Returns YES if the tool should use textures, NO if the tool
				should use the foreground colour.
*/
- (BOOL)useTextures;

-(float)lineSpacing;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

- (NSString*)text;

-(void)reset;

@end

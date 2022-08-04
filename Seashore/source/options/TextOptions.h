#import "Seashore.h"
#import "AbstractScaleOptions.h"
#import "NSTextFieldRedirect.h"
#import "SeaTextLayer.h"

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

    __weak IBOutlet NSSliderCell *verticalMargin;
    
    __weak IBOutlet NSColorWell *colorWell;
    // The font manager associated with the text tool
	NSFontManager *fontManager;
	
    NSFont *font;
    NSColor *color;

    NSBezierPath *textPath;
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

- (TextProperties*)properties;
- (void)setProperties:(TextProperties*)props;

@end

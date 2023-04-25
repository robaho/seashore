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
@interface MyTextView : NSTextView
- (void)setPlaceholderString:(NSString*)s;
@end


@interface TextOptions : AbstractScaleOptions {
	// The pop-up menu specifying the alignment to be used
	NSSegmentedControl *alignmentControl;

	id outlineSlider;
	id fontButton;
    id lineSpacingSlider;
    id verticalMarginSlider;
    id colorWell;
    id boundsButton;

    NSSegmentedControl *textControls;

    MyTextView *textArea;
	
    // The font manager associated with the text tool
	NSFontManager *fontManager;
	
    NSFont *font;
    NSColor *color;

    NSBezierPath *textPath;
}

- (TextProperties*)properties;
- (void)setProperties:(TextProperties*)props;

@end

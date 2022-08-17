#import "Seashore.h"
#import "TextOptions.h"
#import "AbstractScaleTool.h"

/*!
	@class		TextTool
	@abstract	The text tool's role is much the same as in any paint program.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface TextTool : AbstractScaleTool {
    TextOptions *options;
    BOOL edittingLayer;
    BOOL addingLayer;
    BOOL hasUndo;
    IntRect textRect; // used when creating new layer
}

- (IntRect)bounds;
- (NSBezierPath*)textPath;
- (void)updateLayer;
- (IBAction)setTextBoundsFromSelection:(id)sender;

@end

#import "Seashore.h"
#import "AbstractOptions.h"

/*		
	@class		AbstractPaintOptions
	@abstract	Acts as a base class for the options panes of the paint-type tools.
	@discussion	This class is responsible for connection actions of brushes and 
				textures to the options classes.
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface AbstractPaintOptions : AbstractOptions {
    id opacitySlider;
    NSView* brushesButton;
    NSView* texturesButton;
}
/*!
 @method        opacity
 @discussion    Returns the opacity to be used with the eraser tool.
 @result        Returns an integer indicating the opacity (between 0 and 255
 inclusive) to be used with the eraser tool.
 */
- (int)opacity;
- (float)opacityFloat;
- (void)setOpacityFloat:(float)opacity;
- (void)loadOpacity:(NSString*)tag;
- (BOOL)useTextures;

@end

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
    // A slider indicating the opacity of the bucket
    IBOutlet id opacitySlider;

    // A label displaying the opacity of the bucket
    IBOutlet id opacityLabel;
}

/*!
	@method		toggleTextures:
	@discussion	Toggles the modal textures panel.
	@param		sender
				Ignored.
*/
- (IBAction)toggleTextures:(id)sender;


/*!
	@method		toggleBrushes:
	@discussion	Toggles the modal brushes panel.
	@param		sender
				Ignored.
*/
- (IBAction)toggleBrushes:(id)sender;

/*!
 @method        opacityChanged:
 @discussion    Called when the opacity is changed.
 @param        sender
 Ignored.
 */
- (IBAction)opacityChanged:(id)sender;

/*!
 @method        opacity
 @discussion    Returns the opacity to be used with the eraser tool.
 @result        Returns an integer indicating the opacity (between 0 and 255
 inclusive) to be used with the eraser tool.
 */
- (int)opacity;

- (void)loadOpacity:(NSString*)tag;

@end

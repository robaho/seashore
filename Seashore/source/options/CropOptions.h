#import "Seashore.h"
#import "AbstractScaleOptions.h"
#import "AspectRatio.h"

/*!
	@class		CropOptions
	@abstract	Handles the options pane for the cropping tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface CropOptions : AbstractScaleOptions {
	// The AspectRatio instance linked to this options panel
	AspectRatio *aspectRatio;
}

/*!
	@method		cropImage:
	@discussion	Crops the image to given rectangle.
	@param		sender
				Ignored.
*/
- (IBAction)cropImage:(id)sender;


/*!
 @method        cropLayer:
 @discussion    Crops the current layer to given rectangle.
 @param        sender
 Ignored.
 */
- (IBAction)cropLayer:(id)sender;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end

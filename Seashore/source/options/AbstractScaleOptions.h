#import "Seashore.h"
#import "AbstractOptions.h"

/*		
	@class		AbstractScaleOptions
	@abstract	Acts as a base class for the options panes of the scaling tools.
	@discussion	This class is responsible for keeping track of the mode of the aspect ratio
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface AbstractScaleOptions : AbstractOptions {
	// If shift is held down we need to 
	int aspectType;
    BOOL oneToOne;
}

/*!
	@method		ratio
	@discussion	Returns the ratio/size for the rect.
				If tool does not have a rect, this method is not needed.
	@result		Returns a NSSize for the crop in the aspect type's
				units. If it is a ratio the width = X / Y and the 
				height = Y / X.
*/
- (NSSize)ratio;

/*!
	@method		aspectType
	@discussion	Returns the type of aspect ratio.
	@result		Returns a constant representing the type of aspect ratio
				(see AspectRatio).
*/
- (int)aspectType;

- (void)setOneToOne:(BOOL)b;

- (BOOL)isOneToOne;

- (void)aspectChanged:(id)sender;
@end

#import "Seashore.h"

/*!
	@enum		k...Flip
	@constant	kHorizontalFlip
				Specifies a horizontal flip.
	@constant	kVerticalFlip
				Specifies a vertical flip.
*/
enum {
	kHorizontalFlip,
	kVerticalFlip
};

/*!
	@class		SeaFlip
	@abstract	     Handles the flipping of selections for Seashore.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@class SeaDocument;

@interface SeaFlip : NSObject
{

	// The document associated with this object
    __weak IBOutlet SeaDocument *document;
	
}

- (void)flipLayerHorizontally;
- (void)flipLayerVertically;
- (void)flipSelectionHorizontally;
- (void)flipSelectionVertically;

@end

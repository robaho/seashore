#import "Globals.h"

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
	@abstract	Handles the flipping of selections for Seashore.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaFlip : NSObject
{

	// The document associated with this object
    IBOutlet id document;
	
}

- (void)floatingFlip:(int)type;
- (void)floatingHorizontalFlip;
- (void)floatingVerticalFlip;
- (void)standardFlip:(int)type;

/*!
	@method		simpleFlipOf:width:height:spp:type:
	@discussion	Flips the given data
	@param		data
				A pointer to the data to flip.
	@param		width
				The width of the data.
	@param		height
				The height of the data.
	@param		spp
				The samples per pixel of the data.
	@param		type
				The type of flip to preform on the data.
*/
- (void)simpleFlipOf:(unsigned char*)data width:(int)width height:(int)height spp:(int)spp type:(int)type;

/*!
	@method		run:
	@discussion	Flips the current selection in the desired manner or, if nothing
				is selected, the entire layer.
	@param		type
				The type of flip (see SeaFlip).
*/
- (void)run:(int)type;

@end

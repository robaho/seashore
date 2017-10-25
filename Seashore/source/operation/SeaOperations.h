#import "Globals.h"

/*!
	@class		SeaOperations
	@abstract	Acts as a gateway to the various operations of Seashore.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaOperations : NSObject {

	// Outlets to the instances of the same name
	IBOutlet id seaAlignment;
    IBOutlet id seaMargins;
    IBOutlet id seaResolution;
    IBOutlet id seaScale;
	IBOutlet id seaDocRotation;
	IBOutlet id seaRotation;
	IBOutlet id seaFlip;

}

/*!
	@method		seaAlignment
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the SeaAlignment class.
*/
- (id)seaAlignment;

/*!
	@method		seaMargins
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the SeaMargins class.
*/
- (id)seaMargins;

/*!
	@method		seaResoulution
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the SeaResoulution class.
*/
- (id)seaResolution;

/*!
	@method		seaScale
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the SeaScale class.
*/
- (id)seaScale;

/*!
	@method		seaDocRotation
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the SeaDocRotation class.
*/
- (id)seaDocRotation;

/*!
	@method		seaRotation
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the SeaRotation class.
*/
- (id)seaRotation;

/*!
	@method		seaFlip
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the SeaFlip class.
*/
- (id)seaFlip;

@end

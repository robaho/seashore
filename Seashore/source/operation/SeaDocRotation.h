#import "Globals.h"

/*!
	@class		SeaDocRotation
	@abstract	Rotates documents.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaDocRotation : NSObject
{

	// The document and sheet associated with this object
    IBOutlet id document;
	
}

/*!
	@method		flipDocHorizontally
	@discussion	Flips the document horizontally.
*/
- (void)flipDocHorizontally;

/*!
	@method		flipDocVertically
	@discussion	Flips the document vertically.
*/
- (void)flipDocVertically;

/*!
	@method		rotateDocLeft
	@discussion	Rotates the document 90 degrees counter-clockwise.
*/
- (void)rotateDocLeft;

/*!
	@method		rotateDocRight
	@discussion	Rotates the document 90 degrees clockwise.
*/
- (void)rotateDocRight;

@end

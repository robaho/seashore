#import "Globals.h"
#import "SeaLayer.h"
#import "XBMContent.h"

/*!
	@class		XBMLayer
	@abstract	Loads a particular layer from an XBM file.
	@discussion	See http://www.dcs.ed.ac.uk/home/mxr/gfx/2d/XBM.txt for more
				information on the X BitMap Format.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface XBMLayer : SeaLayer {

}

/*!
	@method		initWithFile:document:shareInfo:
	@discussion	Initializes an instance of this class with the layer at a given
				offset inside a given file.
	@param		file
				The file containing the layer.
	@param		offset
				The offset at which the layer begins.
	@param		doc
				The document to be associated with this instance.
	@param		info
				A pointer to an information record for exchanging information
				with the XBMContent class (see XBMContent documentation for more
				information).
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithFile:(FILE *)file offset:(int)offset document:(id)doc sharedInfo:(SharedXBMInfo *)info;

@end

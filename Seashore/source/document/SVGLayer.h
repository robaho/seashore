#import "Globals.h"
#import "SeaLayer.h"

/*!
	@class		SVGLayer
	@abstract	Make a layer from an image representation.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2005 Mark Pazolli
*/

@interface SVGLayer : SeaLayer {

}

/*!
	@method		initWithImageRep:document:spp:
	@discussion	Initializes an instance of this class with the given image
				representation and document.
	@param		imageRep
				The image representation with which to initialize this layer.
				Please note the imageRep data will be loaded as grayscale or
				colour independent of the document type (as such you may want to
				use SeaLayer's conversion routines after this method).
	@param		doc
				The document to be associated with this instance.
	@param		lspp
				The samples per pixel of the layer. This argument may seem
				redundant but it's not.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithImageRep:(id)imageRep document:(id)doc spp:(int)lspp;

@end

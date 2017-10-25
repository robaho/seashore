/*!
	@header		Bucket
	@abstract	Contains functions to help with bucket fills. 
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
				Copyright (c) 2005 Daniel Jalkut
*/

#import "Globals.h"

/*!
	@function	bucketFill
	@discussion	Given a seed point replaces all neighbouring pixels of similar
				colours with a single given colour. The function does not work
				on the bitmap directly but instead on an overlay which can later
				be composited on to the bitmap.
	@param		spp
				The samples per pixel of the bitmap and overlay.
	@param		rect
				The largest region of the bitmap to fill (must lie entirely
				within bitmap).
	@param		overlay
				The block of memory containing the overlay data. Rather than
				change pixels of the bitmap directly, changes will be made to
				this block which can then be manipulated.
	@param		data
				The block of memory containing the bitmap data.
	@param		width
				The width of both the bitmap and overlay.
	@param		height
				The height of both the bitmap and overlay.
	@param		seeds
				The seed points at which to begin filling.
	@param		numSeeds
				The number of seed points in the array.
	@param		fillColor
				The colour with which to replace the various pixels.
	@param		tolerance
				Pixels will only be replaced if their channel(s) are within this
				tolerance of the seed point. A tolerance of 255 indicates that
				all pixels should be replaced in the given rectangle (bucketFill
				works much faster on such calls).
	@param		channel
				The channel(s) to use in determining whether a pixel meets the
				above condition.
	@result		Returns the smallest possible IntRect including all affected
				pixels.
*/
IntRect bucketFill(int spp, IntRect rect, unsigned char *overlay, unsigned char *data, int width, int height, IntPoint seeds[], int numSeeds, unsigned char *fillColor, int tolerance, int channel);

/*!
	@function	textureFill
	@discussion	Given a bitmap, this function fills the bitmap with the given
				texture replacing the bitmap's colour but preserving the
				bitmap's transparency. It is often applied to the overlay.
	@param		spp
				The samples per pixel of the bitmap and the texture.
	@param		rect
				The region of the bitmap to replace with the given texture (must
				lie entirely within bitmap).
	@param		data
				The block of memory containing the bitmap data.
	@param		width
				The width of the bitmap.
	@param		height
				The height of the bitmap.
	@param		texture
				The block of memory containing the texture bitmap data.
	@param		textureWidth
				The width of the texture bitmap.
	@param		textureHeight
				The height of the texture bitmap.
*/
void textureFill(int spp, IntRect rect, unsigned char *data, int width, int height, unsigned char *texture, int textureWidth, int textureHeight);

/*!
	@function	cloneFill
	@discussion	Given a bitmap, this function fills the bitmap with the provided
				data.
	@param		spp
				The samples per pixel of the bitmap and the source.
	@param		rect
				The region of the bitmap to replace with the given source (must
				lie entirely within bitmap).
	@param		data
				The block of memory containing the bitmap data.
	@param		replace
				The block of memory containing the replace data.
	@param		width
				The width of the bitmap.
	@param		height
				The height of the bitmap.
	@param		source
				The block of memory containing the source data.
	@param		sourceWidth
				The width of the source data.
	@param		sourceHeight
				The height of the source data.
	@param		spt
				The point where the rectangle is taken from in the source data.
*/
void cloneFill(int spp, IntRect rect, unsigned char *data, unsigned char *replace, int width, int height, unsigned char *source, int sourceWidth, int sourceHeight, IntPoint spt);


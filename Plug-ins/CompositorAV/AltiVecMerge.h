/*!
	@header		AltiVecMerge
	@abstract	Contains functions to help with the merging of layers, these
				functions are AltiVec-enabled.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

#ifndef NO_ALTIVEC

#import "Globals.h"
#import "AltiVecCore.h"

/*!
	@function	specialMergeAV
	@discussion	Given two bitmap vectors SOURCE and DEST this function returns
				the result of compositing the SOURCE vector onto the DEST vector
				using the special merge technique.
	@param		spp
				The samples per pixel of the bitmap vectors (can be 2 or 4).
	@param		SOURCE
				The bitmap vector being composited.
	@param		DEST
				The bitmap vector upon which the SOURCE is being composited.
	@param		OPACITY
				A vector for which the alpha channel element is set to the
				opacity value with which the SOURCE should be composited. A
				value of NULL indicates the SOURCE should be composited at  full
				opacity.
	@result		Returns a bitmap vector representing the result of compositing.
*/
inline vector unsigned char specialMergeAV(int spp, vector unsigned char DEST, vector unsigned char SOURCE, vector unsigned char *OPACITY);

/*!
	@function	normalMergeAV
	@discussion	Given two bitmap vectors SOURCE and DEST this function returns
				the result of compositing the SOURCE vector onto the DEST vector
				using the normal merge technique.
	@param		spp
				The samples per pixel of the bitmap vectors (can be 2 or 4).
	@param		SOURCE
				The bitmap vector being composited.
	@param		DEST
				The bitmap vector upon which the SOURCE is being composited.
	@param		OPACITY
				A vector for which the alpha channel element is set to the
				opacity value with which the SOURCE should be composited. A
				value of NULL indicates the SOURCE should be composited at  full
				opacity.
	@result		Returns a bitmap vector representing the result of compositing.
*/
inline vector unsigned char normalMergeAV(int spp, vector unsigned char DEST, vector unsigned char SOURCE, vector unsigned char *OPACITY);

/*!
	@function	eraseMergeAV
	@discussion	Given two bitmap vectors SOURCE and DEST this function returns
				the result of compositing the SOURCE vector onto the DEST vector
				using the erase merge technique.
	@param		spp
				The samples per pixel of the bitmap vectors (can be 2 or 4).
	@param		SOURCE
				The bitmap vector being composited.
	@param		DEST
				The bitmap vector upon which the SOURCE is being composited.
	@param		OPACITY
				A vector for which the alpha channel element is set to the
				opacity value with which the SOURCE should be composited. A
				value of NULL indicates the SOURCE should be composited at  full
				opacity.
	@result		Returns a bitmap vector representing the result of compositing.
*/
inline vector unsigned char eraseMergeAV(int spp, vector unsigned char DEST, vector unsigned char SOURCE, vector unsigned char *OPACITY);

/*!
	@function	primaryMergeAV
	@discussion	Given two bitmap vectors SOURCE and DEST this function returns
				the result of compositing the SOURCE vector onto the DEST vector
				using the primary merge technique.
	@param		spp
				The samples per pixel of the bitmap vectors (can be 2 or 4).
	@param		SOURCE
				The bitmap vector being composited.
	@param		DEST
				The bitmap vector upon which the SOURCE is being composited.
	@param		OPACITY
				A vector for which the alpha channel element is set to the
				opacity value with which the SOURCE should be composited. A
				value of NULL indicates the SOURCE should be composited at  full
				opacity.
	@result		Returns a bitmap vector representing the result of compositing.
*/
inline vector unsigned char primaryMergeAV(int spp, vector unsigned char DEST, vector unsigned char SOURCE, vector unsigned char *OPACITY);

/*!
	@function	alphaMergeAV
	@discussion	Given two bitmap vectors SOURCE and DEST this function returns
				the result of compositing the SOURCE vector onto the DEST vector
				using the alpha merge technique.
	@param		spp
				The samples per pixel of the bitmap vectors (can be 2 or 4).
	@param		SOURCE
				The bitmap vector being composited.
	@param		DEST
				The bitmap vector upon which the SOURCE is being composited.
	@param		OPACITY
				A vector for which the alpha channel element is set to the
				opacity value with which the SOURCE should be composited. A
				value of NULL indicates the SOURCE should be composited at  full
				opacity.
	@result		Returns a bitmap vector representing the result of compositing.
*/
inline vector unsigned char alphaMergeAV(int spp, vector unsigned char DEST, vector unsigned char SOURCE, vector unsigned char *OPACITY);

#endif
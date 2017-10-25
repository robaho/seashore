/*!
	@header		AltiVecCore
	@abstract	Contains various functions that help Seashore effectively
				interact with AltiVec.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

#ifndef NO_ALTIVEC

#import "Globals.h"

/*!
	@function	mvec_mult
	@discussion	Multiplies each byte of vector A with each of vector B in  the
				same way as int_mult would multiply the bytes.
	@param		A
				A vector of bytes.
	@param		B
				A vector of bytes.
	@result		Returns a vector of bytes where each byte is the product of 
				each byte of A and B scaled so that the answer lies between 0
				and 255.
*/
inline vector unsigned char mvec_mult(vector unsigned char A, vector unsigned char B);

/*!
	@function	mvec_get_uchar
	@discussion	Returns the specified byte of a vector.
	@param		A
				A vector of bytes.
	@param		pos
				The position of the byte we want to inspect.
	@result		Returns the value of the byte in the given postion of A.
*/
inline unsigned char mvec_get_uchar(vector unsigned char A, int pos);

/*!
	@function	mvec_set_uchar
	@discussion	Sets the specified byte of a vector to a given value.
	@param		A
				A vector of bytes.
	@param		pos
				The position of the byte we want to set.
	@param		e
				The value we want to set the byte to.
*/
inline void mvec_set_uchar(vector unsigned char *A, int pos, unsigned char e);

#endif
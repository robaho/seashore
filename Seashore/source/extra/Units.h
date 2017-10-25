/*!
	@header		Units
	@abstract	Contains various fuctions relating to units.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
*/

#import "Globals.h"

/*!
	@enum		k...Units
	@constant	kPixelUnits
				The units are pixels.
	@constant	kInchUnits
				The units are inches.
	@constant	kMillimeterUnits
				The units are millimetres.
*/
enum {
	kPixelUnits,
	kInchUnits,
	kMillimeterUnits
};

/*!
	@function	StringFromPixels
	@discussion	Converts a number of pixels to a string represeting the given units.
	@param		pixels
				The number of pixels.
	@param		units
				The units being used.
	@param		resolution
				The resolution being used.
	@result		Returns an NSString that is good for displaying the units.
*/
NSString *StringFromPixels(int pixels, int units, int resolution);

/*!
	@function	PixelsfromFloat
	@discussion	Converts a float represeting the given units into a number of pixels.
	@param		measure
				The measure being converted.
	@param		units
				The units being used.
	@param		resolution
				The resolution being used.
	@result		Returns an int that is the exact number of pixels.
*/
int PixelsFromFloat(float measure, int units, int resolution);

/*!
	@function	UnitsString
	@discussion	Gives a label to different unit types.
	@param		units
				The units to display.
	@result		Returns an NSString that is the label for the units.
*/
NSString *UnitsString(int units);

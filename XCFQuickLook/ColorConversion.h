/*!
	@header		ColorConversion
	@abstract	Converts RGB colours to HLS or HSV colours and vice- versa.
	@discussion	For most colour conversion in Seashore ColorSync is used however
				sometimes raw speed is important and/or colour calibration is
				not. In those cases, the functions of this header can help you
				out.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli and
				Copyright (c) 1995 Spencer Kimball and Peter Mattis
*/

#import "Globals.h"

/*!
	@function	RGBtoHSV
	@discussion	Converts a set of RGB (red, green, blue) values to HSV hue
				saturation value) values.
	@param		red
				The red component's value, upon return will be equal to the hue
				component's value.
	@param		green
				The green component's value, upon return will be equal to the
				saturation component's value.
	@param		blue
				The blue component's value, upon return will be equal to the
				value component's value.
*/
 void RGBtoHSV(int *red, int *green, int *blue);

/*!
	@function	HSVtoRGB
	@discussion	Converts a set of HSV (hue saturation value) values to  RGB red,
				green, blue) values.
	@param		hue
				The hue component's value, upon return will be equal to the red
				component's value.
	@param		saturation
				The saturation component's value, upon return will be equal to
				the green component's value.
	@param		value
				The value component's value, upon return will be equal to the
				blue component's value.
*/
 void HSVtoRGB(int *hue, int *saturation, int *value);

/*!
	@function	RGBtoHLS
	@discussion	Converts a set of RGB (red, green, blue) values to HSV hue
				lightness saturation) values.
	@param		red
				The red component's value, upon return will be equal to the hue
				component's value.
	@param		green
				The green component's value, upon return will be equal to the
				lightness component's value.
	@param		blue
				The blue component's value, upon return will be equal to the
				saturation component's value.
*/
 void RGBtoHLS (int *red, int *green, int *blue);

/*!
	@function	HLStoRGB
	@discussion	Converts a set of HLS (hue lightness saturation) values  to RGB
				red, green, blue) values.
	@param		hue
				The hue component's value, upon return will be equal to the red
				component's value.
	@param		lightness
				The lightness component's value, upon return will be equal to
				the green component's value.
	@param		saturation
				The saturation component's value, upon return will be equal to
				the blue component's value.
*/
 void HLStoRGB(int *hue, int *lightness, int *saturation);


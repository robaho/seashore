/*!
	@header		Globals
	@abstract	Contains information that will be included in all project files.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

#import "Rects.h"
#import "Constants.h"

#ifdef __BIG_ENDIAN__
#define MSB 0
#define LSB 1
#else
#define MSB 1
#define LSB 0
#endif

/*!
	@defined	sqr(x)	
	@discussion	A macro that when given any numeric value squares it.
*/
#define	sqr(x) ((x) * (x))

/*!
	@defined	sgn(x)	
	@discussion	A macro that returns the sign of the numeric value given.
*/
#define	sgn(x) (((x) < 0) ? (-1) : (1))

/*!
	@defined	int_mult(a, b, t)
	@discussion	A macro that when given two unsigned characters (bytes)
				determines the product of the two. The returned value is scaled
				so it is between 0 and 255. A third argument,  a temporary
				integer, must also be passed to allow the calculation to
				complete. 
*/
#define int_mult(a,b,t)  ((t) = (a) * (b) + 0x80, ((((t) >> 8) + (t)) >> 8))

/*!
	@defined	make_128(x)
	@discussion	A macro that ensures its integer argument is greater than its
				original value and divisible by 16. This is useful if the result
				is being used to allocate memory that may be subject to AltiVec
				operations which must operate on  128-bits at a time.
*/
#define make_128(x) (x + 16 - (x % 16))

/*!
	@defined	PI
	@discussion	The value of pi to 8 decimal places.
*/
#define PI 3.14159265

/*!
	@defined	gUserDefaults
	@discussion	Allows quick reference to the standard user defaults manager.
*/
#define gUserDefaults [NSUserDefaults standardUserDefaults]

/*!
	@defined	gColorPanel
	@discussion	Allows quick reference to the shared colour panel.
*/
#define gColorPanel [NSColorPanel sharedColorPanel]

/*!
	@defined	gFileManager
	@discussion	Allows quick reference to the defualt file manager.
*/
#define gFileManager [NSFileManager defaultManager]

/*!
	@defined	gMainBundle
	@discussion	Allows quick reference to the main bundle.
*/
#define gMainBundle [NSBundle mainBundle]

/*!
	@defined	gCurrentDocument
	@discussion	Allows quick reference to the current document.
*/
#define gCurrentDocument [[NSDocumentController sharedDocumentController] currentDocument]

/*!
	@defined	LOCALSTR(x, y)
	@discussion	A macro that allows easy access to the localizedStringForKey:
				method.
*/
#define LOCALSTR(x, y) [gMainBundle localizedStringForKey:x value:y table:NULL]

/*!
	@typedef	IntResolution
	@discussion	Creates a phony type, IntResolution, which has the same fields
				as IntPoint.
*/
typedef IntPoint IntResolution;

#ifndef NSAppKitVersionNumber10_2
#define NSAppKitVersionNumber10_2 663
#endif
#ifndef NSAppKitVersionNumber10_3
#define NSAppKitVersionNumber10_3 743
#endif
#ifndef NSAppKitVersionNumber10_4
#define NSAppKitVersionNumber10_4 824
#endif
#ifndef NSAppKitVersionNumber10_4_6
#define NSAppKitVersionNumber10_4_6 824.38
#endif

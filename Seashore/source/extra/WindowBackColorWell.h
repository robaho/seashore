/*!
	@header		WindowBackColorWell
	@abstract	A custom color well for the window back preference
	@discussion	This custom color well is necessary because otherwise the color picker for the window
				background preference can become mangled with other color pickers.
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import "Globals.h"

@interface WindowBackColorWell : NSColorWell
{

	// An instance of the class of the same name
	IBOutlet id seaPrefs;

}

/*!
	@method		activate:
	@discussion	Activates the receiver, displays the color panel, and makes the current
				color the same as its own.
	@param		exclusive
				YES to deactivate any other color wells; NO to keep them active. If a
				color panel is active with exclusive set to YES and another is subsequently
				activated with exclusive set to NO, the exclusive setting of the first panel
				is ignored.
*/
- (void)activate:(BOOL)exclusive;

/*!
	@method		setColor:
	@discussion	Sets the color of the receiver and redraws the receiver (no checks).
	@param		color
				The new color for the color well.
*/
- (void)setInitialColor:(NSColor *)color;

/*!
	@method		setColor:
	@discussion	Sets the color of the receiver and redraws the receiver (checks for correct color
				picker).
	@param		color
				The new color for the color well.
*/
- (void)setColor:(NSColor *)color;

@end

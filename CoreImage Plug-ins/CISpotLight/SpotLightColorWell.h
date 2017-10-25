/*!
	@header		SpotLightColorWell
	@abstract	A custom color well for the plug-in.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>

@interface SpotLightColorWell : NSColorWell
{

	// The instance of the same new
	IBOutlet id ciSpotLight;

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
	@discussion	Sets the color of the receiver and redraws the receiver.
	@param		color
				The new color for the color well.
*/
- (void)setColor:(NSColor *)color;

@end

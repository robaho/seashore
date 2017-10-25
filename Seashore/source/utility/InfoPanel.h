#import "Globals.h"

/*!
	@enum		k...PanelStyle
	@constant	kFloatingPanelStyle
				A basic floating panel unattached to any window elements
	@constant	kVerticalPanelStyle
				A panel with an arrow on the top.
				Generally, comes from elements in a horizontal list 
				(so a vertical panel will not obscure too many elements).
	@constant	kHorizontalPanelStyle
				A panel with an arrow on the left side.
				This would be for a vertical list of elements.
*/
enum {
	kFloatingPanelStyle,
	kVerticalPanelStyle,
	kHorizontalPanelStyle
};

/*!
	@class		InfoPanel
	@abstract	A class for Seashore-specific modal information panels. 
	@discussion	This type of panel is inspired by iCal's information panels,
				and has arrows to point to the source of the relevant content.
				It must have a InfoPanelBacking view as its content view to 
				work properly.
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface InfoPanel : NSPanel {
	// Info panels can come in a few different styles.
	// This stores what we currently think the style is.
	int panelStyle;
	
	// Sometimes the panel is too close to the edge of the screen
	// to fit, so it has to be flipped
	BOOL panelFilpped;
}

/*!
	@method		panelStyle
	@discussion	Allows other objects to know what kind of panel they are dealing with
	@result		An int from the above enum.
*/
- (int)panelStyle;

/*!
	@method		setPanelStyle:
	@discussion Allows the style of the panel to change.
	@param		newStyle
				An element of the enum that the style is changing to.
*/
- (void) setPanelStyle:(int)newStyle;

/*!
	@method		orderFrontToGoal:
	@discussion	This is for showing the panel from a certain point, but staying
				within the bounds of the screen it's on.
	@param		goal
				A NSPoint for the position
	@param		parent
				The window that this panel is attached to
*/
- (void) orderFrontToGoal:(NSPoint)goal onWindow:(NSWindow *)parent;
 
@end

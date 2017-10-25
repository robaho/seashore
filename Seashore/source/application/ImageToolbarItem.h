#import "Globals.h"

/*!
	@class		ImageToolbarItem
	@abstract	A class to create simple image-based toolbar items.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> N/A
*/

@interface ImageToolbarItem : NSToolbarItem {

}

/*!
	@method		initWithIdentifier:label:image:toolTip:target:selector:
	@discussion	Initializes an instance of an NSToolbarItem that has all of the attributes of an image-based item built in.
	@param		itemIdent
				The identifier of the toolbar item.
	@param		label
				The label of the item for both the regular view and menu view.
	@param		image
				The name of the image that represents the item.
	@param		toolTip
				The tooltip for the item.
	@param		target
				The target of the toolbar item.
	@param		selector
				The selector used by the item.
	@result		Returns instance upon success.
*/
-(ImageToolbarItem *)initWithItemIdentifier:  (NSString*) itemIdent label:(NSString *) label image:(NSString *) image toolTip: (NSString *) toolTip target: (id) target selector: (SEL) selector;

@end

#import "ImageToolbarItem.h"

@implementation ImageToolbarItem

-(ImageToolbarItem *)initWithItemIdentifier:  (NSString*) itemIdent label:(NSString *) label image:(NSString *) image toolTip: (NSString *) toolTip target: (id) target selector: (SEL) selector
{
	self = [super initWithItemIdentifier: itemIdent];

	// Set the text label to be displayed in the toolbar and customization palette 
	[self setLabel: label];
	[self setPaletteLabel: label];

	// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
	[self setToolTip: toolTip];
	[self setImage: [NSImage imageNamed: image]];

	// Tell the item what message to send when it is clicked 
	[self setTarget: target];
	[self setAction: selector];	

	return self;
}

@end

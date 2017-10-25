#import "SeaToolbarItem.h"


@implementation SeaToolbarItem

- (void) validate
{
	// Views that use this function need to handle their own enable-ness.
	[super setEnabled: YES];
}

@end

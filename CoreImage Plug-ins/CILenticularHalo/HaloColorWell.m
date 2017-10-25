#import "HaloColorWell.h"
#import "CILenticularHaloClass.h"

@implementation HaloColorWell

- (void)activate:(BOOL)exclusive
{
	[super activate:exclusive];
	[gColorPanel setContinuous:NO];
	[gColorPanel setAction:NULL];
	[gColorPanel setTitle:@"Halo"];
}

- (void)setColor:(NSColor *)color
{
	[super setColor:color];
	[ciHalo setColor:color];
}

@end

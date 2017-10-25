#import "SunbeamsColorWell.h"
#import "CISunbeamsClass.h"

@implementation SunbeamsColorWell

- (void)activate:(BOOL)exclusive
{
	[super activate:exclusive];
	[gColorPanel setContinuous:NO];
	[gColorPanel setAction:NULL];
	[gColorPanel setTitle:@"Sunbeams"];
}

- (void)setColor:(NSColor *)color
{
	[super setColor:color];
	[ciSunbeams setColor:color];
}

@end

#import "SpotLightColorWell.h"
#import "CISpotLightClass.h"

@implementation SpotLightColorWell

- (void)activate:(BOOL)exclusive
{
	[super activate:exclusive];
	[gColorPanel setContinuous:NO];
	[gColorPanel setAction:NULL];
	[gColorPanel setTitle:@"Spotlight"];
}

- (void)setColor:(NSColor *)color
{
	[super setColor:color];
	[ciSpotLight setColor:color];
}

@end

#import "MonochromeColorWell.h"
#import "CIMonochromeClass.h"

@implementation MonochromeColorWell

- (void)activate:(BOOL)exclusive
{
	[super activate:true];
	[gColorPanel setContinuous:NO];
	[gColorPanel setAction:NULL];
	[gColorPanel setTitle:@"Monochrome"];
}

- (void)setColor:(NSColor *)color
{
	[super setColor:color];
	[ciMonochrome setColor:color];
}

@end

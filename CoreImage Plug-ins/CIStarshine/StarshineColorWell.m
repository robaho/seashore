#import "StarshineColorWell.h"
#import "CIStarshineClass.h"

@implementation StarshineColorWell

- (void)activate:(BOOL)exclusive
{
	[super activate:exclusive];
	[gColorPanel setContinuous:NO];
	[gColorPanel setAction:NULL];
	[gColorPanel setTitle:@"Starshine"];
}

- (void)setColor:(NSColor *)color
{
	[super setColor:color];
	[ciStarshine setColor:color];
}

@end

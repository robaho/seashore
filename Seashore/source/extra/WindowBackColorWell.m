#import "WindowBackColorWell.h"
#import "SeaPrefs.h"

@implementation WindowBackColorWell

- (void)activate:(BOOL)exclusive
{
	[super activate:exclusive];
	[gColorPanel setContinuous:NO];
	[gColorPanel setAction:NULL];
	[gColorPanel setTitle:LOCALSTR(@"window back", @"Window Frame")];
}

- (void)setInitialColor:(NSColor *)color
{
	[super setColor:color];
}

- (void)setColor:(NSColor *)color
{
//    if ([gColorPanel isVisible] && [[gColorPanel title] isEqualToString:LOCALSTR(@"window back", @"Window Frame")]) {
//        [super setColor:color];
//        [seaPrefs windowBackChanged:color];
//    }
}

@end

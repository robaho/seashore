#import "NSPreciseImageView.h"

@implementation NSPreciseImageView

- (void)drawRect:(NSRect)rect
{
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
	[super drawRect:rect];
}

@end

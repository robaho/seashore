#import <Cocoa/Cocoa.h>


@interface NSBezierPath(MyExtensions)
+ (NSBezierPath *)bezierPathWithRect:(NSRect) rect andRadius:(float) radius;
@end

void NSLogRect(NSRect rect);

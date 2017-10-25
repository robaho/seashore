#import "NSBezierPath_Extensions.h"

@implementation NSBezierPath (MyExtensions)

+ (NSBezierPath *)bezierPathWithRect:(NSRect) rect andRadius:(float) radius
{
	NSBezierPath *tempPath = [NSBezierPath bezierPath];
	float revCurveRadius, f;
	f = (4.0 / 3.0) * (sqrt(2) - 1);
	if (rect.size.width < 2 * radius) revCurveRadius = rect.size.width / 2.0;
	else if (rect.size.height < 2 * radius) revCurveRadius = rect.size.height / 2.0;
	else revCurveRadius = radius;
	
	[tempPath moveToPoint:NSMakePoint(rect.origin.x, rect.origin.y + revCurveRadius)];
	[tempPath curveToPoint:NSMakePoint(rect.origin.x + revCurveRadius, rect.origin.y) controlPoint1:NSMakePoint(rect.origin.x, rect.origin.y + (1.0 - f) * revCurveRadius) controlPoint2:NSMakePoint(rect.origin.x + (1.0 - f) * revCurveRadius, rect.origin.y)];
	[tempPath lineToPoint:NSMakePoint(rect.origin.x + rect.size.width - revCurveRadius, rect.origin.y)];
	[tempPath curveToPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + revCurveRadius) controlPoint1:NSMakePoint(rect.origin.x + rect.size.width - (1.0 - f) * revCurveRadius, rect.origin.y) controlPoint2:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + (1.0 - f) * revCurveRadius)];
	[tempPath lineToPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height - revCurveRadius)];
	[tempPath curveToPoint:NSMakePoint(rect.origin.x + rect.size.width - revCurveRadius, rect.origin.y + rect.size.height) controlPoint1:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height - (1.0 - f) * revCurveRadius) controlPoint2:NSMakePoint(rect.origin.x + rect.size.width - (1.0 - f) * revCurveRadius, rect.origin.y + rect.size.height)];
	[tempPath lineToPoint:NSMakePoint(rect.origin.x + revCurveRadius, rect.origin.y + rect.size.height)];
	[tempPath curveToPoint:NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height - revCurveRadius) controlPoint1:NSMakePoint(rect.origin.x + (1.0 - f) * revCurveRadius, rect.origin.y + rect.size.height) controlPoint2:NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height - (1.0 - f) * revCurveRadius)];
	[tempPath lineToPoint:NSMakePoint(rect.origin.x, rect.origin.y + revCurveRadius)];
	
	return tempPath;
}

@end

void NSLogRect(NSRect rect)
{
	NSLog(@"rect { size { %f, %f}, origin { %f, %f } }", rect.size.width, rect.size.height, rect.origin.x, rect.origin.y);
}

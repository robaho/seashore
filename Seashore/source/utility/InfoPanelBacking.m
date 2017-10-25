#import "InfoPanelBacking.h"
#import "InfoPanel.h"

@implementation InfoPanelBacking

- (void)drawRect:(NSRect)r
{
	// Get whether or not we have arrows
	BOOL side = NO, top = NO;
	int panelStyle = [(InfoPanel *)[self window] panelStyle];
	
	if(panelStyle == kVerticalPanelStyle){
		top = YES;
	}else if(panelStyle == kHorizontalPanelStyle){
		side = YES;
	}
	
	// Here's the background
	[[NSColor colorWithPatternImage: [NSImage imageNamed:@"info-win-backer"] ] set];
	NSRect rect = [self frame];
	
	// Make adjustments for the arrows
	if(side){
		rect.origin.x += 15;
		rect.size.width -= 15;
	}
	
	if(top){
		rect.size.height -= 15;
	}
		
	// Hard code the rounded-rectangular nature
	float radius = 4.0;
	NSBezierPath *tempPath = [NSBezierPath bezierPath];
	float revCurveRadius, f;
	f = (4.0 / 3.0) * (sqrt(2) - 1);
	if (rect.size.width < 2 * radius) revCurveRadius = rect.size.width / 2.0;
	else if (rect.size.height < 2 * radius) revCurveRadius = rect.size.height / 2.0;
	else revCurveRadius = radius;
	
	// Start drawing the sides (and corners)
	[tempPath moveToPoint:NSMakePoint(rect.origin.x, rect.origin.y + revCurveRadius)];
	[tempPath curveToPoint:NSMakePoint(rect.origin.x + revCurveRadius, rect.origin.y) controlPoint1:NSMakePoint(rect.origin.x, rect.origin.y + (1.0 - f) * revCurveRadius) controlPoint2:NSMakePoint(rect.origin.x + (1.0 - f) * revCurveRadius, rect.origin.y)];
	[tempPath lineToPoint:NSMakePoint(rect.origin.x + rect.size.width - revCurveRadius, rect.origin.y)];
	[tempPath curveToPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + revCurveRadius) controlPoint1:NSMakePoint(rect.origin.x + rect.size.width - (1.0 - f) * revCurveRadius, rect.origin.y) controlPoint2:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + (1.0 - f) * revCurveRadius)];
	[tempPath lineToPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height - revCurveRadius)];
	[tempPath curveToPoint:NSMakePoint(rect.origin.x + rect.size.width - revCurveRadius, rect.origin.y + rect.size.height) controlPoint1:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height - (1.0 - f) * revCurveRadius) controlPoint2:NSMakePoint(rect.origin.x + rect.size.width - (1.0 - f) * revCurveRadius, rect.origin.y + rect.size.height)];
	
	// We're now on the top side so draw the arrow
	if(top){
		[tempPath lineToPoint:NSMakePoint(rect.origin.x + rect.size.width / 2 + 10, rect.origin.y + rect.size.height )];
		[tempPath lineToPoint:NSMakePoint(rect.origin.x + rect.size.width / 2 , rect.origin.y + rect.size.height + 15)];
		[tempPath lineToPoint:NSMakePoint(rect.origin.x + rect.size.width / 2 - 10, rect.origin.y + rect.size.height )];
	}

	// Finish this side
	[tempPath lineToPoint:NSMakePoint(rect.origin.x + revCurveRadius, rect.origin.y + rect.size.height)];

	[tempPath curveToPoint:NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height - revCurveRadius) controlPoint1:NSMakePoint(rect.origin.x + (1.0 - f) * revCurveRadius, rect.origin.y + rect.size.height) controlPoint2:NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height - (1.0 - f) * revCurveRadius)];
	
	// We're now on the left side, so draw that arrow.
	if(side){
		[tempPath lineToPoint:NSMakePoint(rect.origin.x, rect.origin.y + 2 * rect.size.height / 3 + 10)];
		[tempPath lineToPoint:NSMakePoint(rect.origin.x - 15, rect.origin.y + 2 * rect.size.height / 3)];
		[tempPath lineToPoint:NSMakePoint(rect.origin.x, rect.origin.y + 2 * rect.size.height / 3 - 10)];
	}
	
	[tempPath lineToPoint:NSMakePoint(rect.origin.x, rect.origin.y + revCurveRadius)];

	// Fill the path.
	[tempPath fill];
}



@end

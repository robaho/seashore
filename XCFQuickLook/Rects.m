#import "Rects.h"
#import "Globals.h"

 IntPoint NSPointMakeIntPoint(NSPoint point)
{
	IntPoint newPoint;
	
	newPoint.x = floorf(point.x);
	newPoint.y = floorf(point.y);
	
	return newPoint; 
}

 IntSize NSSizeMakeIntSize(NSSize size)
{
	IntSize newSize;
	
	newSize.width = ceilf(size.width);
	newSize.height = ceilf(size.height);
	
	return newSize;
}

 NSPoint IntPointMakeNSPoint(IntPoint point)
{
	NSPoint newPoint;
	
	newPoint.x = point.x;
	newPoint.y = point.y;
	
	return newPoint;
}

 IntPoint IntMakePoint(int x, int y)
{
	IntPoint newPoint;
	
	newPoint.x = x;
	newPoint.y = y;
	
	return newPoint;
}

 NSSize IntSizeMakeNSSize(IntSize size)
{
	NSSize newSize;
	
	newSize.width = size.width;
	newSize.height = size.height;
	
	return newSize;
}

 IntSize IntMakeSize(int width, int height)
{
	IntSize newSize;
	
	newSize.width = width;
	newSize.height = height;
	
	return newSize;
}

 IntRect IntMakeRect(int x, int y, int width, int height)
{
	IntRect newRect;
	
	newRect.origin.x = x;
	newRect.origin.y = y;
	newRect.size.width = width;
	newRect.size.height = height;
	
	return newRect;
}

 void IntOffsetRect(IntRect *rect, int x, int y)
{
	rect->origin.x += x;
	rect->origin.y += y;
}

 BOOL IntPointInRect(IntPoint point, IntRect rect)
{
	if (point.x < rect.origin.x) return NO;
	if (point.x >= rect.origin.x + rect.size.width) return NO;
	if (point.y < rect.origin.y) return NO;
	if (point.y >= rect.origin.y + rect.size.height) return NO;
	
	return YES;
}

 BOOL IntContainsRect(IntRect bigRect, IntRect littleRect)
{
	if (littleRect.origin.x < bigRect.origin.x) return NO;
	if (littleRect.origin.x + littleRect.size.width > bigRect.origin.x + bigRect.size.width) return NO;
	if (littleRect.origin.y < bigRect.origin.y) return NO;
	if (littleRect.origin.y + littleRect.size.height > bigRect.origin.y + bigRect.size.height) return NO;
	
	return YES;
}

 IntRect IntConstrainRect(IntRect littleRect, IntRect bigRect)
{
	IntRect rect = littleRect;
	
	if (littleRect.origin.x < bigRect.origin.x) { rect.origin.x = bigRect.origin.x; rect.size.width = littleRect.size.width - (bigRect.origin.x - littleRect.origin.x); }
	else { rect.origin.x = littleRect.origin.x; rect.size.width = littleRect.size.width; }
	if (rect.origin.x + rect.size.width > bigRect.origin.x + bigRect.size.width) { rect.size.width = (bigRect.origin.x + bigRect.size.width) - rect.origin.x; }
	if (rect.size.width < 0) rect.size.width = 0;
	
	if (littleRect.origin.y < bigRect.origin.y) { rect.origin.y = bigRect.origin.y; rect.size.height = littleRect.size.height - (bigRect.origin.y - littleRect.origin.y); }
	else { rect.origin.y = littleRect.origin.y; rect.size.height = littleRect.size.height; }
	if (rect.origin.y + rect.size.height > bigRect.origin.y + bigRect.size.height) { rect.size.height = (bigRect.origin.y + bigRect.size.height) - rect.origin.y; }
	if (rect.size.height < 0) rect.size.height = 0;
	
	return rect;
}

 NSRect NSConstrainRect(NSRect littleRect, NSRect bigRect)
{
	NSRect rect = littleRect;
	
	if (littleRect.origin.x < bigRect.origin.x) { rect.origin.x = bigRect.origin.x; rect.size.width = littleRect.size.width - (bigRect.origin.x - littleRect.origin.x); }
	else { rect.origin.x = littleRect.origin.x; rect.size.width = littleRect.size.width; }
	if (rect.origin.x + rect.size.width > bigRect.origin.x + bigRect.size.width) { rect.size.width = (bigRect.origin.x + bigRect.size.width) - rect.origin.x; }
	if (rect.size.width < 0) rect.size.width = 0;
	
	if (littleRect.origin.y < bigRect.origin.y) { rect.origin.y = bigRect.origin.y; rect.size.height = littleRect.size.height - (bigRect.origin.y - littleRect.origin.y); }
	else { rect.origin.y = littleRect.origin.y; rect.size.height = littleRect.size.height; }
	if (rect.origin.y + rect.size.height > bigRect.origin.y + bigRect.size.height) { rect.size.height = (bigRect.origin.y + bigRect.size.height) - rect.origin.y; }
	if (rect.size.height < 0) rect.size.height = 0;
	
	return rect;
}

 IntRect IntSumRects(IntRect augendRect, IntRect addendRect)
{
	// If either of the rects are zero
	if(augendRect.size.width <= 0 || augendRect.size.height <= 0)
		return addendRect;
	
	if(addendRect.size.width <= 0 || addendRect.size.width <= 0)
		return augendRect;
	
	IntRect rect;
	// Use the smallest origin
	rect.origin.x = augendRect.origin.x < addendRect.origin.x ? augendRect.origin.x : addendRect.origin.x;
	rect.origin.y = augendRect.origin.y < addendRect.origin.y ? augendRect.origin.y : addendRect.origin.y;

	// Find the width
	if(augendRect.origin.x + augendRect.size.width > addendRect.origin.x + addendRect.size.width){
		rect.size.width = augendRect.origin.x + augendRect.size.width - rect.origin.x;
	}else{
		rect.size.width = addendRect.origin.x + addendRect.size.width - rect.origin.x;	
	}
	
	//Find the height
	if(augendRect.origin.y + augendRect.size.height > addendRect.origin.y + addendRect.size.height){
		rect.size.height = augendRect.origin.y + augendRect.size.height - rect.origin.y;
	}else{
		rect.size.height = addendRect.origin.y + addendRect.size.height - rect.origin.y;	
	}
	
	return rect;
}

 IntRect NSRectMakeIntRect(NSRect rect)
{
	IntRect newRect;
	
	newRect.origin = NSPointMakeIntPoint(rect.origin);
	newRect.size = NSSizeMakeIntSize(rect.size);
	
	return newRect;
}

 NSRect IntRectMakeNSRect(IntRect rect)
{
	NSRect newRect;
	
	newRect.origin = IntPointMakeNSPoint(rect.origin);
	newRect.size = IntSizeMakeNSSize(rect.size);
	
	return newRect;
}

 NSPoint NSPointRotateNSPoint (NSPoint initialPoint, NSPoint centerPoint, float radians)
{
	if(radians == 0.0)
		return initialPoint;
	initialPoint.x -= centerPoint.x;
	initialPoint.y -= centerPoint.y;
	float dist = sqrt(sqr(initialPoint.x) + sqr(initialPoint.y));
	float angle = atan(initialPoint.y / initialPoint.x);
	angle += radians;
	NSPoint result;
	result.x = dist * cos(angle);
	result.y = dist * sin(angle);
	if(initialPoint.x < 0){
		result.x *= -1;
		result.y *= -1;
	}
	result.x += centerPoint.x;
	result.y += centerPoint.y;
	return result;
}


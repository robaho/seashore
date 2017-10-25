#import "Rects.h"

inline IntPoint NSPointMakeIntPoint(NSPoint point)
{
	IntPoint newPoint;
	
	newPoint.x = floorf(point.x);
	newPoint.y = floorf(point.y);
	
	return newPoint; 
}

inline IntSize NSSizeMakeIntSize(NSSize size)
{
	IntSize newSize;
	
	newSize.width = ceilf(size.width);
	newSize.height = ceilf(size.height);
	
	return newSize;
}

inline NSPoint IntPointMakeNSPoint(IntPoint point)
{
	NSPoint newPoint;
	
	newPoint.x = point.x;
	newPoint.y = point.y;
	
	return newPoint;
}

inline IntPoint IntMakePoint(int x, int y)
{
	IntPoint newPoint;
	
	newPoint.x = x;
	newPoint.y = y;
	
	return newPoint;
}

inline NSSize IntSizeMakeNSSize(IntSize size)
{
	NSSize newSize;
	
	newSize.width = size.width;
	newSize.height = size.height;
	
	return newSize;
}

inline IntSize IntMakeSize(int width, int height)
{
	IntSize newSize;
	
	newSize.width = width;
	newSize.height = height;
	
	return newSize;
}

inline IntRect IntMakeRect(int x, int y, int width, int height)
{
	IntRect newRect;
	
	newRect.origin.x = x;
	newRect.origin.y = y;
	newRect.size.width = width;
	newRect.size.height = height;
	
	return newRect;
}

inline void IntOffsetRect(IntRect *rect, int x, int y)
{
	rect->origin.x += x;
	rect->origin.y += y;
}

inline BOOL IntPointInRect(IntPoint point, IntRect rect)
{
	if (point.x < rect.origin.x) return NO;
	if (point.x >= rect.origin.x + rect.size.width) return NO;
	if (point.y < rect.origin.y) return NO;
	if (point.y >= rect.origin.y + rect.size.height) return NO;
	
	return YES;
}

inline BOOL IntContainsRect(IntRect bigRect, IntRect littleRect)
{
	if (littleRect.origin.x < bigRect.origin.x) return NO;
	if (littleRect.origin.x + littleRect.size.width > bigRect.origin.x + bigRect.size.width) return NO;
	if (littleRect.origin.y < bigRect.origin.y) return NO;
	if (littleRect.origin.y + littleRect.size.height > bigRect.origin.y + bigRect.size.height) return NO;
	
	return YES;
}

inline IntRect IntConstrainRect(IntRect littleRect, IntRect bigRect)
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

inline IntRect NSRectMakeIntRect(NSRect rect)
{
	IntRect newRect;
	
	newRect.origin = NSPointMakeIntPoint(rect.origin);
	newRect.size = NSSizeMakeIntSize(rect.size);
	
	return newRect;
}

inline NSRect IntRectMakeNSRect(IntRect rect)
{
	NSRect newRect;
	
	newRect.origin = IntPointMakeNSPoint(rect.origin);
	newRect.size = IntSizeMakeNSSize(rect.size);
	
	return newRect;
}



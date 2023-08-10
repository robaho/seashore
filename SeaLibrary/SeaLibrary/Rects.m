#import "Rects.h"
#import "Globals.h"

IntRect IntZeroRect = {{0,0},{0,0}};

NSControlSize defaultControlSize = NSControlSizeMini;

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

inline IntRect IntOffsetRect(IntRect rect, int x, int y)
{
    return IntMakeRect(rect.origin.x+x,rect.origin.y+y,rect.size.width,rect.size.height);
}

inline IntRect IntGrowRect(IntRect rect, int distance)
{
    return IntMakeRect(rect.origin.x-distance,rect.origin.y-distance,rect.size.width+distance*2,rect.size.height+distance*2);
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
    rect.origin.x = MIN(rect.origin.x,bigRect.origin.x+bigRect.size.width);
	if (rect.origin.x + rect.size.width > bigRect.origin.x + bigRect.size.width) { rect.size.width = (bigRect.origin.x + bigRect.size.width) - rect.origin.x; }
	if (rect.size.width < 0) rect.size.width = 0;
	
	if (littleRect.origin.y < bigRect.origin.y) { rect.origin.y = bigRect.origin.y; rect.size.height = littleRect.size.height - (bigRect.origin.y - littleRect.origin.y); }
	else { rect.origin.y = littleRect.origin.y; rect.size.height = littleRect.size.height; }
    rect.origin.y = MIN(rect.origin.y,bigRect.origin.y+bigRect.size.height);
	if (rect.origin.y + rect.size.height > bigRect.origin.y + bigRect.size.height) { rect.size.height = (bigRect.origin.y + bigRect.size.height) - rect.origin.y; }
	if (rect.size.height < 0) rect.size.height = 0;

    if(rect.size.width==0 || rect.size.height==0){
        rect.size.width = rect.size.height = 0;
    }
	
	return rect;
}

inline NSRect NSConstrainRect(NSRect littleRect, NSRect bigRect)
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

inline IntRect IntRectNormalize(IntRect r)
{
    if(r.size.width<0) {
        r.origin.x += r.size.width;
        r.size.width = ABS(r.size.width);
    }
    if(r.size.height<0) {
        r.origin.y += r.size.height;
        r.size.height = ABS(r.size.height);
    }
    return r;
}

inline IntRect IntSumRects(IntRect augendRect, IntRect addendRect)
{
    augendRect = IntRectNormalize(augendRect);
    addendRect = IntRectNormalize(addendRect);
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

inline NSPoint NSPointRotateNSPoint (NSPoint initialPoint, NSPoint centerPoint, float radians)
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


inline NSString* NSStringFromIntRect(IntRect rect)
{
    return [NSString stringWithFormat:@"%d,%d,%d,%d",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height];
}

inline NSString* NSStringFromIntPoint(IntPoint p)
{
    return [NSString stringWithFormat:@"%d,%d",p.x,p.y];
}

inline NSRect NSGrowRect(NSRect rect,float size){
    return NSMakeRect(rect.origin.x-(size/2),rect.origin.y-(size/2),rect.size.width+size,rect.size.height+size);
}

inline NSRect NSEmptyRect(NSPoint origin){
    return NSMakeRect(origin.x,origin.y,0,0);
}

inline IntRect IntEmptyRect(IntPoint origin){
    return IntMakeRect(origin.x,origin.y,0,0);
}
inline IntPoint IntOffsetPoint(IntPoint p,int xoff,int yoff) {
    return IntMakePoint(p.x+xoff,p.y+yoff);
}

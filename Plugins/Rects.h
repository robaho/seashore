/*!
	@header		Rects
	@abstract	Adds support for integer versions of NSRect, NSSize,  and
				NSPoint (called IntRect, IntSize and IntPoint).
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2004<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>

#ifndef INTRECT_T
#define INTRECT_T

/*!
	@typedef	IntPoint
	@discussion	Similar to NSPoint except with integer fields.
	@field		x
				The x co-ordinate of the point.
	@field		y
				The y co-ordinate of the point.
*/
typedef struct { int x; int y; } IntPoint;

/*!
	@typedef	IntSize
	@discussion	Similar to NSSize except with integer fields.
	@field		width
				The width of the size.
	@field		height
				The height of the size.
*/
typedef struct { int width; int height; } IntSize;

/*!
	@typedef	IntRect
	@discussion	Similar to NSRect except with integer fields.
	@field		origin
				An IntPoint representing the origin of the rectangle.
	@field		size
				An IntSize representing the size of the rectangle.
*/
typedef struct { IntPoint origin; IntSize size; } IntRect;

#endif /* INTRECT_T */

/*!
	@function	NSPointMakeIntPoint
	@discussion	Given an NSPoint makes an IntPoint with similar values fields
				are rounded down if necessary).
	@param		point
				The NSPoint to convert.
	@result		Returns an IntPoint with similar values to the NSPoint.
*/
inline IntPoint NSPointMakeIntPoint(NSPoint point);

/*!
	@function	NSSizeMakeIntSize
	@discussion	Given an NSSize makes an IntSize with similar values fields are
				rounded up if necessary).
	@param		size
				The NSSize to convert.
	@result		Returns an IntSize with similar values to the NSSize.
*/
inline IntSize NSSizeMakeIntSize(NSSize size);

/*!
	@function	IntPointMakeNSPoint
	@discussion	Given an IntPoint makes an NSPoint with similar values.
	@param		point
				The IntPoint to convert.
	@result		Returns a NSPoint with similar values to the IntPoint.
*/
inline NSPoint IntPointMakeNSPoint(IntPoint point);

/*!
	@function	IntSizeMakeNSSize
	@discussion	Given an IntSize makes an NSSize with similar values.
	@param		size
				The IntSize to convert.
	@result		Returns a NSSize with similar values to the IntSize.
*/
inline NSSize IntSizeMakeNSSize(IntSize size);

/*!
	@function	IntMakePoint
	@discussion	Given a set of integer co-ordinates makes an IntPoint.
	@param		x
				The x co-ordinate of the new point.
	@param		y
				The y co-ordinate of the new point.
	@result		Returns an IntPoint with the given co-ordinates.
*/
inline IntPoint IntMakePoint(int x, int y);

/*!
	@function	IntMakePoint
	@discussion	Given a set of integer values makes an IntSize.
	@param		width
				The width of the new size.
	@param		height
				The height of the new size.
	@result		Returns an IntSize with the given values.
*/
inline IntSize IntMakeSize(int width, int height);

/*!
	@function	IntMakeRect
	@discussion	Given a set of integer values makes an IntRect.
	@param		x
				The x co-ordinate of the origin of the new rectangle.
	@param		y
				The y co-ordinate of the origin of the new rectangle.
	@param		width
				The width of the new rectangle.
	@param		height
				The height of the new rectangle.
	@result		Returns an IntRect with the given values.
*/
inline IntRect IntMakeRect(int x, int y, int width, int height);

/*!
	@function	IntOffsetRect
	@discussion	Given a reference to a rectangle offsets it by the specified
				co-ordinates.
	@param		rect
				A reference to the rectangle to be offset.
	@param		x
				The amount by which to offset the x co-ordinates.
	@param		y
				The amount by which to offset the y co-ordinates.
*/
inline void IntOffsetRect(IntRect *rect, int x, int y);

/*!
	@function	IntPointInRect
	@discussion	Given an IntRect tests to see if a given IntPoint lies within
				it. This function assumes a flipped co-ordinate system like that
				used by QuickDraw or NSPointInRect.
	@param		point
				The point to be tested.
	@param		rect
				The rectangle in which to test for the point.
	@result		YES if the point lies within the rectangle, NO otherwise.
*/
inline BOOL IntPointInRect(IntPoint point, IntRect rect);

/*!
	@function	IntContainsRect
	@discussion	Given an IntRect tests to see if it entirely contains another
				IntRect.
	@param		bigRect
				The IntRect in which the littleRect must be contained if
				function is to return YES.
	@param		littleRect
				The IntRect with which to test the above condition.
	@result		Returns YES if the bigRect entirely contains the littleRect, NO
				otherwise.
*/
inline BOOL IntContainsRect(IntRect bigRect, IntRect littleRect);

/*!
	@function	IntConstrainRect
	@discussion	Given an IntRect makes sure it lies within another IntRect.
	@param		littleRect
				The IntRect to be constrained to the bigRect.
	@param		bigRect
				The IntRect within which the constrained rectangle must lie.
	@result		Returns an IntRect that is the littleRect constrained to the
				bigRect.
*/
inline IntRect IntConstrainRect(IntRect littleRect, IntRect bigRect);

/*!
	@function	NSRectMakeIntRect
	@discussion	Given an NSRect makes an IntRect with similar values,  the
				IntRect will always exceed the NSRect in size.
	@param		rect
				The NSRect to convert.
	@result		Returns an IntRect at least the size of NSRect.
*/
inline IntRect NSRectMakeIntRect(NSRect rect);

/*!
	@function	IntRectMakeNSRect
	@discussion	Given an IntRect makes an NSRect with similar values.
	@param		rect
				The IntRect to convert.
	@result		Returns an NSRect with similar values to the NSRect.
*/
inline NSRect IntRectMakeNSRect(IntRect rect);


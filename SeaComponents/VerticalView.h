//
//  shows subview in vertical fit width panel

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface VerticalView : NSView

@property bool lastFills;
@property CGFloat preferredMaxLayoutWidth;

+ (VerticalView*)view;
- (void)addSubviews:(NSView*)view, ...;
- (void)addSubviewsAtIndex:(int)index views:(NSView*)view, ...;
- (void)setLastFills:(bool)lastFills;
@end

NS_ASSUME_NONNULL_END

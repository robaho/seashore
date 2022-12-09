//
//  shows subview in vertical fit width panel

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

IB_DESIGNABLE
@interface VerticalView : NSView

@property (nonatomic) IBInspectable bool lastFills;
@property IBInspectable float margin;
@property IBInspectable float gap;

@property CGFloat preferredMaxLayoutWidth;

+ (VerticalView*)view;
- (void)addSubviews:(NSView*)view, ...;
- (void)addSubviewsAtIndex:(int)index views:(NSView*)view, ...;
@end

NS_ASSUME_NONNULL_END

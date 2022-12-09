
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

IB_DESIGNABLE
@interface BorderView : NSView
{
    float top_height; // captures the original size
    float bottom_height; // captures the original size
    float left_width; // captures the original size
    float right_width; // captures the original size
}
@property IBInspectable float outerInset;
@property IBInspectable float innerInset;
@property CGFloat preferredMaxLayoutWidth;
@property IBOutlet NSView* top;
@property IBOutlet NSView* middle;
@property IBOutlet NSView* bottom;
@property IBOutlet NSView* left;
@property IBOutlet NSView* right;
+(BorderView*)view;
@end

NS_ASSUME_NONNULL_END


#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface BorderView : NSView
{
    float top_height; // captures the original size
    float bottom_height; // captures the original size
}
@property int borderMargin;
@property IBOutlet NSView* top;
@property IBOutlet NSView* middle;
@property IBOutlet NSView* bottom;
@end

NS_ASSUME_NONNULL_END

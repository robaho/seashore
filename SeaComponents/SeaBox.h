#import <Cocoa/Cocoa.h>
#import <SeaComponents/Label.h>

NS_ASSUME_NONNULL_BEGIN

@interface SeaBox : NSBox
{
    NSSize initialSize;
    NSRect myBorderRect;
    Label *label;
}
@end

NS_ASSUME_NONNULL_END

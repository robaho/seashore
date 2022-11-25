#import <Cocoa/Cocoa.h>
#import <SeaComponents/SeaComponents.h>

NS_ASSUME_NONNULL_BEGIN

@interface SeaColorWell : NSView
{
    NSColorWell *colorWell;
    Label *title;
    id<Listener> listener;
    int format;
    bool compact;
}

- (void)setColorValue:(NSColor*)value;
- (NSColor*)colorValue;

+ (SeaColorWell*)colorWellWithTitle:(NSString*)title Listener:(id<Listener>)listener;
+ (SeaColorWell*)compactWithTitle:(NSString*)title Listener:(id<Listener>)listener;

@end

NS_ASSUME_NONNULL_END

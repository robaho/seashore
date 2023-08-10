#import <Cocoa/Cocoa.h>
#import <SeaComponents/SeaComponents.h>

NS_ASSUME_NONNULL_BEGIN

@interface SeaColorWell : NSView
{
    NSColorWell *colorWell;
    Label *title;
    __weak id<Listener> listener;
    bool compact;
}

- (void)setColorValue:(NSColor*)value;
- (NSColor*)colorValue;
- (void)disableColorWell;

+ (SeaColorWell*)colorWellWithTitle:(NSString*)title Listener:(nullable id<Listener>)listener Size:(NSControlSize)size;
+ (SeaColorWell*)compactWithTitle:(NSString*)title Listener:(nullable id<Listener>)listener Size:(NSControlSize)size;

@end

@interface MinimalColorWell : NSColorWell
@end



NS_ASSUME_NONNULL_END

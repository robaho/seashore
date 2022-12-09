#import <Cocoa/Cocoa.h>
#import <SeaComponents/SeaComponents.h>

NS_ASSUME_NONNULL_BEGIN

@interface SeaColorWell : NSView
{
    NSColorWell *colorWell;
    Label *title;
    id<Listener> listener;
    bool compact;
}

- (void)setColorValue:(NSColor*)value;
- (NSColor*)colorValue;
- (void)disableColorWell;

+ (SeaColorWell*)colorWellWithTitle:(NSString*)title Listener:(nullable id<Listener>)listener;
+ (SeaColorWell*)compactWithTitle:(NSString*)title Listener:(nullable id<Listener>)listener;

@end

@interface MinimalColorWell : NSColorWell
@end



NS_ASSUME_NONNULL_END

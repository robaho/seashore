#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class SeaDocument;

@interface SeaBackground : NSView
{
    __weak SeaDocument *document;
    NSImage *checkerboard;
}

- (SeaBackground*)initWithDocument:(SeaDocument*)document;

@end

NS_ASSUME_NONNULL_END

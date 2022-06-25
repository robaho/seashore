#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class SeaDocument;

@interface SeaExtrasView : NSView
{
    __weak SeaDocument *document;

    int selectionPhase;
}

- (SeaExtrasView*)initWithDocument:(SeaDocument*)document;

@end

NS_ASSUME_NONNULL_END

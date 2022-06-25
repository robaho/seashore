#import "AbstractTool.h"
#import "ZoomOptions.h"
#import "AbstractSelectTool.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZoomTool : AbstractSelectTool
{
    ZoomOptions *options;
}

- (IntRect)selectionRect;

@end

NS_ASSUME_NONNULL_END

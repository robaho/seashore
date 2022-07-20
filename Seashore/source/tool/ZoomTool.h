#import "AbstractTool.h"
#import "ZoomOptions.h"
#import "AbstractSelectTool.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZoomTool : AbstractScaleTool
{
    ZoomOptions *options;
}

- (IntRect)zoomRect;

@end

NS_ASSUME_NONNULL_END

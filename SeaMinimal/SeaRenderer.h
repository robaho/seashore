#import <Foundation/Foundation.h>

#include "SeaContent.h"

NS_ASSUME_NONNULL_BEGIN

@interface SeaRenderer : NSObject

- (CGImageRef) render:(SeaContent*)content;
@end

NS_ASSUME_NONNULL_END

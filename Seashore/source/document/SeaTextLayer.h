//
//  SeaTextLayer.h
//  Seashore
//
//  Created by robert engels on 7/23/22.
//

#import "SeaLayer.h"
#import "ParasiteData.h"

NS_ASSUME_NONNULL_BEGIN

@interface TextProperties : NSObject <NSCopying>
@property NSString *text;
@property NSColor *color;
@property NSFont *font;
@property NSBezierPath * _Nullable textPath;
@property int outline;
@property float lineSpacing;
@property int alignment;
@property float verticalMargin;

- (BOOL)isEqualToProperties:(TextProperties*)props;
@end

@interface SeaTextLayer : SeaLayer
{
    bool rasterized;
}

@property TextProperties* properties;

- (SeaTextLayer*)initWithDocument:(SeaDocument*)document layer:(SeaLayer*)layer properties:(TextProperties*)props;
- (void)setBounds:(IntRect)bounds;
- (void)updateBitmap;

@end

NS_ASSUME_NONNULL_END

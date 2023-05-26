//
//  AbstractTool+FillExtensions.h
//  Seashore
//
//  Created by robert engels on 5/25/23.
//

#import "AbstractTool.h"
#import "Bucket.h"

NS_ASSUME_NONNULL_BEGIN

@interface AbstractTool (FillExtensions)

- (void)calculateSeeds:(fillContext*)ctx at:(IntPoint)at;
-(IntRect)fillOverlay:(IntPoint)start color:(unsigned char*)color tolerance:(int)tolerance allRegions:(bool)allRegions op:(NSOperation*)op;

@end

NS_ASSUME_NONNULL_END

//
//  DebugView.h
//  Seashore
//
//  Created by robert engels on 12/26/21.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface DebugView : NSImageView

@property NSBitmapImageRep *rep;

+(DebugView *)createWithRep:(NSBitmapImageRep *)rep;
+(DebugView *)createWithData:(unsigned char *)data width:(int)width height:(int)height snapshot:(BOOL)snapshot;
+(DebugView *)createWithContext:(CGContextRef)ctx;

@end

NS_ASSUME_NONNULL_END

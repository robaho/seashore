//
//  DebugView.h
//  Seashore
//
//  Created by robert engels on 12/26/21.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface DebugView : NSView

@property NSBitmapImageRep *rep;

+(DebugView *)createWithRep:(NSBitmapImageRep *)rep;
+(DebugView *)createWithData:(unsigned char *)data width:(int)width height:(int)height spp:(int)spp snapshot:(BOOL)snapshot;

-(void)update;

@end

NS_ASSUME_NONNULL_END

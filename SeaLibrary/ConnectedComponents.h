//
//  ConnectComponents.h
//  Seashore
//
//  Created by robert engels on 2/20/22.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Comp;

@interface ConnectedComponents : NSObject
{
    NSMutableDictionary<NSNumber*,Comp*> *hash;
    NSMutableArray<Comp*> *components;
    NSMutableArray<NSNumber*> *unused;
    NSMutableArray *closed;
    NSMutableSet *active;
}

+ (CGPathRef)getPaths:(unsigned char *)image width:(int)width height:(int)height;
@end

NS_ASSUME_NONNULL_END

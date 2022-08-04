//
//  XCFTextLayerSupport.h
//  Seashore
//
//  Created by robert engels on 7/30/22.
//

#import <Foundation/Foundation.h>
#import "XCFLayer.h"
#import "SeaTextLayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface XCFTextLayerSupport : NSObject

+(TextProperties*)properties:(XCFLayer*)layer;
+(Parasite)toParasite:(SeaTextLayer*)layer properties:(TextProperties*)properties;

@end

NS_ASSUME_NONNULL_END

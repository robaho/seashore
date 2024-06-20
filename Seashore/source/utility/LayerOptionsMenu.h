//
//  LayerOptionsMenu.h
//  Seashore
//
//  Created by robert engels on 2/23/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LayerOptionsMenu : NSMenu

@end

typedef struct {
    NSString *title;
    int tag;
} BlendMenuItem;

extern BlendMenuItem blendMenu[];
extern int blendMenuCount();

NS_ASSUME_NONNULL_END

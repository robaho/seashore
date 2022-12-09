//
//  SeaSizes.h
//  SeaComponents
//
//  Created by robert engels on 12/1/22.
//
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSControl(MyExtensions)
- (void)setCtrlSize:(NSControlSize)size API_AVAILABLE(macosx(10.9));
- (NSControlSize)ctrlSize API_AVAILABLE(macosx(10.9));
@end

@interface SeaSizes : NSObject
+(float)heightOf:(NSControl*)control;
@end


NS_ASSUME_NONNULL_END

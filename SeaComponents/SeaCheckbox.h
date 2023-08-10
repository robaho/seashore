//
//  SeaCheck.h
//  SeaComponents
//
//  Created by robert engels on 11/21/22.
//

#import <Cocoa/Cocoa.h>
#import <SeaComponents/Listener.h>

NS_ASSUME_NONNULL_BEGIN

@interface SeaCheckbox : NSView
{
    NSButton *checkbox;
    __weak id<Listener> listener;
}

- (bool)isChecked;
- (void)setChecked:(bool)b;

+ (SeaCheckbox*)checkboxWithTitle:(NSString*)title Listener:(nullable id<Listener>)listener;
+ (SeaCheckbox*)checkboxWithTitle:(NSString*)title Listener:(nullable id<Listener>)listener Size:(NSControlSize)size;

@end
NS_ASSUME_NONNULL_END

//
//  SeaSlider.h
//  Seashore
//
//  Created by robert engels on 3/6/22.
//

#import <Cocoa/Cocoa.h>
#import <SeaComponents/Label.h>
#import <SeaComponents/Listener.h>

NS_ASSUME_NONNULL_BEGIN

@interface SeaPopup : NSView
{
    NSPopUpButton *popup;
    NSButton *checkbox;
    Label *title;
    __weak id<Listener> listener;
    bool compact;
    bool checkable;
}

- (NSInteger)indexOfSelectedItem;
- (NSInteger)indexOfItemWithTag:(NSInteger)tag;
- (NSMenuItem*)selectedItem;

- (bool)isChecked;
- (void)setChecked:(bool)b;
- (void)selectItemAtIndex:(NSInteger)index;
- (nullable NSMenuItem*)itemAtIndex:(NSInteger)index;

+ (SeaPopup*)popupWithTitle:(NSString*)title Menu:(NSMenu*)menu Listener:(nullable id<Listener>)listener;
+ (SeaPopup*)popupWithCheck:(NSString*)title Menu:(NSMenu*)menu Listener:(nullable id<Listener>)listener;
+ (SeaPopup*)compactWithTitle:(NSString*)title Menu:(NSMenu*)menu Listener:(nullable id<Listener>)listener;

@end


NS_ASSUME_NONNULL_END

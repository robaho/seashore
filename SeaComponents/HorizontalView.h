//
//  HorizontalView.h
//  SeaComponents
//
//  Created by robert engels on 11/25/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/** lays out subview horizontal in container based on number of visble views*/
IB_DESIGNABLE @interface HorizontalView : NSView

@property IBInspectable float margin;
@property IBInspectable float gap;
@property IBInspectable BOOL leftJustify;
@end


NS_ASSUME_NONNULL_END

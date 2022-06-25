//
//  SizeableView.h
//  SeaComponents
//
//  Created by robert engels on 3/7/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SizeableView : NSView
{
    NSSize contentSize;
}

- (void)setIntrinsicContentSize:(NSSize)size;

@end

NS_ASSUME_NONNULL_END

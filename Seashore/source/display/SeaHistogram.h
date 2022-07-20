//
//  SeaHistogram.h
//  Seashore
//
//  Created by robert engels on 7/5/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SeaHistogram : NSView
{
    __weak IBOutlet id document;
    IBOutlet id modeComboBox;
    IBOutlet id histogramView;
}
- (IBAction)modeChanged:(id)sender;

- (void)update;

@end

NS_ASSUME_NONNULL_END

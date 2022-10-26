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
    __weak IBOutlet NSPopUpButton *modeComboBox;
    IBOutlet id histogramView;
    __weak IBOutlet NSPopUpButton *sourceComboBox;
}
- (IBAction)optionsChanged:(id)sender;

- (void)update;
- (void)shutdown;

@end

NS_ASSUME_NONNULL_END

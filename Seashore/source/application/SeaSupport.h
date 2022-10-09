//
//  SeaSupport.h
//  Seashore
//
//  Created by robert engels on 6/20/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SeaSupport : NSObject
{
    BOOL isSupported;
    IBOutlet id window;
    __weak IBOutlet NSButton *maybeLater;
    __unsafe_unretained IBOutlet NSTextView *textView;
    __weak IBOutlet NSButton *supportSeashore;
    NSTimer *timer;
    int timerCount;
}

- (IBAction)restore:(id)sender;
- (BOOL)isSupportPurchased;
- (IBAction)supportSeashore:(id)sender;
- (IBAction)showSupportSeashore:(id)sender;
@end


NS_ASSUME_NONNULL_END

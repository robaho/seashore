//
//  StatusBarView.h
//  Seashore
//
//  Created by robert engels on 1/23/19.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface StatusBarView : NSView
{
    IBOutlet id channelControls;
    IBOutlet id zoomControls;
    IBOutlet NSTextField *statusLabel;
}

@end

NS_ASSUME_NONNULL_END

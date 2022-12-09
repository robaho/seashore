//
//  SeaButton.h
//  SeaComponents
//
//  Created by robert engels on 11/21/22.
//

#import <Cocoa/Cocoa.h>
#import "Label.h"

NS_ASSUME_NONNULL_BEGIN

@interface SeaButton : NSView
{
    Label *label;
    NSButton *button;
}

- (void)setLabel:(NSString*)label;
- (void)setEnabled:(BOOL)enabled;

+(SeaButton*)compactButton:(NSString*)title target:(id)target action:(nullable SEL)action;
+(SeaButton*)compactButton:(NSString*)title withLabel:(NSString*)label target:(id)target action:(nullable SEL)action;

@end

NS_ASSUME_NONNULL_END

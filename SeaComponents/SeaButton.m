//
//  SeaButton.m
//  SeaComponents
//
//  Created by robert engels on 11/21/22.
//

#import "SeaButton.h"
#import "SeaSizes.h"

@implementation SeaButton

- (id)init
{
    self = [super init];
    button = [[NSButton alloc] init];
    label = [Label compactLabel];
    [label setHidden:TRUE];
    [button setImagePosition:NSNoImage];
    [button setBezelStyle:NSRoundedBezelStyle];
    [button setButtonType:NSMomentaryPushInButton];
    [self addSubview:button];
    [self addSubview:label];
    self.autoresizesSubviews = FALSE;
    self.translatesAutoresizingMaskIntoConstraints = FALSE;
    return self;
}

- (NSSize)intrinsicContentSize
{
    int bh = [SeaSizes heightOf:button];

    if(![label isHidden]) {
        return NSMakeSize(100,MAX(bh,[label intrinsicContentSize].height));
    } else {
        return NSMakeSize([button intrinsicContentSize].width,bh);
    }
}

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    [self layout];
}

- (void)layout {
    NSRect bounds = [self bounds];
    if([label isHidden]) {
        [button setFrame:NSMakeRect(0,0,bounds.size.width,bounds.size.height)];
    } else {
        float w = [button fittingSize].width;
        [label setFrame:NSMakeRect(0,0,bounds.size.width-w,bounds.size.height)];
        [button setFrame:NSMakeRect(bounds.size.width-w,0,w,bounds.size.height)];
    }
}

- (void)setLabel:(NSString*)label
{
    [self->label setTitle:label];
}

- (void)setEnabled:(BOOL)enabled
{
    [self->button setEnabled:enabled];
}

+(SeaButton*)compactButton:(NSString*)title target:(id)target action:(nullable SEL)action
{
    return [SeaButton compactButton:title target:target action:action size:NSControlSizeMini];
}

+(SeaButton*)compactButton:(NSString*)title target:(id)target action:(nullable SEL)action size:(NSControlSize)size
{
    SeaButton *button = [[SeaButton alloc] init];
    [button->button setTitle:title];
    [button->button setTarget:target];
    [button->button setAction:action];
    [button setIdentifier:title];
    [button->button setCtrlSize:size];
    [button->button setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:size]]];
    [button->label setCtrlSize:NSControlSizeRegular];

    return button;
}

+(SeaButton*)compactButton:(NSString*)title withLabel:(NSString*)label target:(id)target action:(nullable SEL)action size:(NSControlSize)size
{
    SeaButton *button = [[SeaButton alloc] init];
    [button->label setHidden:FALSE];
    [button->button setTitle:title];
    [button->button setTarget:target];
    [button->button setAction:action];
    [button->button setCtrlSize:size];
    [button->button setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:size]]];
    [button->label setCtrlSize:size];

    [button setIdentifier:title];

    return button;
}

@end

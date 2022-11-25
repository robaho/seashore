//
//  SeaButton.m
//  SeaComponents
//
//  Created by robert engels on 11/21/22.
//

#import "SeaButton.h"

@implementation SeaButton

- (id)init
{
    self = [super init];
    button = [[NSButton alloc] init];
    label = [Label compactLabel];
    [label setHidden:TRUE];
    [button setButtonType:NSButtonTypeMomentaryPushIn];
    [button setControlSize:NSControlSizeMini];
    [button setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeMini]]];
    [button setBezelStyle:NSBezelStyleRounded];
    [self addSubview:button];
    [self addSubview:label];
    [button invalidateIntrinsicContentSize];
    [self layout];
    return self;
}

- (NSSize)intrinsicContentSize
{
    if(![label isHidden]) {
        return NSMakeSize(100,MAX([button intrinsicContentSize].height,[label intrinsicContentSize].height));
    } else {
        return NSMakeSize([button intrinsicContentSize].width,[button intrinsicContentSize].height);
    }
}

- (void)layout {
    [super layout];

    NSRect bounds = [self frame];
    if([label isHidden]) {
        [button setFrame:NSMakeRect(0,0,bounds.size.width,bounds.size.height)];
    } else {
        float w = [button intrinsicContentSize].width;
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

+(SeaButton*)compactButton:(NSString*)title target:(id)target action:(SEL)action
{
    SeaButton *button = [[SeaButton alloc] init];
    [button->button setTitle:title];
    [button->button setTarget:target];
    [button->button setAction:action];
    [button setIdentifier:title];

    return button;
}

+(SeaButton*)compactButton:(NSString*)title withLabel:(NSString*)label target:(id)target action:(SEL)action
{
    SeaButton *button = [[SeaButton alloc] init];
    [button->label setHidden:FALSE];
    [button->button setTitle:title];
    [button->button setTarget:target];
    [button->button setAction:action];
    [button setIdentifier:title];

    return button;
}


@end

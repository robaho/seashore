//
//  SeaCheck.m
//  SeaComponents
//
//  Created by robert engels on 11/21/22.
//

#import "SeaCheckbox.h"

@implementation SeaCheckbox

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];

    checkbox = [[NSButton alloc] init];
    [checkbox setButtonType:NSButtonTypeSwitch];
    [checkbox setTarget:self];
    [checkbox setAction:@selector(checkboxChanged:)];

    [self addSubview:checkbox];

    return self;
}

- (void)layout
{
    NSRect bounds = self.bounds;

    int w = bounds.size.width;
    int h = bounds.size.height;

    [checkbox setFrame:NSMakeRect(0,0,w,h)];
}

- (bool)isChecked {
    return [checkbox state] == NSControlStateValueOn;
}

- (void)setChecked:(bool)state {
    if(state) {
        [checkbox setState:NSControlStateValueOn];
    } else {
        [checkbox setState:NSControlStateValueOff];
    }
    [self setNeedsDisplay:TRUE];
}

- (NSSize)intrinsicContentSize
{
    return checkbox.intrinsicContentSize;
}

- (void)checkboxChanged:(id)sender
{
    if(listener) [listener componentChanged:self];
}

+ (SeaCheckbox*)checkboxWithTitle:(NSString*)title Listener:(nullable id<Listener>)listener
{
    SeaCheckbox *checkbox = [[SeaCheckbox alloc] init];
    [checkbox->checkbox setControlSize:NSControlSizeMini];
    [checkbox->checkbox setFont:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeMini]]];
    [checkbox->checkbox setTitle:title];
    checkbox->listener = listener;
    return checkbox;
}

@end

//
//  SeaCheck.m
//  SeaComponents
//
//  Created by robert engels on 11/21/22.
//

#import "SeaCheckbox.h"
#import "SeaSizes.h"

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

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    [self layout];
}

- (void)layout
{
    NSRect bounds = NSMakeRect(0,0,self.frame.size.width,self.frame.size.height);

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
    return NSMakeSize(checkbox.intrinsicContentSize.height,[SeaSizes heightOf:checkbox]);
}

- (void)checkboxChanged:(id)sender
{
    if(listener) [listener componentChanged:self];
}

+ (SeaCheckbox*)checkboxWithTitle:(NSString*)title Listener:(nullable id<Listener>)listener
{
    return [SeaCheckbox checkboxWithTitle:title Listener:listener Size:NSControlSizeMini];
}

+ (SeaCheckbox*)checkboxWithTitle:(NSString*)title Listener:(nullable id<Listener>)listener Size:(NSControlSize)size
{
    SeaCheckbox *checkbox = [[SeaCheckbox alloc] initWithFrame:NSZeroRect];
    [checkbox->checkbox setCtrlSize:size];
    [checkbox->checkbox setFont:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:size]]];
    [checkbox->checkbox setTitle:title];
    checkbox->listener = listener;
    return checkbox;
}

@end

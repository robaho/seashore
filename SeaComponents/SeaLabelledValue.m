//
//  SeaLabelledValue.m
//  SeaComponents
//
//  Created by robert engels on 11/27/22.
//

#import "SeaLabelledValue.h"
#import "SeaColorWell.h"

@implementation SeaLabelledValue

inline static NSColor* secondaryLabelColor(void)
{
    if(@available(macos 10.10, *))
    {
        return NSColor.secondaryLabelColor;
    }
    return NSColor.scrollBarColor;
}


- (id)init
{
    self = [super init];
    label = [Label compactLabel];
    value = [Label compactLabel];
    colorWell = [[MinimalColorWell alloc] init];

    [colorWell setEnabled:FALSE];
    [colorWell setHidden:TRUE];

    [colorWell setCtrlSize:NSControlSizeMini];

    [label setTextColor:secondaryLabelColor()];

    [self addSubview:label];
    [self addSubview:value];
    [self addSubview:colorWell];
    
    return self;
}

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    [self layout];
}

- (void)layout
{
    NSRect bounds = self.bounds;
    float half = bounds.size.width/2;
    label.frame = NSMakeRect(0,0,half,bounds.size.height);
    if([colorWell isHidden]) {
        value.frame = NSMakeRect(half,0,half,bounds.size.height);
    } else {
        colorWell.frame = NSMakeRect(half,0,half,bounds.size.height);
    }
}

- (NSSize)intrinsicContentSize
{
    NSSize lsize = [label intrinsicContentSize];
    NSSize vsize = [colorWell isHidden] ? [value intrinsicContentSize] : [colorWell intrinsicContentSize];
    return NSMakeSize(lsize.width+vsize.width, MAX(lsize.height,vsize.height));
}

-(void)setStringValue:(NSString*)value
{
    self->value.stringValue = value;
}
-(void)setIntValue:(int)value
{
    self->value.intValue = value;
}
-(void)setColorValue:(NSColor *)color
{
    [value setHidden:TRUE];

    if(color) {
        [colorWell setHidden:FALSE];
        [colorWell setColor:color];
    } else {
        [colorWell setHidden:TRUE];
    }
    [self layout];
    [self setNeedsDisplay:TRUE];
}

+(SeaLabelledValue*)withLabel:(NSString*)label
{
    return [SeaLabelledValue withLabel:label size:NSControlSizeMini];
}

+(SeaLabelledValue*)withLabel:(NSString*)label size:(NSControlSize)size
{
    SeaLabelledValue *lv = [[SeaLabelledValue alloc] init];
    [lv->label setStringValue:label];
    [lv->label setCtrlSize:size];
    [lv->value setCtrlSize:size];
    [lv->colorWell setCtrlSize:size];
    return lv;
}


@end

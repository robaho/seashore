//
//  SeaColorWell.m
//  SeaComponents
//
//  Created by robert engels on 3/9/22.
//

#import "SeaColorWell.h"

@implementation SeaColorWell

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];

    colorWell = [[NSColorWell alloc] init];
    title = [[Label alloc] init];

    colorWell.target=self;
    colorWell.action=@selector(colorChanged:);

    [self addSubview:colorWell];
    [self addSubview:title];

    return self;
}

- (void)layout
{
    NSRect bounds = self.bounds;
    float half = bounds.size.height / 2;
    [colorWell setFrame:NSMakeRect(0,0,bounds.size.width,half)];
    [title setFrame:NSMakeRect(0,half,bounds.size.width,half)];
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(100,40);
}

- (void)setColorValue:(NSColor*)value
{
    [colorWell setColor:value];
}

- (NSColor*)colorValue
{
    return [colorWell color];
}

- (void)colorChanged:(id)sender
{
    [listener componentChanged:sender];
}

+ (SeaColorWell*)colorWellWithTitle:(NSString*)title Listener:(id<Listener>)listener
{
    SeaColorWell *cw = [[SeaColorWell  alloc] init];
    [cw->title setStringValue:title];
    cw->listener = listener;
    return cw;
}

@end

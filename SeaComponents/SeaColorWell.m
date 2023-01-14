//
//  SeaColorWell.m
//  SeaComponents
//
//  Created by robert engels on 3/9/22.
//

#import "SeaColorWell.h"
#import "SeaSizes.h"

@implementation MinimalColorWell

- (void)drawRect:(NSRect)dirtyRect
{
    float width = 0.20;

    if(!self.enabled) {
        width = .10;
    }

    NSColor *color = [self color];
    NSColor *border = [self isActive] ? [NSColor lightGrayColor] : [NSColor darkGrayColor];

    NSRect outer = [self bounds];
    float vborder = outer.size.height*width;
    float hborder = outer.size.width*width;
    float borderWidth = MIN(hborder,vborder);

    NSRect inner = CGRectInset(outer, borderWidth, borderWidth);

    [border setFill];
    NSRectFill(outer);
    [super drawWellInside:inner];
}

- (NSSize)intrinsicContentSize
{
    NSSize size = [super intrinsicContentSize];
    return NSMakeSize(size.width,[SeaSizes heightOf:self]);
}

@end


@implementation SeaColorWell

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];

    colorWell = [[MinimalColorWell alloc] init];
    title = [[Label alloc] init];

    colorWell.target=self;
    colorWell.action=@selector(colorChanged:);

    [self addSubview:colorWell];
    [self addSubview:title];

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

    if(compact) {
        float width = .75;
        float h = [title intrinsicContentSize].height;
        [colorWell setFrame:NSMakeRect(bounds.size.width*width,0,bounds.size.width*(1-width),bounds.size.height)];
        [title setFrame:NSMakeRect(0,0,bounds.size.width*width,bounds.size.height)];
    } else {
        float h = [title intrinsicContentSize].height;
        [colorWell setFrame:NSMakeRect(0,0,bounds.size.width,bounds.size.height-h)];
        [title setFrame:NSMakeRect(0,bounds.size.height-h,bounds.size.width,h)];
    }
}

- (NSSize)intrinsicContentSize
{
    if(compact) {
        return NSMakeSize(100,MAX([title intrinsicContentSize].height,[colorWell intrinsicContentSize].height));
    } else {
        return NSMakeSize(100,[title intrinsicContentSize].height+[colorWell intrinsicContentSize].height);
    }
}

- (void)setColorValue:(NSColor*)value
{
    if(value) {
        [colorWell setColor:value];
        [colorWell setHidden:FALSE];
    } else {
        [colorWell setHidden:TRUE];
    }
}

- (NSColor*)colorValue
{
    return [colorWell color];
}

- (void)colorChanged:(id)sender
{
    if(listener) {
        [listener componentChanged:sender];
    }
}

- (void)disableColorWell
{
    [colorWell setEnabled:FALSE];
}

+ (SeaColorWell*)colorWellWithTitle:(NSString*)title Listener:(nullable id<Listener>)listener
{
    SeaColorWell *cw = [[SeaColorWell alloc] init];
    [cw->title setStringValue:title];
    [cw->colorWell setCtrlSize:NSControlSizeSmall];
    cw->listener = listener;
    return cw;
}
+ (SeaColorWell*)compactWithTitle:(NSString*)title Listener:(nullable id<Listener>)listener
{
    SeaColorWell *cw = [[SeaColorWell alloc] init];
    cw->compact = true;
    [cw->title makeCompact];
    [cw->colorWell setCtrlSize:NSControlSizeMini];
    [cw->title setStringValue:title];
    cw->listener = listener;
    return cw;
}

@end

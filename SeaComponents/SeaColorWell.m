//
//  SeaColorWell.m
//  SeaComponents
//
//  Created by robert engels on 3/9/22.
//

#import "SeaColorWell.h"

@interface MinimalColorWell : NSColorWell
@end

@implementation MinimalColorWell

- (void)drawRect:(NSRect)dirtyRect
{
    NSColor *color = [self color];
    NSColor *border = [self isActive] ? [NSColor lightGrayColor] : [NSColor darkGrayColor];

    NSRect outer = [self bounds];
    int vborder = outer.size.height*.20;
    int hborder = outer.size.width*.20;
    int borderWidth = MIN(hborder,vborder);
    NSRect inner = CGRectInset(outer, borderWidth, borderWidth);

    [border setFill];
    NSRectFill(outer);
    [super drawWellInside:inner];
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

- (void)layout
{
    if(compact) {
        NSRect bounds = self.bounds;
        float h = [title intrinsicContentSize].height;
        [colorWell setFrame:NSMakeRect(bounds.size.width*.75,0,bounds.size.width*.25,bounds.size.height)];
        [title setFrame:NSMakeRect(0,0,bounds.size.width*.75,bounds.size.height)];
    } else {
        NSRect bounds = self.bounds;
        float h = [title intrinsicContentSize].height;
        [colorWell setFrame:NSMakeRect(0,0,bounds.size.width,bounds.size.height-h)];
        [title setFrame:NSMakeRect(0,h,bounds.size.width,h)];
    }
}

- (NSSize)intrinsicContentSize
{
    if(compact) {
        return NSMakeSize(100,MAX([title intrinsicContentSize].height,[colorWell intrinsicContentSize].height));
    } else {
        return NSMakeSize(100,[title intrinsicContentSize].height + [colorWell intrinsicContentSize].height);
    }
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
+ (SeaColorWell*)compactWithTitle:(NSString*)title Listener:(id<Listener>)listener
{
    SeaColorWell *cw = [[SeaColorWell  alloc] init];
    cw->compact = true;
    [cw->title makeCompact];
    [cw->title setStringValue:title];
    cw->listener = listener;
    return cw;
}

@end

//
//  Label.m
//  SeaComponents
//
//  Created by robert engels on 3/6/22.
//

#import "Label.h"

@interface CenteringCell : NSTextFieldCell
@end
@implementation CenteringCell
- (NSRect) titleRectForBounds:(NSRect)frame {
    CGFloat stringHeight = self.attributedStringValue.size.height;
    NSRect titleRect     = [super titleRectForBounds:frame];
    titleRect.origin.y = frame.origin.y +
    (frame.size.height - stringHeight) / 2.0;
    return titleRect;
}
- (void) drawInteriorWithFrame:(NSRect)cFrame inView:(NSView*)cView {
    [super drawInteriorWithFrame:[self titleRectForBounds:cFrame] inView:cView];
}
@end

@implementation Label

- (Label*)init
{
    self = [super init];
    [self setLineBreakMode:NSLineBreakByTruncatingTail];
    [self setBezeled:NO];
    [self setDrawsBackground:NO];
    [self setEditable:NO];
    [self setSelectable:NO];
    [self setMaximumNumberOfLines:1];
    [self setBordered:FALSE];
    [self setCell:[[CenteringCell alloc]init]];
    return self;
}

- (void)setTitle:(NSString*)title
{
    [self setStringValue:title];
}

- (void)makeSmall {
    [self setControlSize:NSControlSizeSmall];
    [self setFont:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeSmall]]];
}
- (void)makeCompact {
    [self setControlSize:NSControlSizeMini];
    [self setFont:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeMini]]];
}
- (void)makeRegular {
    [self setControlSize:NSControlSizeRegular];
    [self setFont:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeRegular]]];
}

+(Label*)label
{
    Label* label = [[Label alloc] init];
    [label makeRegular];
    return label;
}

+(Label*)compactLabel
{
    Label* label = [[Label alloc] init];
    [label makeCompact];
    return label;
}

+(Label*)smallLabel
{
    Label* label = [[Label alloc] init];
    [label makeSmall];
    return label;
}

@end

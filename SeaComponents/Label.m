//
//  Label.m
//  SeaComponents
//
//  Created by robert engels on 3/6/22.
//

#import "Label.h"
#import "SeaSizes.h"

@interface CenteringCell : NSTextFieldCell
@end
@implementation CenteringCell
- (NSRect)titleRectForBounds:(NSRect)theRect {
    NSRect titleFrame = [super titleRectForBounds:theRect];
    NSSize titleSize = [[self attributedStringValue] boundingRectWithSize:theRect.size options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingTruncatesLastVisibleLine].size;
    titleFrame.origin.y = theRect.origin.y + (theRect.size.height - titleSize.height) / 2.0;
    if(self.bordered)
        titleFrame.origin.x +=2;
    return titleFrame;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect titleRect = [self titleRectForBounds:cellFrame];
    [[self attributedStringValue] drawWithRect:titleRect options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingTruncatesLastVisibleLine];
}
@end


@implementation Label

- (Label*)init
{
    self = [super init];
    [self setCell:[[CenteringCell alloc] init]];
    self.cell.truncatesLastVisibleLine = TRUE;
    self.cell.usesSingleLineMode = TRUE;
    [self setBezeled:NO];
    [self setDrawsBackground:NO];
    [self setEditable:NO];
    [self setSelectable:NO];
    [self setBordered:FALSE];
    return self;
}

- (void)setTitle:(NSString*)title
{
    [self setStringValue:title];
}

- (NSString*)title
{
    return [self stringValue];
}

- (void)setCtrlSize:(NSControlSize)size
{
    [super setCtrlSize:size];
    [self setFont:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:size]]];
}

- (void)makeSmall {
    [self setCtrlSize:NSControlSizeSmall];
}
- (void)makeCompact {
    [self setCtrlSize:NSControlSizeMini];
}
- (void)makeRegular {
    [self setCtrlSize:NSControlSizeRegular];
}

- (void)makeMultiline {
    self.cell.lineBreakMode=NSLineBreakByWordWrapping;
    self.cell.usesSingleLineMode = FALSE;
}

- (void)makeNote {
    [self makeMultiline];
    [self setBordered:TRUE];
    [self setBezelStyle:NSTextFieldRoundedBezel];
    self.cell.highlighted = true;
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
+ (Label*)labelWithSize:(NSControlSize)size
{
    Label* label = [[Label alloc] init];
    [label setCtrlSize:size];
    return label;
}


@end

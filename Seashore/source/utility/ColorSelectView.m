#import "ColorSelectView.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaController.h"
#import "SeaTools.h"
#import "AbstractTool.h"
#import "TextureUtility.h"
#import "SeaTexture.h"
#import "SeaWhiteboard.h"
#import "ToolboxUtility.h"

@implementation ColorSelectView

- (void)awakeFromNib
{
    [gColorPanel setIsVisible:[gUserDefaults boolForKey:@"colorpanel visible"]];
    if([gColorPanel isVisible]) {
        [fgWell activate:TRUE];
    }
}
- (void)dealloc {
    [gUserDefaults setBool:[gColorPanel isVisible] forKey:@"colorpanel visible"];
    [gColorPanel setTarget:nil];
    [gColorPanel setAction:NULL];
}

- (void)setDocument:(id)doc
{
    document = doc;
    [self update];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return YES;
}

- (IBAction)swapColors:(id)sender
{
	NSColor *tempColor;
	[self setNeedsDisplay:YES];
	tempColor = [[document toolboxUtility] foreground];
	[[document toolboxUtility] setForeground:[[document toolboxUtility] background]];
	[[document toolboxUtility] setBackground:tempColor];
	[self update];
}

- (IBAction)defaultColors:(id)sender
{
	[self setNeedsDisplay:YES];
	[[document toolboxUtility] setForeground:[NSColor blackColor]];
	[[document toolboxUtility] setBackground:[NSColor whiteColor]];
	[self update];
}

- (IBAction)activateForegroundColor:(id)sender
{
    [fgWell activate:TRUE];
}

- (IBAction)activateBackgroundColor:(id)sender
{
    [bgWell activate:TRUE];
}

- (IBAction)changeForegroundColor:(id)sender
{
    [[document toolboxUtility] setForeground:[sender color]];
}

- (IBAction)changeBackgroundColor:(id)sender
{
    [[document toolboxUtility] setBackground:[sender color]];
}

- (void)update
{
    [fgWell setColor:[[document toolboxUtility] foreground]];
    [bgWell setColor:[[document toolboxUtility] background]];
}

@end

@implementation ColorSelectViewColorWell

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

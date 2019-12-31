#import "ColorSelectView.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaController.h"
#import "SeaTools.h"
#import "AbstractTool.h"
#import "TextureUtility.h"
#import "SeaTexture.h"
#import "TransparentUtility.h"
#import "TextureUtility.h"
#import "SeaWhiteboard.h"
#import "ToolboxUtility.h"
#import "Bitmap.h"

@implementation ColorSelectView

#define FG_RECT NSRect fg = NSMakeRect(2,2,20,10);
#define BG_RECT NSRect bg = NSMakeRect(19,12,20,10);
#define SWAP_RECT NSRect swap = NSMakeRect(6,14,10,10);

- (id)initWithFrame:(NSRect)frame
{
	// Initialize the super
	if (![super initWithFrame:frame])
		return NULL;
	
	// Set data members appropriately
	mouseDownOnSwap = NO;
	
	return self;
}

- (void)setDocument:(id)doc
{
	document = doc;
	[self setNeedsDisplay:YES];
	
	if (doc == NULL) {
	
		// If we are closing the last document hide the panel for selecting the foreround or background colour
		if ([gColorPanel isVisible] && ([[gColorPanel title] isEqualToString:LOCALSTR(@"foreground", @"Foreground")] || [[gColorPanel title] isEqualToString:LOCALSTR(@"background", @"Background")])) {
			if ([[[NSDocumentController sharedDocumentController] documents] count] == 1)
				[gColorPanel orderOut:self];
		}
		
	}
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return YES;
}

- (void)drawRect:(NSRect)rect
{
    FG_RECT
    BG_RECT
    SWAP_RECT
    
	BOOL foregroundIsTexture = [[document currentTool] foregroundIsTexture];
    
    [self drawColorWell:bg];
    
	// Actual Color
	if (document == NULL)
		[[NSColor whiteColor] set];
	else {
        [[[document contents] background] set];
	}
	[[NSBezierPath bezierPathWithRect:bg] fill];
    
    [self drawColorWell:fg];

	if (foregroundIsTexture) {
		[[NSColor colorWithPatternImage:[[[document textureUtility] activeTexture] thumbnail]] set];
		[[NSBezierPath bezierPathWithRect:fg] fill];
	}
	else {
		if (document == NULL)
			[[NSColor blackColor] set];
		else {
            [[[document contents] foreground] set];
		}
		[[NSBezierPath bezierPathWithRect:fg] fill];
	}
	
    NSImage *image = [NSImage imageNamed:@"swapTemplate"];
    [image setFlipped:YES];
    
    image = getTinted(image,[NSColor controlTextColor]);
	// Draw the images
    [image drawInRect:swap fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
}

- (void)drawColorWell:(NSRect)rect
{
    [[NSColor darkGrayColor] set];
    [[NSBezierPath bezierPathWithRect:NSInsetRect(rect,-2,-2)] fill];
    [[NSColor lightGrayColor] set];
    [[NSBezierPath bezierPathWithRect:NSInsetRect(rect,-1,-1)] fill];
    
    // draw the triangles
    [[NSColor blackColor] set];
    NSBezierPath *tempPath = [NSBezierPath bezierPath];
    [tempPath moveToPoint:rect.origin];
    [tempPath lineToPoint:NSMakePoint(NSMaxX(rect),rect.origin.y)];
    [tempPath lineToPoint:NSMakePoint(rect.origin.x,NSMaxY(rect))];
    [tempPath lineToPoint:rect.origin];
    [tempPath fill];
    // Black
    [[NSColor whiteColor] set];
    tempPath = [NSBezierPath bezierPath];
    [tempPath moveToPoint:NSMakePoint(rect.origin.x,NSMaxY(rect))];
    [tempPath lineToPoint:NSMakePoint(NSMaxX(rect),NSMaxY(rect))];
    [tempPath lineToPoint:NSMakePoint(NSMaxX(rect),rect.origin.y)];
    [tempPath lineToPoint:NSMakePoint(rect.origin.x,NSMaxY(rect))];
    [tempPath fill];
}

- (IBAction)activateForegroundColor:(id)sender
{	
	// Displays colour panel for setting the foreground 
	[gColorPanel setAction:NULL];
	[gColorPanel setShowsAlpha:YES];
	[gColorPanel setColor:[[document contents] foreground]];
	[gColorPanel orderFront:self];
	[gColorPanel setTitle:LOCALSTR(@"foreground", @"Foreground")];
	[gColorPanel setContinuous:YES];
	[gColorPanel setAction:@selector(changeForegroundColor:)];
	[gColorPanel setTarget:self];
}

- (IBAction)activateBackgroundColor:(id)sender
{
	// Displays colour panel for setting the background
	[gColorPanel setAction:NULL];
	[gColorPanel setShowsAlpha:YES];
	[gColorPanel setColor:[[document contents] background]];
	[gColorPanel orderFront:self];
	[gColorPanel setTitle:LOCALSTR(@"background", @"Background")];
	[gColorPanel setContinuous:YES];
	[gColorPanel setAction:@selector(changeBackgroundColor:)];
	[gColorPanel setTarget:self];
}

- (IBAction)swapColors:(id)sender
{
	NSColor *tempColor;
	[self setNeedsDisplay:YES];
	tempColor = [[document contents] foreground];
	[[document toolboxUtility] setForeground:[[document contents] background]];
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

- (void)mouseDown:(NSEvent *)theEvent
{
    FG_RECT
    BG_RECT
    SWAP_RECT

	NSPoint clickPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
	
	// Don't do anything if there isn't a document to do it on
	if (!document)
		return;
	
	if (NSMouseInRect(clickPoint, fg, [self isFlipped])) {
		[self activateForegroundColor: self];
	
	}
	else if (NSMouseInRect(clickPoint, bg, [self isFlipped])) {
		[self activateBackgroundColor: self];
	}
	else if (NSMouseInRect(clickPoint, swap, [self isFlipped])) {
		
		// Highlight the swap button
		mouseDownOnSwap = YES;
		[self setNeedsDisplay:YES];
		
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
    SWAP_RECT
	NSPoint clickPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
	
	if (mouseDownOnSwap) {
	
		// Return the swap button to normal
		mouseDownOnSwap = NO;
		[self setNeedsDisplay:YES];
		
		// If the button was released in the same rectangle swap the colours
		if (NSMouseInRect(clickPoint, swap, [self isFlipped]))
			[self swapColors: self];
	}
}

- (void)changeForegroundColor:(id)sender
{
	[[document toolboxUtility] setForeground:[sender color]];
	[textureUtility setActiveTextureIndex:-1];
	[self setNeedsDisplay:YES];
}

- (void)changeBackgroundColor:(id)sender
{
	[[document toolboxUtility] setBackground:[sender color]];
	[self setNeedsDisplay:YES];
}

- (void)update
{
	// Reconfigure the colour panel correctly
	if ([gColorPanel isVisible] && ([[gColorPanel title] isEqualToString:LOCALSTR(@"foreground", @"Foreground")] || [[gColorPanel title] isEqualToString:LOCALSTR(@"background", @"Background")])) {
				
		// Set colour correctly
		if ([[gColorPanel title] isEqualToString:LOCALSTR(@"foreground", @"Foreground")])
			[gColorPanel setColor:[[document toolboxUtility] foreground]];
		else
			[gColorPanel setColor:[[document toolboxUtility] background]];
		
	}
	
	// Call for an update of the view
	[self setNeedsDisplay:YES];
}

- (BOOL)isFlipped
{
	return YES;
}

- (BOOL)isOpaque
{
	return NO;
}

@end

#import "ColorSelectView.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaController.h"
#import "SeaTools.h"
#import "AbstractTool.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "SeaTexture.h"
#import "TransparentUtility.h"
#import "TextureUtility.h"
#import "SeaWhiteboard.h"
#import "ToolboxUtility.h"

@implementation ColorSelectView

- (id)initWithFrame:(NSRect)frame
{
	// Initialize the super
	if (![super initWithFrame:frame])
		return NULL;
	
	// Set data members appropriately
	mouseDownOnSwap = NO;
	
	return self;
}

- (void)dealloc
{
	[super dealloc];
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
	BOOL foregroundIsTexture = [[[document tools] currentTool] foregroundIsTexture];
	
	NSBezierPath *tempPath;
	// Background color
	// Border
	[[NSColor colorWithCalibratedWhite:0.341 alpha:1.0] set];
	[[NSBezierPath bezierPathWithRect:NSMakeRect(24, 6, 30, 20)] fill];
	[[NSColor colorWithCalibratedWhite:0.759 alpha:1.0] set];
	[[NSBezierPath bezierPathWithRect:NSMakeRect(25, 7, 28, 18)] fill];
	// White
	[[NSColor whiteColor] set];
	tempPath = [NSBezierPath bezierPath];
	[tempPath moveToPoint:NSMakePoint(52, 8)];
	[tempPath lineToPoint:NSMakePoint(26, 24)];
	[tempPath lineToPoint:NSMakePoint(52,24)];
	[tempPath fill];
	// Black
	[[NSColor blackColor] set];
	tempPath = [NSBezierPath bezierPath];
	[tempPath moveToPoint:NSMakePoint(26, 8)];
	[tempPath lineToPoint:NSMakePoint(52, 8)];
	[tempPath lineToPoint:NSMakePoint(26,24)];
	[tempPath fill];
	// Actual Color
	if (document == NULL)
		[[NSColor whiteColor] set];
	else {
		if ([[document whiteboard] CMYKPreview])
			[[[document whiteboard] matchColor:[[document contents] background]] set];
		else
			[[[document contents] background] set];
	}
	[[NSBezierPath bezierPathWithRect:NSMakeRect(26, 8, 26, 16)] fill];

	// Forground Color
	// Border
	[[NSColor colorWithCalibratedWhite:0.341 alpha:1.0] set];
	[[NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, 30, 20)] fill];
	[[NSColor colorWithCalibratedWhite:0.759 alpha:1.0] set];
	[[NSBezierPath bezierPathWithRect:NSMakeRect(1, 1, 28, 18)] fill];
	// White
	[[NSColor whiteColor] set];
	tempPath = [NSBezierPath bezierPath];
	[tempPath moveToPoint:NSMakePoint(28, 2)];
	[tempPath lineToPoint:NSMakePoint(2, 18)];
	[tempPath lineToPoint:NSMakePoint(28,18)];
	[tempPath fill];
	// Black
	[[NSColor blackColor] set];
	tempPath = [NSBezierPath bezierPath];
	[tempPath moveToPoint:NSMakePoint(2, 2)];
	[tempPath lineToPoint:NSMakePoint(28, 2)];
	[tempPath lineToPoint:NSMakePoint(2,18)];
	[tempPath fill];
	// Actual Color
	// Draw the foreground button
	if (foregroundIsTexture) {
		[[NSColor colorWithPatternImage:[[[[SeaController utilitiesManager] textureUtilityFor:document] activeTexture] thumbnail]] set];
		[[NSBezierPath bezierPathWithRect:NSMakeRect(2, 2, 26, 16)] fill];
	}
	else {
		if (document == NULL)
			[[NSColor blackColor] set];
		else {
			if ([[document whiteboard] CMYKPreview])
				[[[document whiteboard] matchColor:[[document contents] foreground]] set];
			else
				[[[document contents] foreground] set];
		}
		[[NSBezierPath bezierPathWithRect:NSMakeRect(2, 2, 26, 16)] fill];
	}
	
	
	// Draw the images
	[[NSImage imageNamed:@"swap"] compositeToPoint:NSMakePoint(18, 27) operation:NSCompositeSourceOver];
	//[[NSImage imageNamed:@"samp"] compositeToPoint:NSMakePoint(0, 27) operation:NSCompositeSourceOver];
	//[[NSImage imageNamed:@"def"] compositeToPoint:NSMakePoint(44, 6) operation:NSCompositeSourceOver];
	
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
	[(ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document] setForeground:[[document contents] background]];
	[(ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document] setBackground:tempColor];
	[self update];
}

- (IBAction)defaultColors:(id)sender
{
	[self setNeedsDisplay:YES];
	[(ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document] setForeground:[NSColor blackColor]];
	[(ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document] setBackground:[NSColor whiteColor]];
	[self update];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint clickPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
	
	// Don't do anything if there isn't a document to do it on
	if (!document)
		return;
	
	if (NSMouseInRect(clickPoint, NSMakeRect(2, 2, 26, 16), [self isFlipped])) {
		[self activateForegroundColor: self];
	
	}
	else if (NSMouseInRect(clickPoint, NSMakeRect(26, 8, 26, 16), [self isFlipped])) {
		[self activateBackgroundColor: self];
	}
	else if (NSMouseInRect(clickPoint, NSMakeRect(9, 27 - 8, 18, 10), [self isFlipped])) {
		
		// Highlight the swap button
		mouseDownOnSwap = YES;
		[self setNeedsDisplay:YES];
		
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint clickPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
	
	if (mouseDownOnSwap) {
	
		// Return the swap button to normal
		mouseDownOnSwap = NO;
		[self setNeedsDisplay:YES];
		
		// If the button was released in the same rectangle swap the colours
		if (NSMouseInRect(clickPoint, NSMakeRect(9, 27 - 8, 18, 10), [self isFlipped]))
			[self swapColors: self];
	}
}

- (void)changeForegroundColor:(id)sender
{
	id toolboxUtility = (ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document];
	
	[toolboxUtility setForeground:[sender color]];
	[textureUtility setActiveTextureIndex:-1];
	[self setNeedsDisplay:YES];
}

- (void)changeBackgroundColor:(id)sender
{
	id toolboxUtility = (ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document];
	
	[toolboxUtility setBackground:[sender color]];
	[self setNeedsDisplay:YES];
}

- (void)update
{
	// Reconfigure the colour panel correctly
	if ([gColorPanel isVisible] && ([[gColorPanel title] isEqualToString:LOCALSTR(@"foreground", @"Foreground")] || [[gColorPanel title] isEqualToString:LOCALSTR(@"background", @"Background")])) {
				
		// Set colour correctly
		if ([[gColorPanel title] isEqualToString:LOCALSTR(@"foreground", @"Foreground")])
			[gColorPanel setColor:[(ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document] foreground]];
		else
			[gColorPanel setColor:[(ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document] background]];
		
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

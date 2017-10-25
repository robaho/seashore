#import "InfoPanel.h"
#import "InfoPanelBacking.h"

@implementation InfoPanel

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	//Call NSWindow's version of this function, but pass in the all-important value of NSBorderlessWindowMask
    //for the styleMask so that the window doesn't have a title bar
    NSWindow* result = [super initWithContentRect:contentRect styleMask:(NSBorderlessWindowMask) backing:NSBackingStoreBuffered defer:NO];
    //Set the background color to clear so that (along with the setOpaque call below) we can see through the parts
    //of the window that we're not drawing into
    [result setBackgroundColor: [NSColor clearColor]];
    //This next line pulls the window up to the front on top of other system windows.  This is how the Clock app behaves;
    //generally you wouldn't do this for windows unless you really wanted them to float above everything.
    [result setLevel: NSNormalWindowLevel];
    //Let's start with no transparency for all drawing into the window
    [result setAlphaValue:1.0];
    //but let's turn off opaqueness so that we can see through the parts of the window that we're not drawing into
    [result setOpaque:NO];
    //and while we're at it, make sure the window has a shadow, which will automatically be the shape of our custom content.
    [result setHasShadow: YES];
	[result setDelegate:result];
	
	return result;
}

- (void)awakeFromNib{
	// We need to initialize the style variable
	//panelStyle = kFloatingPanelStyle;
	// or do we?
}


- (BOOL)canBecomeKeyWindow
{
	// Overrides the default to allow a borderless window to be the key window.
	return YES;
}

//
- (BOOL)canBecomeMainWindow
{
	// Overrides the default to allow a borderless window to be the main window.
	return NO;
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)defaultFrame
{
	return defaultFrame;
}


/* Info Panel Specific Methods */

- (int) panelStyle
{
	return panelStyle;
}

- (void) setPanelStyle:(int)newStyle
{
	panelStyle = newStyle;
}

- (void) orderFrontToGoal:(NSPoint)goal onWindow:(NSWindow *)parent
{
	NSRect oldFrame = [self frame];
	if(panelStyle == kVerticalPanelStyle){
        oldFrame.origin.x = goal.x - oldFrame.size.width / 2;
        oldFrame.origin.y = goal.y - oldFrame.size.height;
    }else if(panelStyle == kHorizontalPanelStyle){
        oldFrame.origin.x = goal.x;
	oldFrame.origin.y = goal.y - 2 * oldFrame.size.height / 3;
    }
    
    NSRect screenRect = [[parent screen] visibleFrame];
    float right = screenRect.size.width + screenRect.origin.x;
    if(oldFrame.size.width + oldFrame.origin.x > right){
        oldFrame.origin.x = right - oldFrame.size.width;
    }else if(oldFrame.origin.x < screenRect.origin.x){
        oldFrame.origin.x = screenRect.origin.x;
    }
    
    float top = screenRect.size.height + screenRect.origin.y;
    if(oldFrame.size.height + oldFrame.origin.y > top){
        oldFrame.origin.y = top - oldFrame.size.height;
    }else if(oldFrame.origin.y < screenRect.origin.y){
        oldFrame.origin.y = screenRect.origin.y;
    }
    
	[self setFrame:oldFrame display: YES];
	[parent addChildWindow:self ordered:NSWindowAbove];

	[self orderFront:self];
}


@end

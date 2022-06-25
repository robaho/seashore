//
//  RoundWindow.m
//  RoundWindow
//
//  Created by Matt Gallagher on 12/12/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file without charge in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "InfoPanel.h"
#import "InfoPanelFrameView.h"

@implementation InfoPanel

//
// initWithContentRect:styleMask:backing:defer:screen:
//
// Init method for the object.
//
- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)windowStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)deferCreation
{
    self = [super
            initWithContentRect:contentRect
            styleMask:NSBorderlessWindowMask
            backing:bufferingType
            defer:deferCreation];
    if (self)
    {
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
    }
    return self;
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

//
// setContentSize:
//
// Convert from childContentView to frameView for size.
//
- (void)setContentSize:(NSSize)newSize
{
    NSSize sizeDelta = newSize;
    NSSize childBoundsSize = [childContentView bounds].size;
    sizeDelta.width -= childBoundsSize.width;
    sizeDelta.height -= childBoundsSize.height;

    InfoPanelFrameView *frameView = [super contentView];
    NSSize newFrameSize = [frameView bounds].size;
    newFrameSize.width += sizeDelta.width;
    newFrameSize.height += sizeDelta.height;

    [super setContentSize:newFrameSize];
}

//
// setContentView:
//
// Keep our frame view as the content view and make the specified "aView"
// the child of that.
//
- (void)setContentView:(NSView *)aView
{
    if ([childContentView isEqualTo:aView])
    {
        return;
    }

    NSRect bounds = [self frame];
    bounds.origin = NSZeroPoint;

    InfoPanelFrameView *frameView = [super contentView];
    if (!frameView)
    {
        frameView = [[InfoPanelFrameView alloc] initWithFrame:bounds];
        [super setContentView:frameView];
    }

    if (childContentView)
    {
        [childContentView removeFromSuperview];
    }
    childContentView = aView;
    [childContentView setFrame:[self contentRectForFrameRect:bounds]];
    [childContentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [frameView addSubview:childContentView];
}

//
// contentView
//
// Returns the child of our frame view instead of our frame view.
//
- (NSView *)contentView
{
    return childContentView;
}

//
// canBecomeKeyWindow
//
// Overrides the default to allow a borderless window to be the key window.
//
- (BOOL)canBecomeKeyWindow
{
    return YES;
}

//
// canBecomeMainWindow
//
// Overrides the default to allow a borderless window to be the main window.
//
- (BOOL)canBecomeMainWindow
{
    return YES;
}

//
// contentRectForFrameRect:
//
// Returns the rect for the content rect, taking the frame.
//
- (NSRect)contentRectForFrameRect:(NSRect)windowFrame
{
    windowFrame.origin = NSZeroPoint;
    return NSInsetRect(windowFrame,
                       WINDOW_FRAME_PADDING,
                       WINDOW_FRAME_PADDING);
}

//
// frameRectForContentRect:styleMask:
//
// Ensure that the window is make the appropriate amount bigger than the content.
//
+ (NSRect)frameRectForContentRect:(NSRect)windowContentRect styleMask:(NSUInteger)windowStyle
{
    return NSInsetRect(windowContentRect, -WINDOW_FRAME_PADDING, -WINDOW_FRAME_PADDING);
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

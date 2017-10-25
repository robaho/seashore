#import "NSExtendedTableView.h"

@implementation NSExtendedTableView

- (BOOL)acceptsFirstResponder
{
  return [self isEnabled];
}

- (void)dealloc
{
  [saveBackgroundColors release];
  [saveTextColors release];
  [super dealloc];
}

- (void)saveState
{
  NSEnumerator *e = [[self tableColumns] objectEnumerator];
  NSTableColumn *curColumn;

  if(saveBackgroundColors == nil)
    saveBackgroundColors = [[NSMutableArray alloc] init];
  if(saveTextColors == nil)
    saveTextColors = [[NSMutableArray alloc] init];

  [saveTextColors removeAllObjects];
  [saveBackgroundColors removeAllObjects];

  while ((curColumn = [e nextObject])) {
    if([[curColumn dataCell] isKindOfClass:[NSTextFieldCell class]]) {
      [saveTextColors addObject:[[curColumn dataCell] textColor]];
      [saveBackgroundColors 
             addObject:[[curColumn dataCell] backgroundColor]];
    }
  }

  saveVerticalScrollerEnabled = FALSE;
  saveHorizontalScrollerEnabled = FALSE;
  if([[self enclosingScrollView] hasVerticalScroller])
    saveVerticalScrollerEnabled = 
         [[[self enclosingScrollView] verticalScroller] isEnabled];
  if([[self enclosingScrollView] hasHorizontalScroller])
    saveHorizontalScrollerEnabled = 
         [[[self enclosingScrollView] horizontalScroller] isEnabled];
}


- (void)setEnabled:(BOOL)bEnable
{
  NSEnumerator *ec;
  NSEnumerator *etc = nil, *ebc = nil;
  NSTableColumn *curColumn;
  NSColor *textColor = nil, *backgroundColor = nil;

  if([self isEnabled] == bEnable) return;

  [super setEnabled:bEnable];
  ec = [[self tableColumns] objectEnumerator];

  if(!bEnable) {
    [self saveState];
    textColor = [NSColor colorWithCalibratedWhite:0.50 alpha:1.0];
    backgroundColor = [NSColor colorWithCalibratedWhite:0.94 alpha:1.0];
  }
  else {
    etc = [saveTextColors objectEnumerator];
    ebc = [saveBackgroundColors objectEnumerator];
  }

  while ((curColumn = [ec nextObject])) {
    if([[curColumn dataCell] isKindOfClass:[NSTextFieldCell class]]) {
      if(bEnable && etc && ebc) {
        textColor = [etc nextObject];
        backgroundColor = [ebc nextObject];
      }
      if(textColor)
        [[curColumn dataCell] setTextColor:textColor];
      if(backgroundColor)
        [[curColumn dataCell] setBackgroundColor:backgroundColor];
    }
  }

  if([[self enclosingScrollView] hasVerticalScroller])
    [[[self enclosingScrollView] verticalScroller] 
                 setEnabled:(bEnable && saveVerticalScrollerEnabled)];

  if([[self enclosingScrollView] hasHorizontalScroller])
    [[[self enclosingScrollView] horizontalScroller] 
                setEnabled:(bEnable && saveHorizontalScrollerEnabled)];

  [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)event
{
	if ([self isEnabled]) {
		[super mouseDown:event];
	}
}

- (void)mouseDragged:(NSEvent *)event
{
	if ([self isEnabled]) {
		[super mouseDragged:event];
	}
}

- (void)mouseUp:(NSEvent *)event
{
	if ([self isEnabled]) {
		[super mouseUp:event];
	}
}

@end

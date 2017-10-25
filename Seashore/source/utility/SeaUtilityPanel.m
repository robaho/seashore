#import "SeaUtilityPanel.h"

@implementation SeaUtilityPanel

- (void)awakeFromNib
{
	[self setDelegate:self];
}

- (BOOL)canBecomeKeyWindow
{
	return NO;
}

- (BOOL)canBecomeMainWindow
{
	return NO;
}

- (IBAction)shade:(id)sender
{
	NSRect frame;
	
	frame = [self frame];
	if (frame.size.height == 16) {
		frame.origin.y -= priorShadeHeight - 16;
		frame.size.height = priorShadeHeight;
		[self setFrame:frame display:YES animate:YES];
		[self setContentView:priorContentView];
		[priorContentView autorelease];
	}
	else {
		priorShadeHeight = frame.size.height;
		frame.origin.y += frame.size.height - 16;
		frame.size.height = 16;
		priorContentView = [self contentView];
		[priorContentView retain];
		if (nullView) [self setContentView:nullView];
		[self setFrame:frame display:YES animate:NO];
	}
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender
{
	return [gCurrentDocument undoManager];
}

- (void)saveFrameUsingName:(NSString *)name
{
	NSRect frame;
	
	frame = [self frame];
	if (frame.size.height != 16) {
		[super saveFrameUsingName:name];
	}
}

- (void)miniaturize:(id)sender
{
	[self shade:sender];
}

- (BOOL)isMiniaturized
{
	return NO;
}

@end

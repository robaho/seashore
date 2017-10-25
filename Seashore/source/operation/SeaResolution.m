#import "SeaResolution.h"
#import "SeaDocument.h"
#import "SeaView.h"
#import "SeaScale.h"
#import "SeaContent.h"
#import "SeaHelpers.h"
#import "SeaSelection.h"
#import "SeaWarning.h"
#import "SeaController.h"

extern IntPoint gScreenResolution;

@implementation SeaResolution

- (void)run
{
	id contents = [document contents];
	
	// Set the text fields correctly
	[xValue setIntValue:(int)[contents xres]];
	[yValue setIntValue:(int)[contents yres]];
	if ([contents xres] == [contents yres]) {
		[yValue setEnabled:NO];
		[forceSquare setState:NSOnState];
	}
	else {
		[yValue setEnabled:YES];
		[forceSquare setState:NSOffState];
	}
	
	// Set the options correctly
	[preserveSize setState:NSOffState];
	
	// Show the sheet
	[NSApp beginSheet:sheet modalForWindow:[document window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)apply:(id)sender
{
	id contents = [document contents];
	IntResolution newRes;
	
	// Get the values
	newRes.x = [xValue intValue];
	newRes.y = [yValue intValue];
	
	// End the sheet
	[NSApp stopModal];
	[NSApp endSheet:sheet];
	[sheet orderOut:self];
	
	// Don't do if values are unreasonable or unchanged
	if ([forceSquare state]) newRes.y = newRes.x;
	if (newRes.x < 9) { NSBeep(); return; }
	if (newRes.y < 9) { NSBeep(); return; }
	if (newRes.x > 73728) { NSBeep(); return; }
	if (newRes.y > 73728) { NSBeep(); return; }
	if (newRes.x == [contents xres] && newRes.y == [contents yres]) { return; }
	if (gScreenResolution.x == 0 || gScreenResolution.y == 0) {
		[[SeaController seaWarning] addMessage:LOCALSTR(@"resolution no effect message", @"The resolution of this image has been changed and this will affect printing and saving. However this will not affect the viewing window because your Preferences are set to ignore image resolution.") forDocument: document level:kModerateImportance];
	}
	
	// Make the changes
	if ([preserveSize state]) [seaScale scaleToWidth:[(SeaContent *)contents width] * ((float)newRes.x / (float)[contents xres]) height:[(SeaContent *)contents height] * ((float)newRes.y / (float)[contents yres]) interpolation:GIMP_INTERPOLATION_CUBIC index:kAllLayers];
	[self setResolution:newRes];
}

- (IBAction)cancel:(id)sender
{
	[NSApp stopModal];
	[NSApp endSheet:sheet];
	[sheet orderOut:self];
}

- (void)setResolution:(IntResolution)newRes
{
	IntResolution oldRes;
	
	// Allow the undo/redo
	oldRes.x = [[document contents] xres];
	oldRes.y = [[document contents] yres];
	[[[document undoManager] prepareWithInvocationTarget:self] setResolution:oldRes];
	
	// Change the resolution
	[[document contents] setResolution:newRes];
	
	// Inform the helpers
	[[document helpers] resolutionChanged];
}

- (IBAction)toggleForceSquare:(id)sender
{
	[yValue setStringValue:[xValue stringValue]];
	if ([forceSquare state])
		[yValue setEnabled:NO];
	else
		[yValue setEnabled:YES];
}

- (IBAction)togglePreserveSize:(id)sender
{
}

- (IBAction)xValueChanged:(id)sender
{
	if ([forceSquare state]) [yValue setStringValue:[xValue stringValue]];
}

@end

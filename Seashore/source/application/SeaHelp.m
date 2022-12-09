#import "SeaHelp.h"

@implementation SeaHelp

- (IBAction)openHelp:(id)sender
{	
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"Seashore Guide" ofType:@"pdf"]];
}

- (IBAction)openEffectsHelp:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"Seashore Effects Guide" ofType:@"pdf"]];
}

- (IBAction)reportAProblem:(id)sender {
     NSURL * problem_url = [NSURL URLWithString:@"https://github.com/robaho/seashore/issues/new"];
     [[NSWorkspace sharedWorkspace] openURL:problem_url];
}

- (void)displayInstantHelp:(int)stringID
{
	NSArray *instantHelpArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Instant" ofType:@"plist"]];
	
	if (stringID >= 0 && stringID < [instantHelpArray count]) {
		[instantHelpLabel setStringValue:[instantHelpArray objectAtIndex:stringID]];
		[instantHelpWindow orderFront:self];
	}
}

- (void)updateInstantHelp:(int)stringID
{
	NSArray *instantHelpArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Instant" ofType:@"plist"]];
	
	if (stringID >= 0 && stringID < [instantHelpArray count] && [instantHelpWindow isVisible]) {
		[instantHelpLabel setStringValue:[instantHelpArray objectAtIndex:stringID]];
	}
}

@end

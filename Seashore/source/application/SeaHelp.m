#import "SeaHelp.h"

@implementation SeaHelp

- (IBAction)goEmail:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:cedarsx@gmail.com?subject=Seashore%20Comment"]];
}

- (IBAction)goSourceForge:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://sourceforge.net/projects/seashore/"]];
}

- (IBAction)goWebsite:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://seashore.sourceforge.net/"]];
}

- (IBAction)goSurvey:(id)sender
{
	NSString *url = [NSString stringWithFormat:@"http://seashore.sourceforge.net/survey.php?version=%@" , [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleVersion"]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (IBAction)openBugs:(id)sender
{
	NSString *url = [NSString stringWithFormat:@"http://seashore.sourceforge.net/quick.php?version=%@" , [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleVersion"]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (IBAction)openHelp:(id)sender
{	
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"Seashore Guide" ofType:@"pdf"]];
}


- (IBAction)openEffectsHelp:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"Seashore Effects Guide" ofType:@"pdf"]];
}

- (void)URL:(NSURL *)sender resourceDataDidBecomeAvailable:(NSData *)newBytes {}
- (void)URLResourceDidCancelLoading:(NSURL *)sender {}
- (void)URL:(NSURL *)sender resourceDidFailLoadingWithReason:(NSString *)reason {}

- (void)URLResourceDidFinishLoading:(NSURL *)sender
{
	NSURL *download_url;
	NSDictionary *dict;
	int newest_version;
	int installed_version = (int)[[[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleVersion"] intValue];
	
	dict = [NSDictionary dictionaryWithContentsOfURL:sender];
	if (dict) {
		newest_version = [[dict objectForKey:@"current version"] intValue];
		if (newest_version > installed_version) {
			download_url = [NSURL URLWithString:[dict objectForKey:@"url"]];
			if (NSRunAlertPanel(LOCALSTR(@"download available title", @"Update available"), LOCALSTR(@"download available body", @"An updated version of Seashore is now availble for download."), LOCALSTR(@"download now", @"Download now"), LOCALSTR(@"download later", @"Download later"), NULL) == NSAlertDefaultReturn) {
				[[NSWorkspace sharedWorkspace] openURL:download_url];
			}
		}
		else {
			if (adviseFailure)
				NSRunAlertPanel(LOCALSTR(@"up-to-date title", @"Seashore up-to-date"), LOCALSTR(@"up-to-date body", @"Seashore is up-to-date."), LOCALSTR(@"ok", @"OK"), NULL, NULL);				
		}
	}
	else {
		if (adviseFailure)
			NSRunAlertPanel(LOCALSTR(@"download error title", @"Download error"), LOCALSTR(@"download error body", @"The file required to check if Seashore cannot be downloaded from the Internet. Please check your Internet connection and try again."), LOCALSTR(@"ok", @"OK"), NULL, NULL);
	}	
}

- (IBAction)checkForUpdate:(id)sender
{
	NSURL *check_url;
	
	check_url = [NSURL URLWithString:@"http://seashore.sourceforge.net/current.xml"];
	adviseFailure = (sender != NULL);
	[check_url loadResourceDataNotifyingClient:self usingCache:YES];
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

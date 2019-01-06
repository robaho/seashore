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


- (IBAction)checkForUpdate:(id)sender
{
	NSURL *check_url;
	
	check_url = [NSURL URLWithString:@"http://seashore.sourceforge.net/current.xml"];
	adviseFailure = (sender != NULL);
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:check_url];
    
    [NSURLConnection sendAsynchronousRequest:(NSURLRequest *)request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data,
                                               NSError *error) {
                               
                               NSURL *download_url;
                               NSDictionary *dict;
                               int newest_version;
                               int installed_version = (int)[[[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleVersion"] intValue];
                               
                               dict = [NSDictionary dictionaryWithContentsOfURL:[response URL]];
                               if (dict) {
                                   newest_version = [[dict objectForKey:@"current version"] intValue];
                                   if (newest_version > installed_version) {
                                       download_url = [NSURL URLWithString:[dict objectForKey:@"url"]];
                                       if (NSRunAlertPanel(LOCALSTR(@"download available title", @"Update available"), @"%@", LOCALSTR(@"download available body", @"An updated version of Seashore is now availble for download."), LOCALSTR(@"download now", @"Download now"), LOCALSTR(@"download later", @"Download later"), NULL) == NSAlertDefaultReturn) {
                                           [[NSWorkspace sharedWorkspace] openURL:download_url];
                                       }
                                   }
                                   else {
                                       if (self->adviseFailure)
                                           NSRunAlertPanel(LOCALSTR(@"up-to-date title", @"Seashore up-to-date"), @"%@", LOCALSTR(@"up-to-date body", @"Seashore is up-to-date."), LOCALSTR(@"ok", @"OK"), NULL, NULL);
                                   }
                               }
                               else {
                                   if (self->adviseFailure)
                                       NSRunAlertPanel(LOCALSTR(@"download error title", @"Download error"), @"%@", LOCALSTR(@"download error body", @"The file required to check if Seashore cannot be downloaded from the Internet. Please check your Internet connection and try again."), LOCALSTR(@"ok", @"OK"), NULL, NULL);
                               }

                                
                            }];
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

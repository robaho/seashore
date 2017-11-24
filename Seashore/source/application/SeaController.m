#import "SeaController.h"
#import "UtilitiesManager.h"
#import "SeaBrush.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "SeaSelection.h"
#import "SeaWarning.h"
#import "SeaPrefs.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaDocumentController.h"

id seaController;

@implementation SeaController

- (id)init
{
	// Remember ourselves
	seaController = self;
	
	// Creates an array which can store objects that wish to recieve the terminate: message
	terminationObjects = [[NSArray alloc] init];
	
	// Specify ourselves as NSApp's delegate
    [NSApp setDelegate:seaController];

	// We want to know when ColorSync changes
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(colorSyncChanged:) name:@"AppleColorSyncPreferencesChangedNotification" object:NULL];
	
	return self;
}

- (void)dealloc
{
	if (terminationObjects) [terminationObjects autorelease];
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSString *crashReport = [NSString stringWithFormat:@"%@/Library/Logs/CrashReporter/Seashore.crash.log", NSHomeDirectory()];
	NSString *trashedReport = [NSString stringWithFormat:@"%@/.Trash/Seashore.crash.log", NSHomeDirectory()];

	// Run initial tests
	if ([seaPrefs firstRun] && [gFileManager fileExistsAtPath:crashReport]) {
		if ([gFileManager movePath:crashReport toPath:trashedReport handler:NULL]) {
			[seaWarning addMessage:LOCALSTR(@"old crash report message", @"Seashore has moved its old crash report to the Trash so that it will be deleted next time you empty the trash.") level:kModerateImportance];
		}
	}
	/*
	[seaWarning addMessage:LOCALSTR(@"beta message", @"Seashore is still under development and may contain bugs. Please make sure to only work on copies of images as there is the potential for corruption. Also please report any bugs you find.") level:[seaPrefs firstRun] ? kHighImportance : kVeryLowImportance];
	*/
	
	// Check run count
	/*
	if ([seaPrefs runCount] == 25) {
		if (NSRunAlertPanel(LOCALSTR(@"feedback survey title", @"Seashore Feedback Survey"), LOCALSTR(@"feedback survey body", @"In order to improve the next release of Seashore we are asking users to participate in a survey. The survey is only one page long and can be accessed by clicking the \"Run Survey\" button. This message should not trouble you again."), LOCALSTR(@"feedback survey button", @"Run Survey"), LOCALSTR(@"cancel", @"Cancel"), NULL) == NSAlertDefaultReturn) {
			[seaHelp goSurvey:NULL];
		}
	}
	*/
	
	// Check for update
	if ([seaPrefs checkForUpdates]) {
		[seaHelp checkForUpdate:NULL];
	}
}

- (id)utilitiesManager
{
	return utilitiesManager;
}

- (id)seaPlugins
{
	return seaPlugins;
}

- (id)seaPrefs
{
	return seaPrefs;
}

- (id)seaProxy
{
	return seaProxy;
}

- (id)seaHelp
{
	return seaHelp;
}

- (id)seaWarning
{
	return seaWarning;
}

+ (id)utilitiesManager
{
	return [seaController utilitiesManager];
}

+ (id)seaPlugins
{
	return [seaController seaPlugins];
}

+ (id)seaPrefs
{
	return [seaController seaPrefs];
}

+ (id)seaProxy
{
	return [seaController seaProxy];
}

+ (id)seaHelp
{
	return [seaController seaHelp];
}

+ (id)seaWarning
{
	return [seaController seaWarning];
}

- (IBAction)revert:(id)sender
{
	id newDocument;
	NSString *filename = [gCurrentDocument fileName];
	NSRect frame = [[[[gCurrentDocument windowControllers] objectAtIndex:0] window] frame];
	id window;
	
	// Question whether to proceed with reverting
	if (NSRunAlertPanel(LOCALSTR(@"revert title", @"Revert"), [NSString stringWithFormat:LOCALSTR(@"revert body", @"\"%@\" has been edited. Are you sure you want to undo changes?"), [gCurrentDocument displayName]], LOCALSTR(@"revert", @"Revert"), LOCALSTR(@"cancel", @"Cancel"), NULL) == NSAlertDefaultReturn) {
		
		// Close the document and reopen it
		[gCurrentDocument close];
		newDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:filename display:NO];
		window = [[[newDocument windowControllers] objectAtIndex:0] window];
		[window setFrame:frame display:YES];
		[window makeKeyAndOrderFront:self];		

	}
}

- (IBAction)editLastSaved:(id)sender
{
	id originalDocument, currentDocument = gCurrentDocument;
	NSString *old_path = [currentDocument fileName], *new_path = NULL;
	int i;
	BOOL done;
	
	// Find a unique new name
	done = NO;
	for (i = 1; i <= 64 && !done; i++) {
		if (i == 1) {
			new_path = [[old_path stringByDeletingPathExtension] stringByAppendingFormat:@" (Original).%@", [old_path pathExtension]];
			if ([gFileManager fileExistsAtPath:new_path] == NO) {
				done = YES;
			}
		}
		else {
			new_path = [[old_path stringByDeletingPathExtension] stringByAppendingFormat:@" (Original %d).%@", i, [old_path pathExtension]];
			if ([gFileManager fileExistsAtPath:new_path] == NO) {
				done = YES;
			}
		}
	}
	if (!done) {
		NSLog(@"Can't find suitable filename (last tried: %@)", new_path);
		return;
	}
	
	// Copy the contents on disk and open so the last saved version can be edited
	if ([gFileManager copyPath:old_path toPath:new_path handler:nil]) {
		originalDocument = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] openNonCurrentFile:new_path];
	}
	else {
		NSRunAlertPanel(LOCALSTR(@"locked title", @"Operation Failed"), [NSString stringWithFormat:LOCALSTR(@"locked body", @"The \"Compare to Last Saved\" operation failed. The most likely cause for this is that the disk the original is kept on is full or read-only."), [gCurrentDocument displayName]], LOCALSTR(@"ok", @"OK"), NULL, NULL);
		return;
	}
	
	// Finally remove the file we just created
	[gFileManager removeFileAtPath:new_path handler:NULL];
}

- (void)colorSyncChanged:(NSNotification *)notification
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	// Tell all documents to update there colour worlds
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] whiteboard] updateColorWorld];
	}
}

- (IBAction)showLicense:(id)sender
{
	[licenseWindow setLevel:NSFloatingWindowLevel];
	[licenseWindow makeKeyAndOrderFront:self];
}

- (IBAction)newDocumentFromPasteboard:(id)sender
{
	NSDocument *document;
	
	// Ensure that the document is valid
	if(![[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NSPICTPboardType, NULL]]){
		NSBeep();
		return;
	}
	
	// We can now create the new document
	document = [[SeaDocument alloc] initWithPasteboard];
	[[NSDocumentController sharedDocumentController] addDocument:document];
	[document makeWindowControllers];
	[document showWindows];
	[document autorelease];
}

- (void)registerForTermination:(id)object
{
	[terminationObjects autorelease];
	terminationObjects = [[terminationObjects arrayByAddingObject:object] retain];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	int i;
	
	// Inform those that wish to know
	for (i = 0; i < [terminationObjects count]; i++)
		[[terminationObjects objectAtIndex:i] terminate];
	
	// Save the changes in preferences
	[gUserDefaults synchronize];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return NO;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)application
{
    return NSTerminateNow;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)app
{
	return [seaPrefs openUntitled];
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)app
{
	[[NSDocumentController sharedDocumentController] newDocument:self];
	
	return YES;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	id availableType;
	
	switch ([menuItem tag]) {
		case 175:
			return gCurrentDocument && [gCurrentDocument fileName] && [gCurrentDocument isDocumentEdited] && [gCurrentDocument current];
		break;
		case 176:
			return gCurrentDocument && [gCurrentDocument fileName] && [gCurrentDocument current];
		break;
		case 400:
			availableType = [[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NSPICTPboardType, NULL]];
			if (availableType)
				return YES;
			else
				return NO;
		break;
	}
	
	return YES;
}

+ (id)seaController
{
	return seaController;
}

@end

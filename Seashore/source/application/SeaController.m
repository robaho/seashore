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
	
	return self;
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
	
	// Check for update
	if ([seaPrefs checkForUpdates]) {
		[seaHelp checkForUpdate:NULL];
	}
}

- (UtilitiesManager*)utilitiesManager
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

+ (UtilitiesManager*)utilitiesManager
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
    id currentDocument = gCurrentDocument;
    [[NSDocumentController sharedDocumentController] openNonCurrentFile:[currentDocument fileName]];
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
}

- (void)registerForTermination:(id)object
{
    terminationObjects = [terminationObjects arrayByAddingObject:object];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	int i;
	
	// Inform those that wish to know
    for (i = 0; i < [terminationObjects count]; i++) {
        id<SeaTerminate> t = [terminationObjects objectAtIndex:i];
		[t terminate];
    }
	
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

#import "SeaController.h"
#import "SeaBrush.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "SeaSelection.h"
#import "SeaSupport.h"
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

- (id)seaSupport
{
    return seaSupport;
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

+ (id)seaSupport
{
    return [seaController seaSupport];
}

- (IBAction)revert:(id)sender
{
	SeaDocument *newDocument;
	NSString *filename = [gCurrentDocument fileName];
	NSRect frame = [[[[gCurrentDocument windowControllers] objectAtIndex:0] window] frame];
	id window;
	
	// Question whether to proceed with reverting
	if (NSRunAlertPanel(LOCALSTR(@"revert title", @"Revert"), [NSString stringWithFormat:LOCALSTR(@"revert body", @"\"%@\" has been edited. Are you sure you want to undo changes?"), [gCurrentDocument displayName]], LOCALSTR(@"revert", @"Revert"), LOCALSTR(@"cancel", @"Cancel"), NULL) == NSAlertDefaultReturn) {
		
		// Close the document and reopen it
		[gCurrentDocument close];
		newDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:filename display:NO];
		window = [[[newDocument windowControllers] objectAtIndex:0] window];
		[window setFrame:frame display:NO];
		[window makeKeyAndOrderFront:self];

        if([[SeaController seaPrefs] zoomToFitAtOpen]) {
            [[newDocument docView] zoomToFit:self];
        }

        [window setIsVisible:YES];
	}
}

- (IBAction)editLastSaved:(id)sender
{
    id currentDocument = gCurrentDocument;
    SeaDocument *lastDocument = [[NSDocumentController sharedDocumentController] openNonCurrentFile:[currentDocument fileName]];
    if(!lastDocument)
        return;
    // show documents side by side
    NSRect screen = [[[[currentDocument docView] window] screen] frame];
    NSRect currentFrame = [[[currentDocument docView] window] frame];
    
    currentFrame.size.width = screen.size.width/2;
    currentFrame.origin.x = screen.origin.x;
    
    NSRect lastFrame = NSMakeRect(currentFrame.origin.x+currentFrame.size.width+1,currentFrame.origin.y,currentFrame.size.width-1,currentFrame.size.height);
    [[[currentDocument docView] window] setFrame:currentFrame display:NO];
    [[[lastDocument docView] window] setFrame:lastFrame display:NO];

    if([[SeaController seaPrefs] zoomToFitAtOpen]) {
        [[currentDocument docView] zoomToFit:self];
        [[lastDocument docView] zoomToFit:self];
    }

    [[[currentDocument docView] window] setIsVisible:YES];
    [[[lastDocument docView] window] setIsVisible:YES];
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
	if(![[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NSURLPboardType, NSStringPboardType, NULL]]){
		NSBeep();
		return;
	}
	
	// We can now create the new document
	document = [[SeaDocument alloc] initWithPasteboard];
    if(!document){
        NSAlert *alert = [NSAlert alertWithMessageText:@"Unsupported pasteboard format." defaultButton:@"OK" alternateButton:NULL otherButton:NULL informativeTextWithFormat:@"Unsupported pasteboard format."];
        [alert runModal];
        return;
    }
    
	[[NSDocumentController sharedDocumentController] addDocument:document];
	[document makeWindowControllers];
	[document showWindows];
}

- (void)registerForTermination:(id<SeaTerminate>)object
{
    terminationObjects = [terminationObjects arrayByAddingObject:object];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [gUserDefaults setBool:[gColorPanel isVisible] forKey:@"colorpanel visible"];

    for (id<SeaTerminate> t in terminationObjects) {
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
			return gCurrentDocument && [gCurrentDocument fileName] && [gCurrentDocument isDocumentEdited];
		break;
		case 176:
			return gCurrentDocument && [gCurrentDocument fileName];
		break;
		case 400:
			availableType = [[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NSURLPboardType, NULL]];
			if (availableType)
				return YES;
            else {
                NSString *string = [[NSPasteboard generalPasteboard] stringForType:NSStringPboardType];
                if(string!=NULL && [string hasPrefix:@"<svg"]) return YES;
                return NO;
            }
		break;
	}
	
	return YES;
}

+ (id)seaController
{
	return seaController;
}

@end

/*
	UpdaterObject.m

	Copyright (c) 2002 Mark Pazolli
	Distributed under the terms of the MIT License
*/

// The following may be of help in constructing the updater
// diff -r --brief NewApp.app OldApp.app | grep -E -v '.DS_Store|OtherFileWeDontCareAbout' > differences.txt

#import "UpdaterObject.h"

@implementation UpdaterObject

#define kApplicationName "Seashore"
#define kLatestVersionString "0.1.8p2"
#define kApplicationWebsite "http://seashore.sourceforge.net/"
#define kUpdateMessage "This version attempts to fix TIFF exporting on Intel machines."

- (id)init
{
	// Specify ourselves as NSApp's delegate
	[NSApp setDelegate:self];
	
	return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	// Runs the update
	[self updateSeashore:self];
}

- (IBAction)updateSeashore:(id)sender
{
	NSOpenPanel *openPanel;
	NSString *tempString, *versionString, *sourcePathPrefix, *destPathPrefix, *currentFileString;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSFileWrapper *currentFile;
	NSDirectoryEnumerator *sourceDirectory;
	NSArray *tempArray, *removeFilesArray;
	BOOL isDirectory;
	int i;
	
	// Ask user to select destination
	openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:NO];
	if ([openPanel runModalForDirectory:@"/Applications/" file:[NSString stringWithFormat:@"%s.app", kApplicationName] types:[NSArray arrayWithObject:@"app"]] == NSOKButton) {
		
		// Determine the destPathPrefix
		destPathPrefix = [[openPanel filenames] objectAtIndex:0];
		
		// Abort if bundle's name is not equivalent to kApplicationName
		tempString = [[NSDictionary dictionaryWithContentsOfFile:[destPathPrefix stringByAppendingString:@"/Contents/Info.plist"]] objectForKey:@"CFBundleName"];
		if (![tempString isEqualToString:[NSString stringWithCString:kApplicationName]]) {
			NSRunAlertPanel(@"Update Not Possible", [NSString stringWithFormat:@"The application you have selected does not appear to be a version of %s. This update will abort.", kApplicationName], @"Ok", NULL, NULL);
			return;
		}
		
		// Abort if version is already up-to-date
		versionString = [[NSDictionary dictionaryWithContentsOfFile:[destPathPrefix stringByAppendingString:@"/Contents/Info.plist"]] objectForKey:@"CFBundleShortVersionString"];
		if ([versionString isEqualToString:@"0.1.8p1"]) {
			versionString = @"0.1.8";
		}
		if ([versionString isEqualToString:[NSString stringWithCString:kLatestVersionString]]) {
			NSRunAlertPanel(@"Update Already Implemented", [NSString stringWithFormat:@"The version of %s you selected is already up-to-date. This update will abort.", kApplicationName], @"Ok", NULL, NULL);
			return;
		}
		
		// Check if we have an update for that version
		tempArray = [fileManager directoryContentsAtPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources"]];
		if (![tempArray containsObject:versionString]) {
			if (NSRunAlertPanel(@"Update Not Available", [NSString stringWithFormat:@"The version of %s you have selected cannot be updated by this updater. It is suggested you update manually at %s. This update will abort.", kApplicationName, kApplicationWebsite], @"Ok", @"Visit Site", NULL) == NSAlertAlternateReturn) {
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithCString:kApplicationWebsite]]];
			}
			return;
		}
		sourcePathPrefix = [[[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"] stringByAppendingString:versionString];
	
		// Now add the '/' on
		sourcePathPrefix = [sourcePathPrefix stringByAppendingString:@"/"];
		destPathPrefix = [destPathPrefix stringByAppendingString:@"/"];
	
		// Remove any files that the developer requests be removed
		removeFilesArray = [NSArray arrayWithContentsOfFile:[[[sourcePathPrefix stringByAppendingString:@"../"] stringByAppendingString:versionString] stringByAppendingString:@".del.plist"]];
		if (removeFilesArray != NULL) {
			for (i = 0; i < [removeFilesArray count]; i++) {
				[fileManager removeFileAtPath:[destPathPrefix stringByAppendingString:[removeFilesArray objectAtIndex:i]] handler:nil];
			}
		}
		
		// Commence the update
		sourceDirectory = [fileManager enumeratorAtPath:sourcePathPrefix];
		while (currentFileString = [sourceDirectory nextObject]) {
		
			// Ignore the .DS_Store files
			if (![[currentFileString lastPathComponent] isEqualToString:@".DS_Store"]) {
			
				// Check if this is a framework
				if ([currentFileString rangeOfString:@".framework"].length > 0) {
					if ([currentFileString hasSuffix:@".framework"]) {
					
						// Replace framework
						[fileManager removeFileAtPath:[destPathPrefix stringByAppendingString:currentFileString] handler:nil];
						[fileManager copyPath:[sourcePathPrefix stringByAppendingString:currentFileString] toPath:[destPathPrefix stringByAppendingString:currentFileString] handler:nil];
					
					}
				}
				else {
				
					// Determine if there is a directory at the source
					[fileManager fileExistsAtPath:[sourcePathPrefix stringByAppendingString:currentFileString] isDirectory:&isDirectory];
					if (isDirectory) {
						
						// Determine if there is a directory at the destination and if not create one
						if (![fileManager fileExistsAtPath:[destPathPrefix stringByAppendingString:currentFileString]])
							[fileManager createDirectoryAtPath:[destPathPrefix stringByAppendingString:currentFileString] attributes:NULL];
					
					}
					else {
						
						// If not a directory we can simply copy across
						currentFile = [[NSFileWrapper alloc] initWithPath:[sourcePathPrefix stringByAppendingString:currentFileString]];
						[currentFile writeToFile:[destPathPrefix stringByAppendingString:currentFileString] atomically:YES updateFilenames:NO];
						
					}
				
				}
				
			}
			
		}
		
		// State that the update was successful
		NSRunAlertPanel(@"Update Completed", [NSString stringWithFormat:@"The selected version of %s has now been updated to %s. %s", kApplicationName, kLatestVersionString, kUpdateMessage], @"Ok", NULL, NULL);
		
		// Quit after finishing
		if (sender == self)
			[NSApp terminate:NULL];
		
	}
}

@end

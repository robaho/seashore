/*
	InstallerObject.m

	Copyright (c) 2002-2005 Mark Pazolli
	Distributed under the terms of the MIT License
*/

#import "InstallerObject.h"

@implementation InstallerObject

- (id)init
{
	// Specify ourselves as NSApp's delegate
	[NSApp setDelegate:self];
	
	return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	// Runs the update
	[self install:self];
}

- (IBAction)install:(id)sender
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSOpenPanel *openPanel;
	NSMutableDictionary *infoDict;
	NSDictionary *svgDict;
	NSString *value, *destPath;
	NSMutableArray *array;
	NSArray *objectArray, *keyArray;
	NSTask *task;
	BOOL success;
	int i;
	
	// Ask user to select destination
	openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:NO];
	if ([openPanel runModalForDirectory:@"/Applications/" file:@"Seashore.app" types:[NSArray arrayWithObject:@"app"]] == NSOKButton) {
	
		// Determine the destination path
		destPath = [[openPanel filenames] objectAtIndex:0];
	
		// Open the Info.plist dictionary
		infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:[destPath stringByAppendingString:@"/Contents/Info.plist"]];
		
		// Check application
		value = [infoDict objectForKey:@"CFBundleExecutable"];
		if (![value isEqualToString:@"Seashore"]) {
			NSRunAlertPanel(@"Installation failed", @"The application you have selected does not appear to be Seashore. As a result, the installation cannot take place.", @"Ok", NULL, NULL);
			return;
		}
		
		// Check version
		value = [infoDict objectForKey:@"CFBundleShortVersionString"];
		if ([value characterAtIndex:0] == '0' && [value characterAtIndex:2] < '1' && [value characterAtIndex:4] < '6') {
			NSRunAlertPanel(@"Installation failed", @"This installer is only designed to work with Seashore 0.1.6 or later. As a result, the installation cannot take place.", @"Ok", NULL, NULL);
			return;
		}
		
		// Check presence
		array = [NSMutableArray arrayWithArray:[infoDict objectForKey:@"CFBundleDocumentTypes"]];
		success = YES;
		for (i = 0; i < [array count]; i++) {
			value = [[array objectAtIndex:i] objectForKey:@"CFBundleTypeName"];
			if ([value isEqualToString:@"SVG Document"]) {
				success = NO;
			}
		}
		if (!success) {
			NSRunAlertPanel(@"Installation finished", @"This installer found the SVG Importer present in this version of Seashore. As a result, no changes were made. If this is an old version of the importer you can remove it through the File menu.", @"Ok", NULL, NULL);
			return;
		}
		
		// Revise Info.plist
		objectArray = [NSArray arrayWithObjects:[NSArray arrayWithObjects:@"svg", @"SVG", NULL], @"SVG Icon.icns", @"SVG Document", @"Viewer", @"SeaDocument", NULL];
		keyArray = [NSArray arrayWithObjects:@"CFBundleTypeExtensions", @"CFBundleTypeIconFile", @"CFBundleTypeName", @"CFBundleTypeRole", @"NSDocumentClass", NULL];
		svgDict = [NSDictionary dictionaryWithObjects:objectArray forKeys:keyArray];
		[array insertObject:svgDict atIndex:[array count]];
		[infoDict setObject:array forKey:@"CFBundleDocumentTypes"];
		if (![infoDict writeToFile:[destPath stringByAppendingString:@"/Contents/Info.plist"] atomically:YES]) {
			NSRunAlertPanel(@"Installation failed", @"The installer was unable to replace \"Info.plist\" file - perhaps because Seashore is a read-only volume. As a result, the installation did not take place.", @"Ok", NULL, NULL);
			return;
		}
		
		// Add files
		success = YES;
		if (success) {
			success = success && [fileManager copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/SVG Icon.icns"] toPath:[destPath stringByAppendingString:@"/Contents/Resources/SVG Icon.icns"] handler:NULL];
			success = success && [fileManager createDirectoryAtPath:[destPath stringByAppendingString:@"/Contents/PlugIns/SVGImporter.app"] attributes:NULL];
			success = success && [fileManager createDirectoryAtPath:[destPath stringByAppendingString:@"/Contents/PlugIns/SVGImporter.app/Contents"] attributes:NULL];
			success = success && [fileManager createDirectoryAtPath:[destPath stringByAppendingString:@"/Contents/PlugIns/SVGImporter.app/Contents/MacOS"] attributes:NULL];
			success = success && [fileManager copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/SVGCairoImporter"] toPath:[destPath stringByAppendingString:@"/Contents/PlugIns/SVGImporter.app/Contents/MacOS/SVGImporter"] handler:NULL];
		}
		if (!success) {
			NSRunAlertPanel(@"Installation failed", @"The installer was unable to add some files and complete the installation. As a result, the installation failed and did not complete.", @"Ok", NULL, NULL);
			return;
		}
		
		// Instruct the computer to revise its knowledge of applications
		task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/touch" arguments:[NSArray arrayWithObject:destPath]];
		[task waitUntilExit];
		[[NSWorkspace sharedWorkspace] findApplications];
		
		// State installation as being complete
		NSRunAlertPanel(@"Installation completed", @"The installer successfully installed the SVG Importer for Seashore.", @"Ok", NULL, NULL);
	
		// Quit after finishing
		if (sender == self)
			[NSApp terminate:NULL];
	}
}

- (IBAction)remove:(id)sender
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSOpenPanel *openPanel;
	NSMutableDictionary *infoDict;
	NSDirectoryEnumerator *dir;
	NSString *value, *destPath, *file;
	NSMutableArray *array;
	NSTask *task;
	BOOL success;
	int i;
	
	// Ask user to select destination
	openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:NO];
	if ([openPanel runModalForDirectory:@"/Applications/" file:@"Seashore.app" types:[NSArray arrayWithObject:@"app"]] == NSOKButton) {
	
		// Determine the destination path
		destPath = [[openPanel filenames] objectAtIndex:0];
	
		// Open the Info.plist dictionary
		infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:[destPath stringByAppendingString:@"/Contents/Info.plist"]];
		
		// Check application
		value = [infoDict objectForKey:@"CFBundleExecutable"];
		if (![value isEqualToString:@"Seashore"]) {
			NSRunAlertPanel(@"Removal failed", @"The application you have selected does not appear to be Seashore. As a result, the removal cannot take place.", @"Ok", NULL, NULL);
			return;
		}
		
		// Check version
		value = [infoDict objectForKey:@"CFBundleShortVersionString"];
		if ([value characterAtIndex:0] == '0' && (([value characterAtIndex:2] < '1') || ([value characterAtIndex:2] == '1' && [value characterAtIndex:4] < '6'))) {
			NSRunAlertPanel(@"Removal failed", @"This installer is only designed to work with Seashore 0.1.6 or later. As a result, the removal cannot take place.", @"Ok", NULL, NULL);
			return;
		}
		
		// Check presence
		array = [NSMutableArray arrayWithArray:[infoDict objectForKey:@"CFBundleDocumentTypes"]];
		success = NO;
		for (i = 0; i < [array count]; i++) {
			value = [[array objectAtIndex:i] objectForKey:@"CFBundleTypeName"];
			if ([value isEqualToString:@"SVG Document"]) {
				[array removeObjectAtIndex:i];
				success = YES;
			}
		}
		if (!success) {
			NSRunAlertPanel(@"Removal finished", @"This installer did not find the SVG Importer present in this version of Seashore. As a result, no changes were made.", @"Ok", NULL, NULL);
			return;
		}
		
		// Revise Info.plist
		[infoDict setObject:array forKey:@"CFBundleDocumentTypes"];
		if (![infoDict writeToFile:[destPath stringByAppendingString:@"/Contents/Info.plist"] atomically:YES]) {
			NSRunAlertPanel(@"Removal failed", @"The installer was unable to replace \"Info.plist\" file - perhaps because Seashore is a read-only volume. As a result, the removal did not take place.", @"Ok", NULL, NULL);
			return;
		}
		
		// Delete files
		success = YES;
		if (success) {
			success = success && [fileManager removeFileAtPath:[destPath stringByAppendingString:@"/Contents/Resources/SVG Icon.icns"] handler:NULL];
			dir = [fileManager enumeratorAtPath:[destPath stringByAppendingString:@"/Contents/PlugIns/SVGImporter.app"]];
			array = [NSMutableArray array];
			if (dir) {
				while (file = [dir nextObject]) [array insertObject:file atIndex:0];
				for (i = 0; i < [array count]; i++) {
					success = success && [fileManager removeFileAtPath:[destPath stringByAppendingFormat:@"/Contents/PlugIns/SVGImporter.app/%@", [array objectAtIndex:i]] handler:NULL];
				}
			}
			else
				success = NO;
			success = success && [fileManager removeFileAtPath:[destPath stringByAppendingFormat:@"/Contents/PlugIns/SVGImporter.app"] handler:NULL];
		}
		if (!success) {
			NSRunAlertPanel(@"Removal failed", @"The installer was unable to delete some files and complete the removal. As a result, the removal failed and did not complete.", @"Ok", NULL, NULL);
			return;
		}
		
		// Instruct the computer to revise its knowledge of applications
		task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/touch" arguments:[NSArray arrayWithObject:destPath]];
		[task waitUntilExit];
		[[NSWorkspace sharedWorkspace] findApplications];
		
		// State removal as being complete
		NSRunAlertPanel(@"Removal completed", @"The installer successfully removed the SVG Importer from Seashore.", @"Ok", NULL, NULL);
	}
}

@end

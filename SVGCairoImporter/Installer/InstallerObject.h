/*
	InstallerObject.h

	Copyright (c) 2002-2005 Mark Pazolli
	Distributed under the terms of the MIT License
*/

#import <Cocoa/Cocoa.h>

@interface InstallerObject : NSObject
{
}

// Initialize the object
- (id)init;

// Runs the update
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification;

// Installs the SVG Importer into Seashore
- (IBAction)install:(id)sender;

// Removes the SVG Importer from Seashore
- (IBAction)remove:(id)sender;

@end

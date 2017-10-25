/*
	UpdaterObject.h

	Copyright (c) 2002 Mark Pazolli
	Distributed under the terms of the MIT License
*/

#import <Cocoa/Cocoa.h>

@interface UpdaterObject : NSObject
{
}

// Initialize the object
- (id)init;

// Runs the update
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification;

// Updates Seashore
- (IBAction)updateSeashore:(id)sender;

@end

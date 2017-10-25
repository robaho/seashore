/*
	Brushed 0.8.1
	
	This class handles calls from the main menu of the program,
	often redirecting them to document-based classes.
	
	Copyright (c) 2002 Mark Pazolli
	Distributed under the terms of the GNU General Public License
*/

#import "Globals.h"

@interface BrushedController : NSObject
{
}

// Handle a copy operation
- (IBAction)copy:(id)sender;

// Handle a paste operation
- (IBAction)paste:(id)sender;

// Determine whether a menu item should be enabled or disabled
- (BOOL)validateMenuItem:(id)menuItem;

@end

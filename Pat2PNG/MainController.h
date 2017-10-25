/*
	Pat2Tex 0.8.0

	This class encapsulates the entire functionality of the program,
	which converts the GIMP's ".pat" texture files to PNG image files
	that Seashore uses for its textures.
	
	Copyright (c) 2002 Mark Pazolli
	Distributed under the terms of the GNU General Public License
*/

#import "Globals.h"

@interface MainController : NSObject
{
}

// Run the conversion process
- (IBAction)run:(id)sender;

@end

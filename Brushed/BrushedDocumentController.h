/*
	Brushed 0.8.1
	
	We need to customize the open panel! And Apple says...
	
	"If you need to customize the Open panel, you have encountered 
	one of the clear times when an NSDocumentController subclass is needed. 
	You can override the NSDocumentController’s runModalOpenPanel:forTypes: 
	method to customize the panel or add an accessory view."
	
	Copyright (c) 2002 Mark Pazolli
	Distributed under the terms of the GNU General Public License
*/

#import "Globals.h"

@interface BrushedDocumentController : NSDocumentController
{
}

// Allow customization of the open panel
- (int)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions;

@end

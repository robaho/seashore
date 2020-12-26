/*!
	@header		BlurClass
	@abstract	Blurs the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2004 Mark Pazolli and
				Copyright (c) 1995 Spencer Kimball and Peter Mattis
*/

#import <Cocoa/Cocoa.h>
#import <Plugins/PluginClass.h>
#import "GaussianFuncs.h"

@interface GaussianClass : NSObject <PluginClass> {

	// The plug-in's manager
	PluginData *pluginData;

	// The label displaying the radius of the blur
	IBOutlet id radiusLabel;
	
	// The slider for the radius of the blur
	IBOutlet id radiusSlider;

	// The panel for the plug-in
	IBOutlet id panel;

	// The number of applications
	int radius;

	// YES if the blurring must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;

}
@end

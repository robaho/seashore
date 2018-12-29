/*!
	@header		SharpenClass
	@abstract	Sharpens the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2005 Mark Pazolli and
				Copyright (c) 1997-1998 Michael Sweet
*/

#import <Cocoa/Cocoa.h>
#import <Plugins/PluginClass.h>

@interface SharpenClass : NSObject <PluginClass> {

	// The plug-in's manager
	SeaPlugins *seaPlugins;

	// The label displaying the extent
	IBOutlet id extentLabel;
	
	// The slider for the extent
	IBOutlet id extentSlider;

	// The panel for the plug-in
	IBOutlet id panel;

	// The number of extent
	int extent;

	// YES if the blurring must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;

}

@end

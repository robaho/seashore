/*!
	@header		PosterizeClass
	@abstract	Runs a posterize operation on the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2005 Mark Pazolli
*/

#import <Cocoa/Cocoa.h>
#import <Plugins/PluginClass.h>

@interface PosterizeClass : NSObject <PluginClass> {

	// The plug-in's manager
	PluginData *pluginData;

	// The posterize slider
	IBOutlet id posterizeSlider;
	
	// The posterize label
	IBOutlet id posterizeLabel;

	// The panel for the plug-in
	IBOutlet id panel;

	// The posterize value
	int posterize;

	// YES if the effect must be refreshed
	BOOL refresh;

	// YES if the application succeeded
	BOOL success;

}

@end

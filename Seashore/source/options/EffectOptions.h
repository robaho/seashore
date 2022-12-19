#import "Seashore.h"
#import "AbstractOptions.h"
#import <Plugins/PluginClass.h>
#import <SeaComponents/SeaComponents.h>

/*!
	@class		EffectOptions
	@abstract	Handles the options pane for the effects tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2007 Mark Pazolli
*/

@interface EffectOptions : AbstractOptions {

	// The label showing the number of clicks remaining
	id clickCountLabel;
    // The instruction for those effects
    NSTextField *instructionsLabel;

    id effectsButton;

    id resetButton;
    id applyButton;
    id reapplyButton;
    id detectRectangleButton;

    // holds the view declared by the plugin
    NSView *pluginViewContainer;
    VerticalView *instructionsArea;
    
    id<PluginClass> currentPlugin;
}

/*!
	@method		updateClickCount:
	@discussion	Updates the number of clicks remiaing for the current effect.
	@param		sender
				Ignored.
*/
-(void)updateClickCount:(id)sender;
-(void)installPlugin:(id<PluginClass>)plugin View:(NSView*)view;
-(id<PluginClass>)currentPlugin;

@end

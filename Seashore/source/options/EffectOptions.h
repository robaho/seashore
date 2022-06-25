#import "Seashore.h"
#import "AbstractOptions.h"
#import "PluginClass.h"
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
	// The instruction for those effects
	IBOutlet id effectTableInstruction;
	
	// The label showing the number of clicks remaining
	IBOutlet id clickCountLabel;

    // The label showing the current effect
    IBOutlet id effectsLabel;

    IBOutlet id resetButton;
    IBOutlet id applyButton;
    IBOutlet id reapplyButton;

    // holds the view declared by the plugin
    __weak IBOutlet NSView *pluginViewContainer;

    __weak IBOutlet VerticalView *instructionsArea;
    
    PluginClass *currentPlugin;
}

/*!
	@method		updateClickCount:
	@discussion	Updates the number of clicks remiaing for the current effect.
	@param		sender
				Ignored.
*/
- (IBAction)updateClickCount:(id)sender;

/*!
	@method		showEffects:
	@discussion	Brings the effects panel to the front (it's modal).
	@param		sender
				Ignored.
*/
- (IBAction)showEffects:(id)sender;

-(void)installPlugin:(PluginClass*)plugin View:(NSView*)view;
-(PluginClass*)currentPlugin;

@end

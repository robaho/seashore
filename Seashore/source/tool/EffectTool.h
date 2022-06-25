#import "Seashore.h"
#import "AbstractTool.h"
#import "SeaPlugins.h"
#import "EffectOptions.h"

/*!
	@defined	kMaxEffectToolPoints
	@discussion	Defines the preview size of the brushes in the view.
*/
#define kMaxEffectToolPoints 32

/*!
	@class		EffectTool
	@abstract	The effect tool allows the user to apply certain point-based
				effects to the image.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2007 Mark Pazolli
*/

@interface EffectTool : AbstractTool {
	// The points so far registered
	IntPoint points[kMaxEffectToolPoints];

	// A count of the points so far registered
	int count;
    
    EffectOptions *options;
    
    PluginClass *currentPlugin;
    
    NSView *pluginView;
    
    long lastPointTime;
    
    PluginClass *lastPlugin;
}

/*!
	@method		mouseDownAt:withEvent:
	@discussion	Handles mouse down events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse down event.
*/
- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
    @method        selectEffect
    @param         plugin
                 The newly selected effect/plugin.
    @discussion    Call to select a new effect.
*/
- (void)selectEffect:(PluginClass*)plugin;

/*!
	@method		reset
	@discussion	Reset the effect.
*/
- (void)reset;

/*!
	@method		point:
	@discussion	Returns the given point from the effect tool. Only valid
				for plug-ins with type one.
	@param		index
				An integer from zero to less than the plug-in's specified
				value.
	@result		The corresponding point from the effect tool.
*/
- (IntPoint)point:(int)index;

/*!
	@method		clickCount
	@discussion	Returns the number of clicks thus far.
	@result		Returns an integer indicating the number of clicks thus far.
*/
- (int)clickCount;

/*!
    @method        plugin
    @discussion    returns the current effect or nil.
    @result        returns the current effect or nil.
*/
- (PluginClass*)plugin;

- (void)settingsChanged;

- (IBAction)apply:(id)sender;
- (IBAction)reset:(id)sender;

- (IBAction)reapply:(id)sender;
- (BOOL)hasLastEffect;

-(BOOL)shouldDrawPoints;

@end

#import "EffectOptions.h"
#import "SeaController.h"
#import "SeaPlugins.h"
#import "SeaTools.h"
#import "PluginClass.h"
#import "InfoPanel.h"
#import "EffectTool.h"

@implementation EffectOptions

- (void)awakeFromNib
{
    [self updateClickCount:self];
}

- (void)updateClickCount:(id)sender
{
    EffectTool* tool = (EffectTool*)[[document tools] getTool:kEffectTool];
    if(!currentPlugin) {
        [effectsLabel setStringValue:@"No effect selected."];
//        [effectTableInstruction setHidden:TRUE];
//        [clickCountLabel setHidden:TRUE];
        [instructionsArea setHidden:TRUE];
        if([tool hasLastEffect]){
            [reapplyButton setHidden:FALSE];
        } else {
            [reapplyButton setHidden:TRUE];
        }
        [resetButton setHidden:TRUE];
        [applyButton setHidden:TRUE];
    } else {
        [reapplyButton setHidden:TRUE];
        [applyButton setHidden:FALSE];
        [resetButton setHidden:FALSE];
        [instructionsArea setHidden:FALSE];
        [effectsLabel setStringValue:[currentPlugin name]];
        [effectTableInstruction setStringValue:[currentPlugin instruction]];
        if([currentPlugin points]>0) {
            [clickCountLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"click count", @"Clicks remaining: %d"),
                                             [[tool plugin] points] - [tool clickCount]]];
        }
        [applyButton setEnabled:[currentPlugin points]==[tool clickCount]];
    }
}

- (IBAction)showEffects:(id)sender
{
    NSMenu *menu = [[SeaController seaPlugins] menu];

    [NSMenu popUpContextMenu:menu withEvent:[[NSApplication sharedApplication] currentEvent] forView:(NSButton *)sender];
}

- (void)installPlugin:(PluginClass*)plugin View:(NSView *)view
{
    [pluginViewContainer setSubviews:[NSArray array]];

    if(view) {
        [pluginViewContainer addSubview:view];
    }
    [pluginViewContainer setNeedsLayout:TRUE];

    currentPlugin = plugin;

    [self updateClickCount:self];

    [instructionsArea setNeedsLayout:TRUE];

    NSView *parent = [pluginViewContainer superview];
    [view setNeedsLayout:TRUE];
    [parent setNeedsLayout:TRUE];
    [parent setNeedsDisplay:TRUE];
}

-(PluginClass*)currentPlugin
{
    return currentPlugin;
}

@end

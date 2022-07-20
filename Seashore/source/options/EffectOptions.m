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
        if([currentPlugin respondsToSelector:@selector(instruction)]) {
            [effectTableInstruction setHidden:FALSE];
            [effectTableInstruction setStringValue:[currentPlugin instruction]];
        } else {
            [effectTableInstruction setHidden:TRUE];
        }

        if([currentPlugin points]>0) {
            [clickCountLabel setHidden:FALSE];
            [clickCountLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"click count", @"Clicks remaining: %d"),
                                             [[tool plugin] points] - [tool clickCount]]];
        } else {
            [clickCountLabel setHidden:TRUE];
        }
        [applyButton setEnabled:[currentPlugin points]==[tool clickCount]];
    }
}

- (IBAction)showEffects:(id)sender
{
    NSMenu *menu = [[SeaController seaPlugins] menu];

    [NSMenu popUpContextMenu:menu withEvent:[[NSApplication sharedApplication] currentEvent] forView:(NSButton *)sender];
}

- (void)installPlugin:(PluginClass*)plugin View:(NSView *)pluginView
{
    [pluginViewContainer setSubviews:[NSArray array]];

    if(pluginView) {
        [pluginViewContainer addSubview:pluginView];
    }
    [pluginViewContainer setNeedsLayout:TRUE];

    currentPlugin = plugin;

    [self updateClickCount:self];

    [instructionsArea setNeedsLayout:TRUE];
    [view setNeedsLayout:TRUE];
    [view setNeedsDisplay:TRUE];
}

-(PluginClass*)currentPlugin
{
    return currentPlugin;
}

@end

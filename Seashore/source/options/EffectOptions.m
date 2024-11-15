#import "EffectOptions.h"
#import "SeaController.h"
#import "SeaPlugins.h"
#import "SeaTools.h"
#import <Plugins/PluginClass.h>
#import "InfoPanel.h"
#import "EffectTool.h"
#import "SeaPrefs.h"

@implementation EffectOptions

- (id)init:(id)document
{
    self = [super init:document];

    NSControlSize size = [[SeaController seaPrefs] controlSize];

    [self setSubviews:[NSArray array]];
    [self setIdentifier:@"Effect Options"];

    self.lastFills = TRUE;

    AbstractTool *tool = [[document tools] getTool:kEffectTool];

    BorderView *borderView = [BorderView view];
    [borderView setIdentifier:@"Effect Options BorderView"];

    NSView *top = [VerticalView view];

    effectsButton = [SeaButton compactButton:@"Effects" withLabel:@"No effect selected." target:self action:@selector(showEffects:) size:size];

    instructionsArea = [VerticalView view];
    [instructionsArea setIdentifier:@"effects instructions area"];

    clickCountLabel = [Label labelWithSize:size];
    instructionsLabel = [Label labelWithSize:size];
    [instructionsLabel setIdentifier:@"effects instructions label"];
    [instructionsLabel makeMultiline];

    detectRectangleButton = [SeaButton compactButton:@"Detect Rectangle" target:tool action:@selector(detectRectangle:) size:size];

    [instructionsArea addSubview:clickCountLabel];
    [instructionsArea addSubview:instructionsLabel];
    [instructionsArea addSubview:detectRectangleButton];

    [top addSubview:effectsButton];
    [top addSubview:instructionsArea];

    pluginViewContainer = [BorderView view];
    [pluginViewContainer setIdentifier:@"effects options container"];

    NSView *bottom = [VerticalView view];

    resetButton = [SeaButton compactButton:@"Reset" target:tool action:@selector(reset:) size:size];
    [bottom addSubview:resetButton];
    applyButton = [SeaButton compactButton:@"Apply" target:tool action:@selector(apply:) size:size];
    [bottom addSubview:applyButton];
    reapplyButton = [SeaButton compactButton:@"Reapply Last Effect" target:tool action:@selector(reapply:) size:size];
    [bottom addSubview:reapplyButton];

    [borderView addSubview:top];
    [borderView addSubview:pluginViewContainer];
    [borderView addSubview:bottom];

    borderView.top = top;
    borderView.middle = pluginViewContainer;
    borderView.bottom = bottom;

    [self addSubview:borderView];

    [self updateClickCount:self];

    return self;
}

- (void)updateClickCount:(id)sender
{
    EffectTool* tool = (EffectTool*)[[document tools] getTool:kEffectTool];
    if(!currentPlugin) {
        [effectsButton setLabel:@"No effect selected."];
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
        [effectsButton setLabel:[currentPlugin name]];

        if([currentPlugin respondsToSelector:@selector(instruction)]) {
            [instructionsLabel setHidden:FALSE];
            [instructionsLabel setStringValue:[currentPlugin instruction]];
        } else {
            [instructionsLabel setHidden:TRUE];
        }

        if (@available(macOS 10.10, *)) {
            if([currentPlugin respondsToSelector:@selector(detectRectangle)]) {
                [detectRectangleButton setHidden:FALSE];
            } else {
                [detectRectangleButton setHidden:TRUE];
            }
        } else {
            [detectRectangleButton setHidden:TRUE];
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
    [self setNeedsLayout:TRUE];
    [self setNeedsDisplay:TRUE];
}

- (void)showEffects:(id)sender
{
    NSMenu *menu = [[SeaController seaPlugins] menu];

    [NSMenu popUpContextMenu:menu withEvent:[[NSApplication sharedApplication] currentEvent] forView:(NSButton *)sender];
}

- (void)installPlugin:(id<PluginClass>)plugin View:(NSView *)pluginView
{
    [pluginViewContainer setSubviews:[NSArray array]];

    if(pluginView) {
        [pluginViewContainer addSubview:pluginView];
    }
    [pluginViewContainer setNeedsLayout:TRUE];

    currentPlugin = plugin;

    [self updateClickCount:self];

    [instructionsArea setNeedsLayout:TRUE];

    [self layout];
    [self setNeedsDisplay:TRUE];
}

-(id<PluginClass>)currentPlugin
{
    return currentPlugin;
}

@end

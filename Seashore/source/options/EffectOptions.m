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
	int effectIndex=-1;
	parentWin = nil;
	NSArray *pointPlugins = [[SeaController seaPlugins] pointPlugins];
	if ([pointPlugins count]) {
		if ([gUserDefaults objectForKey:@"effectIndex"]) effectIndex = [gUserDefaults integerForKey:@"effectIndex"];
        if (effectIndex < 0 || effectIndex >= [pointPlugins count]) {
            [effectTableInstruction setStringValue:@""];
            [clickCountLabel setStringValue:@""];
            return;
        }
        
        PluginClass* plugin = [pointPlugins objectAtIndex:effectIndex];

		[effectTable noteNumberOfRowsChanged];
		[effectTable selectRowIndexes:[NSIndexSet indexSetWithIndex:effectIndex] byExtendingSelection:NO];
		[effectTable scrollRowToVisible:effectIndex];
		[effectTableInstruction setStringValue:[plugin instruction]];
		[clickCountLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"click count", @"Clicks remaining: %d"), [plugin points]]];
		[(InfoPanel *)panel setPanelStyle:kVerticalPanelStyle];
    }
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
{
	return [[[SeaController seaPlugins] pointPluginsNames] objectAtIndex:rowIndex];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[[SeaController seaPlugins] pointPluginsNames] count];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSArray *pointPlugins = [[SeaController seaPlugins] pointPlugins];
    PluginClass* plugin =[pointPlugins objectAtIndex:[effectTable selectedRow]];
	[effectTableInstruction setStringValue:[plugin instruction]];
    EffectTool* tool = (EffectTool*)[[document tools] getTool:kEffectTool];
    [tool selectEffect:plugin];
}

- (int)selectedRow
{
	return [effectTable selectedRow];
}

- (void)updateClickCount:(id)sender
{
    EffectTool* tool = (EffectTool*)[[document tools] getTool:kEffectTool];
    if(![tool plugin]) {
        [effectTableInstruction setStringValue:@""];
        [clickCountLabel setStringValue:@""];
    } else {
        [clickCountLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"click count", @"Clicks remaining: %d"),
                                         [[tool plugin] points] - [tool clickCount]]];
    }
}

- (IBAction)showEffects:(id)sender
{
	NSWindow *w = [document window];
	NSPoint p = [w convertBaseToScreen:[w mouseLocationOutsideOfEventStream]];
	[panel orderFrontToGoal:p onWindow: w];
	parentWin = w;
	
	[NSApp runModalForWindow:panel];
}

- (IBAction)closeEffects:(id)sender
{

	[NSApp stopModal];
	if (parentWin){
		[parentWin removeChildWindow:panel];
		parentWin = NULL;
	}
	[panel orderOut:self];	
}

@end

#import "EffectOptions.h"
#import "SeaController.h"
#import "SeaPlugins.h"
#import "SeaTools.h"
#import "PluginClass.h"
#import "InfoPanel.h"


@implementation EffectOptions
- (void)awakeFromNib
{
	int effectIndex;
	parentWin = nil;
	NSArray *pointPlugins = [[SeaController seaPlugins] pointPlugins];
	if ([pointPlugins count]) {
		if ([gUserDefaults objectForKey:@"effectIndex"]) effectIndex = [gUserDefaults integerForKey:@"effectIndex"];
		else effectIndex = 0;
		if (effectIndex < 0 || effectIndex >= [pointPlugins count]) effectIndex = 0;

		[effectTable noteNumberOfRowsChanged];
		[effectTable selectRowIndexes:[NSIndexSet indexSetWithIndex:effectIndex] byExtendingSelection:NO];
		[effectTable scrollRowToVisible:effectIndex];
		[effectTableInstruction setStringValue:[[pointPlugins objectAtIndex:effectIndex] instruction]];
		[clickCountLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"click count", @"Clicks remaining: %d"), [[pointPlugins objectAtIndex:effectIndex] points]]];
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
	[effectTableInstruction setStringValue:[[pointPlugins objectAtIndex:[effectTable selectedRow]] instruction]];
	[[[gCurrentDocument tools] getTool:kEffectTool] reset];
}

- (int)selectedRow
{
	return [effectTable selectedRow];
}

- (IBAction)updateClickCount:(id)sender
{
	[clickCountLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"click count", @"Clicks remaining: %d"), [[[[SeaController seaPlugins] pointPlugins] objectAtIndex:[effectTable selectedRow]] points] - [[[gCurrentDocument tools] getTool:kEffectTool] clickCount]]];
}

- (IBAction)showEffects:(id)sender
{
	NSWindow *w = [gCurrentDocument window];
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

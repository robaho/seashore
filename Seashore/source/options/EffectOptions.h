#import "Globals.h"
#import "AbstractOptions.h"

/*!
	@class		EffectOptions
	@abstract	Handles the options pane for the effects tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2007 Mark Pazolli
*/

@interface EffectOptions : AbstractOptions {
	// The table listing all effects
	IBOutlet id effectTable;
	
	// The instruction for those effects
	IBOutlet id effectTableInstruction;
	
	// The label showing the number of clicks remaining
	IBOutlet id clickCountLabel;
	
	// The panel of the effect options
	IBOutlet id panel;

	// The parent window for the effects options
	id parentWin;
}


/*!
	@method		tableView:objectValueForTableColumn:row:
	@discussion	Returns the name of a given row in the effect table.
	@param		tableView
				Ignored.
	@param		tableColumn
				Ignored.
	@param		rowIndex
				The row of the table.
	@result		An NSString representing the name of the effect.
*/
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex;

/*!
	@method		numberOfRowsInTableView:
	@discussion	Returns the number of rows in the effect table.
	@param		tableView
				Ignored.
	@result		An integer representing the number of rows.
*/
- (int)numberOfRowsInTableView:(NSTableView *)tableView;

/*!
	@method		tableViewSelectionDidChange:
	@discussion	Called when the effect table's selection changes.
	@param		notification
				Ignored.
*/
- (void)tableViewSelectionDidChange:(NSNotification *)notification;

/*!
	@method		selectedRow
	@discussion	The row currently selected by the options.
	@result		An integer.
*/
- (int)selectedRow;

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


/*!
	@method		closeEffects:
	@discussion	Closes the effects panel.
	@param		sender
				Ignored.
*/
- (IBAction)closeEffects:(id)sender;

@end

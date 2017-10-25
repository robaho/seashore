#import "Globals.h"

/*!
	@class		SeaAlignment
	@abstract	Aligns layers in the document.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaAlignment : NSObject
{

	// The document associated with this object
	IBOutlet id document;

}

/*!
	@method		alignLeft:
	@discussion	Aligns linked layers with the left of the active layer.
	@param		sender
				Ignored.
*/
- (IBAction)alignLeft:(id)sender;

/*!
	@method		alignRight:
	@discussion	Aligns linked layers with the right of the active layer.
	@param		sender
				Ignored.
*/
- (IBAction)alignRight:(id)sender;

/*!
	@method		alignHorizontalCenters:
	@discussion	Aligns linked layers with the horizontal centre of the active
				layer.
	@param		sender
				Ignored.
*/
- (IBAction)alignHorizontalCenters:(id)sender;

/*!
	@method		alignTop:
	@discussion	Aligns linked layers with the top of the active layer.
	@param		sender
				Ignored.
*/
- (IBAction)alignTop:(id)sender;

/*!
	@method		alignBottom:
	@discussion	Aligns linked layers with the bottom of the active layer.
	@param		sender
				Ignored.
*/
- (IBAction)alignBottom:(id)sender;

/*!
	@method		alignVerticalCenters:
	@discussion	Aligns linked layers with the vertical centre of the active
				layer.
	@param		sender
				Ignored.
*/
- (IBAction)alignVerticalCenters:(id)sender;

/*!
	@method		centerLayerHorziontally
	@discussion	Centres the active layer so its horizontal centre matches that
				of the document's.
	@param		sender
				Ignored.
*/
- (IBAction)centerLayerHorizontally:(id)sender;

/*!
	@method		centerLayerVertically
	@discussion	Centres the active layer so its vertical centre matches that of
				the document's.
	@param		sender
				Ignored.
*/
- (IBAction)centerLayerVertically:(id)sender;

/*!
	@method		undoOffsets:layer:
	@discussion	Undoes a change in offsets of a particular layer (this method
				should only ever be called by the undo manager following a call
				to centerLayerHorizontally, centerLayerVertically, etc.).
	@param		offsets
				The offsets to be restored.
	@param		index
				The index of the layer whose offsets to restore.
*/
- (void)undoOffsets:(IntPoint)offsets layer:(int)index;

@end

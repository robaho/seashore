#import "Seashore.h"
#import "SeaLayerUndo.h"

/*!
	@struct		RotationUndoRecord
	@discussion	Specifies how rotation of the document should be undone.
	@field		index
				The index of the layer to which the adjustment was applied.
	@field		rotation
				The amount of rotation.
	@field		undoIndex
				The index of the snapshot to be restored.
	@field		rect
				The original rectangle of the layer.
	@field		isRotated
				YES if the layer is in the rotated state, NO otherwise.
	@field		withTrim
				YES if the rotation is done with trimming, NO otherwise.
	@field		disableAlpha
				YES if the layer's alpha channel should be disabled after an
				undo, NO otherwise.
*/

@interface RotationUndoRecord : NSObject
{
    @public
    
    int index;
	float rotation;
	LayerSnapshot* snapshot;
	IntRect rect;
	BOOL isRotated;
	BOOL withTrim;
	BOOL disableAlpha;
}
@end

/*!
	@class		SeaRotation
	@abstract	Rotates layers in the document.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaRotation : NSObject
{

	// The document and sheet associated with this object
    __weak IBOutlet id document;
	IBOutlet id sheet;
	
	// A label specifying the layer being rotated
    IBOutlet id selectionLabel;
	
	// The rotation value (in degrees)
	IBOutlet id rotateValue;
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		run:
	@discussion	Presents the user with a sheet allowing him to configure the
				document's or layer's margins.
	@param		global
				YES if the document's margins should be changed, NO if the
				layer's margins should be changed.
*/
- (void)run;

/*!
	@method		apply:
	@discussion	Takes the settings from the configuration sheet and applies the
				necessary changes to the document.
	@param		sender
				Ignored.
*/
- (IBAction)apply:(id)sender;

/*!
	@method		cancel:
	@discussion	Closes the configuration sheet without applying the changes.
	@param		sender
				Ignored.
*/
- (IBAction)cancel:(id)sender;

/*!
	@method		rotate:
	@discussion	Rotates the active layer the given number of degrees handles
				updates and undos).
	@param		degrees
				The number of degrees to rotate.
	@param		trim
				YES if the layer should be trimmed of alpha after rotation, NO
				otherwise.
*/
- (void)rotate:(float)degrees withTrim:(BOOL)trim;

@end

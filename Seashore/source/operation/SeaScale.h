#import "Globals.h"

/*!
	@defined	kNumberOfScaleRecordsPerMalloc
	@discussion	Defines the number of scale undo records to allocate at a single
				time.
*/
#define kNumberOfScaleRecordsPerMalloc 10

/*!
	@struct		ScaleUndoRecord
	@discussion	Specifies how scaling of the document should be undone.
	@field		index
				The index of the layer to which scaling was applied or
				kAllLayers if scaling was applied to the document.
	@field		unscaledWidth
				The unscaled width of the document or layer.
	@field		unscaledHeight
				The unscaled height of the document or layer.
	@field		scaledWidth
				The scaled width of the document or layer.
	@field		scaledHeight
				The scaled height of the document or layer.
	@field		scaledXOrg
				The new X origin that the layer is scaled to.
	@field		scaledYOrg
				The new Y origin that the layer is scaled to.
	@field		interpolation
				The interpolation style to be used when scaling.
	@field		isScaled
				YES if the layer or document is currently scaled, NO otherwise.
	@field		indicies
				An array of indicies of the snapshots of the scaled layers (not
				the indicies of the layers themselves). If the index field is
				kAllLayers the array's length is as long as the number of layers
				in the document, otherwise it is one.
	@field		rects
				An array corresponding to the indicies of the rectangles
				specifying the layers' sizes and origins before they were
				scaled.
*/
typedef struct {
	int index;
	int unscaledWidth;
	int unscaledHeight;
	int scaledWidth;
	int scaledHeight;
	int scaledXOrg;
	int scaledYOrg;
	int interpolation;
	BOOL isMoving;
	BOOL isScaled;
	int *indicies;
	IntRect *rects;
} ScaleUndoRecord;

/*!
	@class		SeaScale
	@abstract	Changes the scale of a document or its layers according to user
				specifications.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaScale : NSObject {

	// The document and sheet associated with this object
    IBOutlet id document;
	IBOutlet id sheet;
	
	// The working index associated with this object
	int workingIndex;
	
	// The x and y scaling values
    IBOutlet id xScaleValue;
    IBOutlet id yScaleValue;
	
	// The height and width values
	IBOutlet id widthValue;
	IBOutlet id heightValue;
	
	// The various buttons for changing units
	IBOutlet id widthPopdown;
	IBOutlet id heightUnits;

	// The options
    IBOutlet id keepProportions;
	
	// The interpolation style to be used for scaling
	IBOutlet id interpolationPopup;
	
	// A list of various undo records required for undoing
	ScaleUndoRecord *undoRecords;
	int undoMax, undoCount; 
	
	// A label specifying the layer or document being scaled
    IBOutlet id selectionLabel;
	
	// The presets menu
	IBOutlet id presetsMenu;

	// The units for the panel
	int units;	
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		run:
	@discussion	Presents the user with a sheet allowing him to scale the
				document's or active layer's contents.
	@param		global
				YES if the document's contents should be scaled, NO if the
				layer's contents should be scaled.
*/
- (void)run:(BOOL)global;

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
	@method		scaleToWidth:height:interpolation:index:
	@discussion	Scales the given layer (or entire document) so that it matches
				the specified height and width. Interpolation (allowing for
				smoother scaling) is used as specified (handles updates and
				undos).
	@param		width
				The revised width of the document or layer.
	@param		height
				The revised height of the document or layer.
	@param		interpolation
				The interpolation style to be used (see GIMPCore).
	@param		index
				The index of the layer to be scaled (or kAllLayers to indicate
				the entire document).
*/
- (void)scaleToWidth:(int)width height:(int)height interpolation:(int)interpolation index:(int)index;

/*!
	@method		scaleToWidth:height:xorg:yorg:interpolation:index:
	@discussion	Scales the given layer (or entire document) so that it matches
				the specified height and width. Interpolation (allowing for
				smoother scaling) is used as specified (handles updates and
				undos).
	@param		width
				The revised width of the document or layer.
	@param		height
				The revised height of the document or layer.
	@param		xorg
				The x origin of the newly scaled layer.
	@param		yorg
				The y origin of the newly scaled layer.
	@param		interpolation
				The interpolation style to be used (see GIMPCore).
	@param		index
				The index of the layer to be scaled (or kAllLayers to indicate
				the entire document).
*/
- (void)scaleToWidth:(int)width height:(int)height xorg:(int)xorg yorg:(int)yorg interpolation:(int)interpolation index:(int)index;


/*!
	@method		undoScale:
	@discussion	Undoes a scaling operation (this method should only ever be
				called by the undo manager following a call to
				scaleToWidth:height:interpolation:index:).
	@param		undoIndex
				The index of the undo record corresponding to the scale
				operation to be undone.
*/
- (void)undoScale:(int)undoIndex;

/*!
	@method		togglePreserveSize:
	@discussion	Called after the user checks/unchecks the keep proportions
				checkbox to adjust the values of the dialog as is necessary.
	@param		sender
				Ignored.
*/
- (IBAction)toggleKeepProportions:(id)sender;

/*!
	@method		valueChanged:
	@discussion	Called after a value is changed in the configuration sheet in
				order to sychronize other values as is necessary.
	@param		sender
				Ignored.
*/
- (IBAction)valueChanged:(id)sender;

/*!
	@method		unitsChanged:
	@discussion	Changes the units in accordance with the given pop-down menu item.
	@param		sender
				The pop-down menu item.
*/
- (IBAction)unitsChanged:(id)sender;

/*!
	@method		changeToPreset:
	@discussion	Called to change to a preset when a menu item is selected from
				the presets menu.
	@param		sender
				Ignored.
*/
- (IBAction)changeToPreset:(id)sender;

@end

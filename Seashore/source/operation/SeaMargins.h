#import "Globals.h"

/*!
	@defined	kNumberOfScaleRecordsPerMalloc
	@discussion	Defines the number of scale undo records to allocate at a single
				time.
*/
#define kNumberOfMarginRecordsPerMalloc 10

/*!
	@struct		MarginUndoRecord
	@discussion	Specifies how scaling of the document should be undone.
	@field		index
				The index of the layer to which the adjustment was applied or
				kAllLayers if the adjustment was applied to the document.
	@field		left
				The change in the left margin, expressed in relative terms.
	@field		top
				The change in the top margin, expressed in relative terms.
	@field		right
				The change in the right margin, expressed in relative terms.
	@field		bottom
				The change in the bottom margin, expressed in relative terms.
	@field		isChanged
				YES if the adjustment is currently applied, NO otherwise.
	@field		indicies
				An array of indicies of snapshots of the layer's cut-off bits
				kept in the form LEFT-TOP-RIGHT-BOTTOM, any of which may be -1
				to indicate there were no cut-off bits. If the index field is
				kAllLayers this array is not defined.
*/
typedef struct {
	int index;
	int left;
	int top;
	int right;
	int bottom;
	BOOL isChanged;
	int indicies[4];
} MarginUndoRecord;

/*!
	@enum		k...ClipMode
	@constant	kNoClipMode
				If the new boundaries clip any layer's content leave it unchanged.
	@constant	kFullClipMode
				If the new boundaries clip the content of layers that are the same size as the image, remove that content.
	@constant	kAllClipMode
				If the new boundaries clip any layer's content, remove that content.
*/
enum {
	kNoClipMode,
	kFullClipMode,
	kAllClipMode
};

/*!
	@class		SeaMargins
	@abstract	Changes the margins of a document or its layers  according to
				user specifications.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaMargins : NSObject {
	
	// The document and sheet associated with this object
    IBOutlet id document;
    IBOutlet id sheet;
	IBOutlet id box;
	
	// The working index associated with this object
	int workingIndex;
	
	// The check box telling us whether to add margin's relative to content
	IBOutlet id contentRelative;
	
	// The matrix telling us the behavior of clipping
	IBOutlet id clippingMatrix;
	
	// The text boxes for how much the margins should be extended by
	IBOutlet id leftValue;
    IBOutlet id rightValue;
    IBOutlet id topValue;
    IBOutlet id bottomValue;
    IBOutlet id widthValue;
    IBOutlet id heightValue;
	
	// The text labels displaying the units
    IBOutlet id leftLabel;
    IBOutlet id rightLabel;
    IBOutlet id topPopdown;
    IBOutlet id bottomLabel;
    IBOutlet id widthLabel;
    IBOutlet id heightLabel;

	// Content margins
	int contentTop;
	int contentBottom;
	int contentLeft;
	int contentRight;

	// A list of various undo records required for undoing
	MarginUndoRecord *undoRecords;
	int undoMax, undoCount; 
	
	// A label specifying what margins will be changed
    IBOutlet id selectionLabel;
	
	// The presets menu
	IBOutlet id presetsMenu;
	
	// The units for the panel
	int units;
	
	// Sheet shown
	bool sheetShown;
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
	@discussion	Presents the user with a sheet allowing him to configure the
				document's or layer's margins.
	@param		global
				YES if the document's margins should be changed, NO if the
				layer's margins should be changed.
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
	@method		condeseLayer:
	@discussion	Condenses the layer so its boundaries only include its content.
	@param		sender
				Ignored.
*/
- (IBAction)condenseLayer:(id)sender;

/*!
	@method		condeseToSelection:
	@discussion	Condenses the layer so its boundaries match the current selection.
	@param		sender
				Ignored.
*/
- (IBAction)condenseToSelection:(id)sender;

/*!
	@method		expandLayer:
	@discussion	Expand the layer so its boundaries match the document.
	@param		sender
				Ignored.
*/
- (IBAction)expandLayer:(id)sender;


/*!
	@method		cropImage:
	@discussion	Cut the current document down to the current selection.
	@param		sender
				Ignored.
*/
- (IBAction)cropImage:(id)sender;

/*!
	@method		maskImage:
	@discussion	Move the image's boundaries in to the current selection.
	@param		sender
				Ignored.
*/
- (IBAction)maskImage:(id)sender;

/*!
	@method		setMarginsLeft:right:top:bottom:index:
	@discussion	Expands or reduces the margins of the given layer (or entire
				document) as specified. All measurements are taken to be
				relative with zero indicating no change, negative values
				indicating that margin should be moved inward and positive
				values indicating that the margin should be moved outward
				handles updates and undos).
	@param		left
				The adjustment to be made to the left margin (in pixels).
	@param		top
				The adjustment to be made to the top margin (in pixels).
	@param		right
				The adjustment to be made to the right margin (in pixels).
	@param		bottom
				The adjustment to be made to the bottom margin (in pixels).
	@param		index
				The index of the layer's margins to adjust (or kAllLayers to
				indicate the entire document).
*/
- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom index:(int)index;

/*!
	@method		undoMargins:
	@discussion	Undoes a set margins operation (this method should only ever be
				called by the undo manager following a call to
				setMarginsLeft:right:top:bottom:index:).
	@param		undoIndex
				The index of the undo record corresponding to the margins
				operation to be undone.
*/
- (void)undoMargins:(int)undoIndex;

/*!
	@method		marginsChanged:
	@discussion	Updates the width and height text boxes in the configuration
				sheet to give the user an idea of their changes will affect the
				document.
	@param		sender
				Ignored.
*/
- (IBAction)marginsChanged:(id)sender;

/*!
	@method		dimensionsChanged:
	@discussion	Updates the margin text boxes in the configuration
				sheet to give the user an idea of their changes will affect the
				document.
	@param		sender
				Ignored.
*/
- (IBAction)dimensionsChanged:(id)sender;

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

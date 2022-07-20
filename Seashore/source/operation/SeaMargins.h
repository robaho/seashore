#import "Seashore.h"

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
@class SeaDocument;

@interface SeaMargins : NSObject {
	
	// The document and sheet associated with this object
    __weak IBOutlet SeaDocument *document;
    IBOutlet id sheet;

	// The check box telling us whether to add margin's relative to content
	IBOutlet id contentRelative;
    
    // adjust layer positioning after size change
    IBOutlet id adjustLayerBoundaries;

	// The text boxes for how much the margins should be extended by
    IBOutlet id widthValue;
    IBOutlet id heightValue;
	
    IBOutlet id heightLabel;
    IBOutlet id widthPopdown;

    __weak IBOutlet NSTextField *leftLabel;
    __weak IBOutlet NSTextField *topLabel;
    __weak IBOutlet NSTextField *leftValue;
    __weak IBOutlet NSTextField *topValue;

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
	@method		show
	@discussion	show the canvas size dialog
*/
- (void)show;

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
	@method		marginsChanged:
	@discussion	Updates the width and height text boxes in the configuration
				sheet to give the user an idea of their changes will affect the
				document.
	@param		sender
				Ignored.
*/
- (IBAction)marginsChanged:(id)sender;

/*!
	@method		unitsChanged:
	@discussion	Changes the units in accordance with the given pop-down menu item.
	@param		sender
				The pop-down menu item.
*/
- (IBAction)unitsChanged:(id)sender;

@end

#import "Seashore.h"
#import "SeaController.h"

/*!
	@enum		k...Color
	@constant	kCyanColor
				The colour cyan.
	@constant	kMagentaColor
				The colour magenta.
	@constant	kYellowColor
				The colour yellow.
	@constant	kBlackColor
				The colour black.
	@constant	kMaxColor
				A marker indicating the last possible colour plus one.
*/
enum {
	kCyanColor,
	kMagentaColor,
	kYellowColor,
	kBlackColor,
    kGrayColor,
    kWhiteColor,
	kMaxColor
};


/*!
	@class		SeaPrefs
	@abstract	Handles a number of Seashore's preferences.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaPrefs : NSObject <SeaTerminate> {
	
	// The SeaController object
	IBOutlet id controller;
	
	// The preferences panel
	IBOutlet NSPanel *panel;
	
	// The general prefs view
	IBOutlet id generalPrefsView;
	
	// The new prefs view
	IBOutlet id newPrefsView;
	
	// The color prefs view
	IBOutlet id colorPrefsView;
	
	// The menu for selecting the selection colour
	IBOutlet id selectionColorMenu;

	// The menu for selecting the guide colour
	IBOutlet id guideColorMenu;
	
	// The matrix button for the checkrboard pattern
	IBOutlet id checkerboardMatrix;

	// The matrix button for the color of the layer bounds
	IBOutlet id layerBoundsMatrix;
		
	// The color well for the window back
	IBOutlet id windowBackWell;
	
    // the color well for the transparency color
    IBOutlet id transparencyColorWell;
    
    // The text field for the suggested width value for a new image
	IBOutlet id widthValue;
	
	// The text field for the suggested height value for a new image
	IBOutlet id heightValue;
	
	// The units label for the height
	IBOutlet id heightUnits;
	
	// The menu for the default units
	IBOutlet id newUnitsMenu;
	
	// The menu for the current units
	IBOutlet id docUnitsMenu;
	
	// The menu for the default resolution
	IBOutlet id resolutionMenu;
	
	// The menu for the mode
	IBOutlet id modeMenu;
	
	// The menu for resolution handling
	IBOutlet id resolutionHandlingMenu;
	
	// The checkbox for transparency
	IBOutlet id transparentBackgroundCheckbox;

	// A checkbox which when checked indicates smart interpolations should be used
	IBOutlet id smartInterpolationCheckbox;
	
	// A checkbox which when checked indicates a new document should be created at start-up
	IBOutlet id openUntitledCheckbox;

    // if checked, zoom document to fit at open
    IBOutlet id zoomToFitAtOpenCheckbox;
	
	// A checkbox which when checked indicates mouse coalescing should always be on
	IBOutlet id coalescingCheckbox;
	
	// A checkbox which when checks indicates the precise cursor should be used
	IBOutlet id preciseCursorCheckbox;

    IBOutlet id marchingAntsCheckbox;

    IBOutlet id layerBoundaryLinesCheckbox;

    IBOutlet id undoLevelsInput;

    IBOutlet id canvasShadowCheckbox;

    IBOutlet id rightButtonDrawsBGColorCheckbox;

    IBOutlet id useLargerFontsCheckbox;

    // Stores whether or not layer boundaries are visible
	BOOL layerBounds;

	// Stores whether or not guides are visible
	BOOL guides;

	// Stores whether or not rulers are visible
	BOOL rulers;
	
	// Stores whether or not to use the checkerboard
	BOOL useCheckerboard;

    int undoLevels;
	
	// The color of the back of the window
	NSColor *windowBackColor;

    // The color of to use for transparency
    NSColor *transparencyColor;

	// Whether smart interpolation should be used
	BOOL smartInterpolation;
	
	// Whether to create a new document at start-up
	BOOL openUntitled;
    
    // Whether to zoom to fit documents at open
    BOOL zoomToFitAtOpen;

	// Whether the precise cursor should be used
	BOOL preciseCursor;
	
	// The current selection colour
	int selectionColor;

	// Whether or not the layer bounds are white
	BOOL whiteLayerBounds;
	
	// The current guide colour
	int guideColor;

	// The standard width and height for a new document
	int width, height;
	
	// The standard resolution for a new document
	int resolution;
	
	// The standard units for a new document
	int newUnits;

	// The mode used for a new document
	int mode;
	
	// Whether images sholud have a transparent background
	BOOL transparentBackground;

    // whether marching ants is enabed
    BOOL marchingAnts;

    // if true user layer boundary lines, else shading
    BOOL layerBoundaryLines;

	// Whether mouse coalescing should always be on or not
	BOOL mouseCoalescing;

    // if true show the shadow on the drawing canvas
    BOOL showCanvasShadow;

    BOOL useLargerFonts;

	// The toolbar
	id toolbar;
	
	// The main screen resolution
	IntPoint mainScreenResolution;
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		awakeFromNib
	@discussion	Configures the interface.
*/
- (void)awakeFromNib;

/*!
	@method		terminate
	@discussion	Saves preferences to disk (this method is called before the
				application exits by the SeaController).
*/
- (void)terminate;

/*!
	@method		show:
	@discussion	Shows the preferences panel.
	@param		sender
				Ignored.
*/
- (IBAction)show:(id)sender;

/*!
	@method		generalPrefs
	@discussion	Shows the general preferences.
	@param		sender
				Ignored.
*/
- (void) generalPrefs;

/*!
	@method		newPrefs
	@discussion	Shows the new preferences.
	@param		sender
				Ignored.
*/
- (void) newPrefs;

/*!
	@method		colorPrefs
	@discussion	Shows the color preferences.
	@param		sender
				Ignored.
*/
- (void) colorPrefs;
 

/*!
	@method		setWidth:
	@discussion	Sets the default width.
	@param		sender
				Ignored.
*/
-(IBAction)setWidth:(id)sender;

/*!
	@method		setHeight:
	@discussion	Sets the default height.
	@param		sender
				 Ignored.
*/
-(IBAction)setHeight:(id)sender;

/*!
	@method		setNewUnits:
	@discussion	Sets the default units for new documents.
	@param		sender
				Ignored.
*/
-(IBAction)setNewUnits:(id)sender;


/*!
	@method		changeUnits:
	@discussion	Changes the current application units to the sender's tag.
	@param		sender
				The NSMenuItem whose tag has the units.
*/
-(IBAction)changeUnits:(id)sender;

/*!
	@method		setMode:
	@discussion	Sets the default mode.
	@param		sender
				Ignored.
*/
-(IBAction)setMode:(id)sender;

/*!
	@method		setTransparentBackground:
	@discussion	Sets the default background.
	@param		sender
				Ignored.
*/
-(IBAction)setTransparentBackground:(id)sender;

/*!
	@method		setSmartInterpolation:
	@discussion	Sets if smart interpolation should be used.
	@param		sender
				Ignored.
*/
-(IBAction)setSmartInterpolation:(id)sender;

/*!
	@method		setOpenUntitled:
	@discussion	Sets if a new document should be created at start-up.
	@param		sender
				Ignored.
*/
-(IBAction)setOpenUntitled:(id)sender;

/*!
    @method        setZoomToFitAtOpen:
    @discussion    Sets if a  document should be zoom to fit at open.
    @param        sender
                Ignored.
*/
-(IBAction)setZoomToFitAtOpen:(id)sender;

/*!
	@method		setMouseCoalescing:
	@discussion	Sets mouse coalescing.
	@param		sender
				Ignored.
*/
-(IBAction)setMouseCoalescing:(id)sender;

/*!
	@method		setPreciseCursor:
	@discussion	Sets if use a precise cursor.
	@param		sender
				Ignored.
*/
-(IBAction)setPreciseCursor:(id)sender;

/*!
	@method		windowWillClose:
	@discussion	Notification telling us the window will close. Needed because the text field does not automatically commit.
	@param		aNotification
				Ignored.
*/
- (void)windowWillClose:(NSNotification *)aNotification;

/*!
	@method		layerBounds
	@discussion	Returns whether or not the layer boundaries should be visible.
	@result		YES if the layer boundaries should be visible, NO otherwise.
*/
- (BOOL)layerBounds;

/*!
	@method		guides
	@discussion	Returns whether or not the layer guides should be visible.
	@result		YES if the layer guides should be visible, NO otherwise.
*/
- (BOOL)guides;

/*!
	@method		rulers
	@discussion	Returns whether or not the rulers should be visible.
	@result		YES if the rulers should be visible, NO otherwise.
*/
- (BOOL)rulers;

/*!
	@method		effectsPanel
	@discussion	Returns whether effects should appear as a panel or a sheet.
	@result		Returns YES if they should appear as a panel, NO otherwise.
*/
- (BOOL)effectsPanel;

/*!
	@method		smartInterpolation
	@discussion	Returns whether smart interpolation should be used.
	@result		Returns YES if smart interpolation should be used, NO otherwise.
*/
- (BOOL)smartInterpolation;

/*!
	@method		toggleBoundaries:
	@discussion	Toggles whether or not the layer boundaries are visible.
	@param		sender
				Ignored.
*/
- (IBAction)toggleBoundaries:(id)sender;

/*!
	@method		toggleGuides:
	@discussion	Toggles whether or not the layer guides are visible.
	@param		sender
				Ignored.
*/
- (IBAction)toggleGuides:(id)sender;

/*!
	@method		toggleRulers:
	@discussion	Toggles whether or not the rulers are visible.
	@param		sender
				Ignored.
*/
- (IBAction)toggleRulers:(id)sender;

/*!
	@method		checkerboardChanged:
	@discussion	Called when whether we're using the checkerboard background changes.
	@param		sender
				The NSMatrix sending the message.
*/
- (IBAction)checkerboardChanged:(id)sender;

/*!
	@method		useCheckerboard
	@discussion	Whether the transparency should be represented by a pattern.
	@result		True if a pattern; false would use the transparency color.
*/
- (BOOL)useCheckerboard;

/*!
    @method        transparecyColorChanged
    @discussion    Called when the transparency color changes.
    @param        sender
                The Color Well sending the message.
*/
- (IBAction)transparencyColorChanged:(id)sender;

/*!
    @method        transparencyColor
    @discussion    Returns the color of the transparecy when using non-checkboard
    @result        Returns a RGB NSColor object representing the color.
*/
- (NSColor *)transparencyColor;

/*!
	@method		defaultWindowBack:
	@discussion	Called to the window back color to the default color.
	@param		sender
				The Color Well sending the message.
*/
- (IBAction)defaultWindowBack:(id)sender;

/*!
	@method		windowBackChanged:
	@discussion	Called when the window back color changes.
	@param		sender
				The Color Well sending the message.
*/
- (IBAction)windowBackChanged:(id)sender;

/*!
	@method		windowBack
	@discussion	Returns the color of the window backing (outside the image).
	@result		Returns a RGB NSColor object representing the color.
*/
- (NSColor *)windowBack;

/*!
	@method		selectionColor
	@discussion	Returns the current selection colour.
	@param		alpha
				The alpha value to be associated with the colour.
	@result		Returns a RGB NSColor object representing the selection colour.
*/
- (NSColor *)selectionColor:(float)alpha;

/*!
	@method		selectionColorIndex
	@discussion	Returns the index of the current selection colour.
	@result		Returns an integer representing the selection colour.
*/
- (int)selectionColorIndex;

/*!
	@method		selectionColorChanged:
	@discussion	Called when the selection colour is changed.
	@param		sender
				The menu item which caused the change in selection colour. Its
				tag should equal the desired selection colour plus 280.
*/
- (IBAction)selectionColorChanged:(id)sender;

/*!
	@method		rotateSelectionColor:
	@discussion	Rotates the current selection colour.
	@param		sender
				Ignored.
*/
- (IBAction)rotateSelectionColor:(id)sender;

/*!
 @method        marchingAnts
 @result        Returns YES to use marching ants rather than transpaency
 */
- (BOOL)marchingAnts;

/*!
 @method        layerBoundaryLines
 @result        Returns YES to use boundary lines, otherwise shading
 */
- (BOOL)layerBoundaryLines;

- (BOOL)whiteLayerBounds;

- (IBAction)layerBoundsColorChanged:(id)sender;

/*!
 @method		guideColor
 @discussion	Returns the current guide colour.
 @param		alpha
				The alpha value to be associated with the colour.
 @result		Returns a RGB NSColor object representing the guide colour.
 */
- (NSColor *)guideColor:(float)alpha;

/*!
 @method		guideColorIndex
 @discussion	Returns the index of the current guide colour.
 @result		Returns an integer representing the guide colour.
 */
- (int)guideColorIndex;

/*!
 @method		guideColorChanged:
 @discussion	Called when the guide colour is changed.
 @param			sender
				The menu item which caused the change in guide colour. Its
				tag should equal the desired guide colour plus 290.
 */
- (IBAction)guideColorChanged:(id)sender;

/*!
	@method		mouseCoalescing
	@discussion	Returns whether mouse coalescing should always be on.
	@result		Returns YES if it should always be on, NO otherwise.
*/
- (BOOL)mouseCoalescing;

/*!
	@method		preciseCursor
	@discussion	Returns whether a precise cursor should be used.
	@result		Returns YES if the precise cursor should be used, NO otherwise.
*/
- (BOOL)preciseCursor;

/*!
	@method		size
	@discussion Returns the size for new images.
	@result		Returns an IntSize representing the size for new images.
*/
- (IntSize)size;

/*!
	@method		resolution
	@discussion Returns the menu item index of the resolution for new images.
	@result		Returns the menu item index of the resolution for new images.
*/
- (int)resolution;

/*!
	@method		mode
	@discussion Returns the menu item index of the mode for new images.
	@result		Returns the menu item index of the mode for new images.
*/
- (int)mode;

/*!
 @method        undoLevels
 @result        Returns the configured number of undo levels.
 */

- (int)undoLevels;

/*!
	@method		screenResolution
	@discussion	Returns the screen resolution to be used when calculating view size.
				Considers resolution handling preference.
	@param		Returns either (0, 0) (ignore image resolution), (72, 72) (assume 72 dpi)
				or the true screen resolution.
*/
- (IntPoint)screenResolution;

/*!
	@method		transparentBackground
	@discussion Returns whether the background should be transparent.
	@result		Returns YES for transparency.
*/
- (BOOL)transparentBackground;

/*!
	@method		newUnits
	@discussion Returns the units used for new images.
	@result		Returns an int that represents the units (see SeaDocument).
*/
- (int)newUnits;

/*!
	@method		openUntitled
	@discussion	Returns whether a new document should be created at
				start-up.
	@result		Returns YES if the a new document should be created, NO otherwise.
*/
- (BOOL)openUntitled;

/*!
    @method        zoomToFitAtOpen
    @discussion    Returns whether a document should zoom to fit at open
    @result        Returns YES if the a new document should be zoomed, NO otherwise.
*/
- (BOOL)zoomToFitAtOpen;

/*!
 @method        showCanvasShadow
 @discussion    Returns whether to show the shadow on the drawing canvas
 @result        Returns YES if to show the shadow, NO otherwise.
 */
- (BOOL)showCanvasShadow;

/*!
 @result        Returns YES if to use the bg color, else it erases.
 */
- (BOOL)rightButtonDrawsBGColor;

/*!
 @result        Returns YES if to use larger fonts where we can
 */
- (BOOL)useLargerFonts;
- (NSControlSize)controlSize;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled.
	@param		menuItem
				The menu item to be validated.
	@result		YES if the menu item should be enabled, NO otherwise.
*/
- (BOOL)validateMenuItem:(id)menuItem;

@end

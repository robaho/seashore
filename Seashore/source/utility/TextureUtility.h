#import "Seashore.h"
#import "AbstractPanelUtility.h"
#import "SeaTexture.h"
#import "ColorSelectView.h"

/*!
	@class		TextureUtility
	@abstract	Loads and manages all textures for the user.
	@discussion	This class is based upon the BrushUtility class.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/
@class SeaDocument;

@interface TextureUtility : AbstractPanelUtility {
	
	// The proxy object
	IBOutlet id seaProxy;
	
	// The texture grouping pop-up
    IBOutlet id textureGroupPopUp;
	
	// The label that presents the user with the texture name
	IBOutlet id textureNameLabel;
	
	// The view that displays the textures
    IBOutlet id view;
    	
	// The opacity selection items
	IBOutlet id opacitySlider;
	IBOutlet id opacityLabel;
	
	// An dictionary of all brushes known to Seashore
	NSDictionary<NSString*,SeaTexture*> *textures;
	
	// An array of all groups (an array of an array SeaTexture's) and group names (an array of NSString's)
	NSArray *groups;
	NSArray *groupNames;
	
	// The index of the currently active group
	int activeGroupIndex;
	
	// The index of the currently active texture
    SeaTexture *selected;

    // The document which is the focus of this utility
    __weak IBOutlet id document;

    __weak IBOutlet ColorSelectView *colorSelectView;
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		awakeFromNib
	@discussion	Configures the utility's interface.
*/
- (void)awakeFromNib;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

/*!
	@method		loadTextures:
	@discussion	Frees (if necessary) and then reloads all the textures from
				Seashore's textures directory.
	@param		update
				YES if the texture utility should be updated after reloading all
				the textures (typical case), NO otherwise.
*/
- (void)loadTextures:(BOOL)update;

/*!
	@method		addTextureFromPath:toGroup:
	@discussion	Loads a texture from the given path (handles updates).
	@param		path
				The path from which to load the texture.
*/
- (void)addTextureFromPath:(NSString *)path;

/*!
	@method		changeGroup:
	@discussion	Called when the texture group is changed.
	@param		sender
				Ignored.
*/
- (IBAction)changeGroup:(id)sender;

/*!
	@method		activeTexture
	@discussion	Returns the currently active texture.
	@result		Returns an instance of SeaTexture representing the currently
				active texture.
*/
- (id)activeTexture;

/*!
 @method        setActiveTexture
 @discussion    set the active texture, or NULL to disable textures
 */
- (void)setActiveTexture:(SeaTexture*)texture;

/*!
	@method		activeTextureIndex
	@discussion	Returns the index of the currently active texture.
	@result		Returns an integer representing the index of the currently
				active texture.
*/
- (int)activeTextureIndex;

/*!
	@method		setActiveTextureIndex:
	@discussion	Sets the active texture to that specified by the given index.
	@param		index
				The index of the texture to activate.
*/
- (void)setActiveTextureIndex:(int)index;

/*!
	@method		textures
	@discussion	Returns all the textures in the currently active group.
	@result		Returns an array with all the textures in the currently active
				group. 
*/
- (NSArray *)textures;

/*!
	@method		groupNames
	@discussion	Returns the textures' group names (excluding custom groups).
	@result		Returns an NSArray containing the textures' group names.
*/
- (NSArray *)groupNames;

@end

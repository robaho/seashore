#import "Globals.h"

/*!
	@class		SeaWindowContent
	@abstract	Provides a view manages all of the various subviews in the document window.
	@discussion	Ideally this is the only class that sets the frames, sizes and locations of
				each of the views in the main document view. The major caveat is that this 
				relies strongly on the window being configured properly in the IB NIB file.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

enum
{
	kOptionsBar,
	kSidebar,
	kPointInformation,
	kStatusBar,
	kWarningsBar,
    kRecentsBar
};


@class SeaDocument;
@class SeaOptionsView;
@class LayerControlView;
@class BannerView;

@interface SeaWindowContent : NSView {
	__weak IBOutlet SeaDocument *document;

	__weak IBOutlet SeaOptionsView* optionsBar;
	__weak IBOutlet NSView *nonOptionsBar;
	
	__weak IBOutlet NSView* sidebar;
	__weak IBOutlet NSScrollView* layers;
	__weak IBOutlet NSView* pointInformation;
	__weak IBOutlet LayerControlView* sidebarStatusbar;
	
	__weak IBOutlet NSView *nonSidebar;
	__weak IBOutlet BannerView *warningsBar;
	__weak IBOutlet NSView *mainDocumentView;
	__weak IBOutlet LayerControlView *statusBar;
    __weak IBOutlet NSView *recentsBar;
	
	// Dictionary for all properties
	NSDictionary *dict;
}

- (BOOL)visibilityForRegion:(int)region;
- (void)setVisibility:(BOOL)visibility forRegion:(int)region;
- (float)sizeForRegion:(int)region;
@end

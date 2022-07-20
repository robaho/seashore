#import "Seashore.h"

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
	kOptionsPanel,
	kLayersPanel,
	kPointInformation,
	kStatusBar,
    kRecentsHistogram
};


@class SeaDocument;

@interface SeaWindowContent : NSView {
	__weak IBOutlet SeaDocument *document;

	IBOutlet NSView *optionsBar;
	IBOutlet NSView *nonOptionsBar;
	
	IBOutlet NSView *sidebar;
	IBOutlet NSView *layers;
	IBOutlet NSView *pointInformation;

	IBOutlet NSView *nonSidebar;
	IBOutlet NSView *contentView;
	IBOutlet NSView *statusBar;
    IBOutlet NSView *recentsBar;
    IBOutlet NSView *rightSideBar;

    IBOutlet NSView *banner;
    IBOutlet NSView *goldStar;

	// Dictionary for all properties
	NSDictionary *dict;
}

- (BOOL)visibilityForRegion:(int)region;
- (void)setVisibility:(BOOL)visibility forRegion:(int)region;
- (void)hideBanner;
- (IBAction)showSupportSeashore:(id)sender;
@end

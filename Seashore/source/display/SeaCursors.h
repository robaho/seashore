#import "Seashore.h"

/*!
	@class		SeaCursors
	@abstract	Handles the cursors for the SeaView
	@discussion	This is a second class for organizational simplicity because it 
	contains a separate set of functionality from the view class.
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@class SeaDocument;
@class	SeaView;

@interface SeaCursors : NSObject {
	// Other Important Objects
	__weak SeaDocument *document;
	__weak SeaView *view;
	
    NSCursor *udCursor, *lrCursor, *urdlCursor, *uldrCursor;
	NSCursor* handleCursors[8];

    float currentScale;
}

@property (readonly) NSCursor *crosspointCursor;
@property (readonly) NSCursor *wandCursor;
@property (readonly) NSCursor *zoomCursor;
@property (readonly) NSCursor *pencilCursor;
@property (readonly) NSCursor *brushCursor;
@property (readonly) NSCursor *bucketCursor;
@property (readonly) NSCursor *eyedropCursor;
@property (readonly) NSCursor *moveCursor;
@property (readonly) NSCursor *eraserCursor;
@property (readonly) NSCursor *smudgeCursor;
@property (readonly) NSCursor *effectCursor;
@property (readonly) NSCursor *addCursor;
@property (readonly) NSCursor *subtractCursor;
@property (readonly) NSCursor *noopCursor;
@property (readonly) NSCursor *cloneCursor;
@property (readonly) NSCursor *closeCursor;
@property (readonly) NSCursor *resizeCursor;
@property (readonly) NSCursor *handCursor;
@property (readonly) NSCursor *grabCursor;

- (id)initWithDocument:(id)newDocument andView:(id)newView;
- (void)updateCursor:(NSEvent*)event;
- (IntRect)handleRect:(IntPoint)p;
/** returns the cursor that was set */
- (NSCursor*)handleRectCursors:(IntRect)rect point:(IntPoint)p cursor:(nullable NSCursor*)cursor ignoresMove:(BOOL)ignoresMove;
- (BOOL)isHandleCursor:(nullable NSCursor*)cursor;
- (BOOL)usePreciseCursor;

@end

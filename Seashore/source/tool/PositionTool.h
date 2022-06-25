#import "Seashore.h"
#import "PositionOptions.h"
#import "AbstractScaleTool.h"
#import "SeaLayer.h"

#define kNumberOfTransformRecordsPerMalloc 10


/*!
	@class		PositionTool
	@abstract   	The position tool allows layers to be repositioned, scaled and rotated within the
				document.
*/
@interface PositionTool : AbstractTool {

    // The point where the selection begun
    IntPoint initialPoint;

    int x,y;
    float scaleX,scaleY;
    // rotation is in radians
	float rotation;

    float tempScaleX, tempScaleY;
    float tempRotation;
    int tempX,tempY;

    int function;
    int handle;

    __weak IBOutlet NSButton *resetButton;
    __weak IBOutlet NSButton *applyButton;
    __weak IBOutlet NSButton *mergeButton;
    __weak IBOutlet NSButton *scaleToFitButton;

    PositionOptions *options;

    NSMutableArray *undoRecords;
    int undoCount;
}

- (void)adjustOffset:(IntPoint)offset;

- (NSAffineTransform*)transform:(SeaLayer*)layer;

- (IntRect)bounds;
- (IntRect)bounds:(SeaLayer*)layer;

- (IBAction)apply:(id)sender;

- (IBAction)reset:(id)sender;

- (IBAction)zoomToFitBoundary:(id)sender;

- (IBAction)scaleToFit:(id)sender;
@end

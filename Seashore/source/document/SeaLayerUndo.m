#import "SeaLayerUndo.h"
#import "SeaLayer.h"
#import "SeaContent.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "SeaHelpers.h"
#import <sys/stat.h>
#import <sys/mount.h>

@implementation LayerSnapshot
-(void)dealloc
{
    free(data);
}
@end

@implementation SeaLayerUndo

- (id)initWithDocument:(id)doc forLayer:(id)ilayer
{
	// Setup our local variables
	document = doc;
	layer = ilayer;

	return self;
}

- (LayerSnapshot*)takeSnapshot:(IntRect)rect automatic:(BOOL)automatic
{
	unsigned char *data, *temp_ptr;
	int i, width, sectionSize;

    long start = LOG_PERFORMANCE ? getCurrentMillis() : 0;
	
	// Check the rectangle is valid
	rect = IntConstrainRect(rect, IntMakeRect(0, 0, [layer width], [layer height]));
	if (rect.size.width <= 0) return NULL;
	if (rect.size.height <= 0) return NULL;
	
	// Set up variables
	sectionSize = rect.size.width * rect.size.height * SPP;
	data = [layer data];
	width = [layer width];

    LayerSnapshot *snapshot = [[LayerSnapshot alloc] init];

	// Allow the undo (if required)
	if (automatic) [[[document undoManager] prepareWithInvocationTarget:self] restoreSnapshot:snapshot automatic:YES];

    if(data!=NULL) {
        temp_ptr = (unsigned char*)malloc(sectionSize);
        snapshot->data = temp_ptr;
        snapshot->rect = rect;

        CHECK_MALLOC(temp_ptr);
        SAVE_BITMAP(temp_ptr,data,rect,width);
    }

    if(LOG_PERFORMANCE)
        NSLog(@"snapshot finished %ld",getCurrentMillis()-start);

	return snapshot;
}

- (void)restoreSnapshot:(LayerSnapshot*)snapshot automatic:(BOOL)automatic
{
	IntRect rect;
	unsigned char *data, *temp_ptr, *o_temp_ptr = NULL, *odata = NULL;
	int i, width, lindex;
	
	// Allow the undo/redo
	if (automatic) [[[document undoManager] prepareWithInvocationTarget:self] restoreSnapshot:snapshot automatic:YES];
	
	// Set-up variables
	data = [layer data];
	width = [layer width];
	lindex = [layer index];
    
    temp_ptr = snapshot->data;
    rect = snapshot->rect;
    
    int datasize =rect.size.width * rect.size.height * SPP;
    
    if (automatic) {
        if(data!=NULL) {
            o_temp_ptr = odata = malloc(datasize);
            SAVE_BITMAP(o_temp_ptr,data,rect,width);
        }
	}

    if(data!=NULL) {
        RESTORE_BITMAP(data,temp_ptr,rect,width);
    }
		
	// Call for an update
	if (automatic) [[document helpers] layerSnapshotRestored:lindex rect:rect];

	// Move saved image data into the record
	if (automatic && odata!=NULL) {
		memcpy(snapshot->data, odata, datasize);
		free(odata);
	}
}

@end

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
	int i, width, sectionSize, spp;

    long start = LOG_PERFORMANCE ? getCurrentMillis() : 0;
	
	// Check the rectangle is valid
	rect = IntConstrainRect(rect, IntMakeRect(0, 0, [layer width], [layer height]));
	if (rect.size.width <= 0) return NULL;
	if (rect.size.height <= 0) return NULL;
	
	// Set up variables
	spp = [[document contents] spp];
	sectionSize = rect.size.width * rect.size.height * spp;
	data = [layer data];
	width = [layer width];

    LayerSnapshot *snapshot = [[LayerSnapshot alloc] init];

	// Allow the undo (if required)
	if (automatic) [[[document undoManager] prepareWithInvocationTarget:self] restoreSnapshot:snapshot automatic:YES];
	
    temp_ptr = (unsigned char*)malloc(sectionSize);
    snapshot->data = temp_ptr;
    snapshot->rect = rect;

    CHECK_MALLOC(temp_ptr);
	for (i = 0; i < rect.size.height; i++) {
		memcpy(temp_ptr, data + ((rect.origin.y + i) * width + rect.origin.x) * spp, rect.size.width * spp);
		temp_ptr += rect.size.width * spp;
	}

    if(LOG_PERFORMANCE)
        NSLog(@"snapshot finished %ld",getCurrentMillis()-start);

	return snapshot;
}

- (void)restoreSnapshot:(LayerSnapshot*)snapshot automatic:(BOOL)automatic
{
	IntRect rect;
	unsigned char *data, *temp_ptr, *o_temp_ptr = NULL, *odata = NULL;
	int i, width, spp, lindex;
	
	// Allow the undo/redo
	if (automatic) [[[document undoManager] prepareWithInvocationTarget:self] restoreSnapshot:snapshot automatic:YES];
	
	// Set-up variables
	data = [layer data];
	width = [layer width];
	spp = [[document contents] spp];
	lindex = [layer index];
    
    temp_ptr = snapshot->data;
    rect = snapshot->rect;
    
    int datasize =rect.size.width * rect.size.height * spp;
    
    if (automatic) {
        o_temp_ptr = odata = malloc(datasize);
    }
    
	// Save the current image data
	if (automatic) {
		for (i = 0; i < rect.size.height; i++) {
			memcpy(o_temp_ptr, data + ((rect.origin.y + i) * width + rect.origin.x) * spp, rect.size.width * spp);
			o_temp_ptr += rect.size.width * spp;
		}
	}
	
	// Replace the image data with that of the record
	for (i = 0; i < rect.size.height; i++) {
		memcpy(data + ((rect.origin.y + i) * width + rect.origin.x) * spp, temp_ptr, rect.size.width * spp);
		temp_ptr += rect.size.width * spp;
	}
		
	// Call for an update
	if (automatic) [[document helpers] layerSnapshotRestored:lindex rect:rect];

	// Move saved image data into the record
	if (automatic) {
		memcpy(snapshot->data, odata, datasize);
		free(odata);
	}
}

@end

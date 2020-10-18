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

@implementation SeaLayerUndo

- (id)initWithDocument:(id)doc forLayer:(id)ilayer
{
	// Setup our local variables
	document = doc;
	layer = ilayer;
	
	// Allocate the initial records size
	records = malloc(kNumberOfUndoRecordsPerMalloc * sizeof(UndoRecord));
	records_max_len = kNumberOfUndoRecordsPerMalloc;
	records_len = 0;
	
	return self;
}

- (void)dealloc
{
    int i;
	// Free the undo cache
	for (i = 0; i < records_len; i++) {
        if(records[i].data != NULL){
            free(records[i].data);
            records[i].data=NULL;
        }
	}
	
	// Free the record of the memory cache
	if (records) free(records);
}

- (int)takeSnapshot:(IntRect)rect automatic:(BOOL)automatic
{
	unsigned char *data, *temp_ptr;
	int i, width, sectionSize, spp;
	
	// Check the rectangle is valid
	rect = IntConstrainRect(rect, IntMakeRect(0, 0, [(SeaLayer *)layer width], [(SeaLayer *)layer height]));
	if (rect.size.width <= 0) return -1;
	if (rect.size.height <= 0) return -1;
	
	// Set up variables
	spp = [(SeaContent *)[document contents] spp];
	sectionSize = rect.size.width * rect.size.height * spp;
	data = [(SeaLayer *)layer data];
	width = [(SeaLayer *)layer width];
	
	// Allow the undo (if required)
	if (automatic) [[[document undoManager] prepareWithInvocationTarget:self] restoreSnapshot:records_len automatic:YES];
	
	// Allocate more space for the records if need be
	if (records_len >= records_max_len) {
		records_max_len += kNumberOfUndoRecordsPerMalloc;
		records = realloc(records, records_max_len * sizeof(UndoRecord));
	}
	
	// Record the details
    records[records_len].rect = rect;
    temp_ptr = records[records_len].data = (unsigned char*)malloc(sectionSize);
    CHECK_MALLOC(temp_ptr);
	for (i = 0; i < rect.size.height; i++) {
		memcpy(temp_ptr, data + ((rect.origin.y + i) * width + rect.origin.x) * spp, rect.size.width * spp);
		temp_ptr += rect.size.width * spp;
	}
    
	// Increment records_len
	records_len++;
	
	return records_len - 1;
}

- (void)restoreSnapshot:(int)index automatic:(BOOL)automatic
{
	IntRect rect;
	unsigned char *data, *temp_ptr, *o_temp_ptr = NULL, *odata = NULL;
	int i, width, spp, lindex;
	
	// Check the index is valid
	#ifdef DEBUG
	if (index < 0) NSLog(@"Invalid index recieved by restoreSnapshot:");
	if (index >= records_len) NSLog(@"Invalid index recieved by restoreSnapshot:");
	#endif
	if (index < 0) return;
	
	// Allow the undo/redo
	if (automatic) [[[document undoManager] prepareWithInvocationTarget:self] restoreSnapshot:index automatic:YES];
	
    UndoRecord record = records[index];
	
	// Set-up variables
	data = [(SeaLayer *)layer data];
	width = [(SeaLayer *)layer width];
	spp = [(SeaContent *)[document contents] spp];
	lindex = [(SeaLayer *)layer index];
    temp_ptr = record.data;
    rect = record.rect;
    
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
		memcpy(record.data, odata, datasize);
		free(odata);
	}
}

@end

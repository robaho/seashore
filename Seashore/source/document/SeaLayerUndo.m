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

extern int tempFileCount;
extern BOOL userWarnedOnDiskSpace;

@implementation SeaLayerUndo

- (id)initWithDocument:(id)doc forLayer:(id)ilayer
{
	// Setup our local variables
	document = doc;
	layer = ilayer;
	memoryCacheSize = (unsigned long)[[SeaController seaPrefs] memoryCacheSize];
	
	// Allocate the initial records size
	records = malloc(kNumberOfUndoRecordsPerMalloc * sizeof(UndoRecord));
	records_max_len = kNumberOfUndoRecordsPerMalloc;
	records_len = 0;
	
	// Allocate the memory cache
	memory_cache_len = memoryCacheSize * 1024;
	memory_cache = malloc(memory_cache_len);
	memory_cache_pos = 0;
	
	return self;
}

- (void)dealloc
{
	struct stat sb;
	char *tempFileName;
	int i, j;
	short oldFileNumber;
	
	// Free the disk cache
	for (i = 0; i < records_len; i++) {
		if (records[i].fileNumber >= 0) {
			tempFileName = (char *)[[NSString stringWithFormat:@"/tmp/seaundo-%d", records[i].fileNumber] fileSystemRepresentation];
			if (stat(tempFileName, &sb) == 0) {
				oldFileNumber = records[i].fileNumber;
				for (j = 0; j < records_len; j++) {
					if (records[j].fileNumber == oldFileNumber) {
						records[j].fileNumber = -2;
					}
				}
				unlink(tempFileName);
			}
		}
	}
	
	// Free the memory cache
	if (memory_cache) free(memory_cache);
	
	// Free the record of the memory cache
	if (records) free(records);
	
	// Call the super
	[super dealloc];
}

- (BOOL)checkDiskSpace
{
	struct statfs fs;
	struct stat sb;
	char *tempFileName;
	int i, j;
	unsigned long spaceLeft;
	short oldFileNumber;
	BOOL badstate;
	
	// Determine the disk space remaining
	statfs("/tmp", &fs);
	spaceLeft = ((unsigned long long)fs.f_bfree * (unsigned long long)fs.f_bsize) / ((unsigned long long)1024);
	badstate = spaceLeft < (unsigned long)(50 * 1024) || spaceLeft < memoryCacheSize * (unsigned long)12;
	if (badstate) {
	
		// If it is too low display a warning
		if (userWarnedOnDiskSpace == NO) {
			NSRunAlertPanel(LOCALSTR(@"disk space title", @"Disk space low"), LOCALSTR(@"disk space body", @"Your system disk now has limited space, you should quit Seashore and free more space."), LOCALSTR(@"ok", @"OK"), NULL, NULL);
			userWarnedOnDiskSpace = YES;
		}
		
		// And remove as many of *our* files as necessary to restore 50 MB of system disk space
		for (i = 0; i < records_len && badstate; i++) {
			if (records[i].fileNumber >= 0) {
				oldFileNumber = records[i].fileNumber;
				tempFileName = (char *)[[NSString stringWithFormat:@"/tmp/seaundo-%d", oldFileNumber] fileSystemRepresentation];
				if (stat(tempFileName, &sb) == 0) {
					for (j = 0; j < records_len; j++) {
						if (records[j].fileNumber == oldFileNumber) {
							records[j].fileNumber = -2;
						}
					}
					spaceLeft += sb.st_size;
					unlink(tempFileName);
				}
			}
			badstate = spaceLeft < (unsigned long)(50 * 1024) || spaceLeft < memoryCacheSize * (unsigned long)12;
		}
		
	}
	
	// In the very worst cases recommend that undo data not be written to disk
	if (spaceLeft < (unsigned long)(16 * 1024) || spaceLeft < memoryCacheSize * (unsigned long)3)
		return NO;
		
	return YES;
}

- (void)writeMemoryCache
{
	FILE *file;
	int fileNo, i;

	// Check we actually have something to write to disk
	if (memory_cache_pos > 0) {

		// Check we have sufficient disk space
		if ([self checkDiskSpace]) {
			
			// Set the file number and increment the tempFileCount
			fileNo = tempFileCount;
			tempFileCount++;
			
			// Open a file for writing the memory cache
			file = fopen([[NSString stringWithFormat:@"/tmp/seaundo-%d", fileNo] fileSystemRepresentation], "w");
			
			// Write the memory cache
			if (file != NULL) fwrite(memory_cache, sizeof(unsigned char), memory_cache_pos, file);
			if (file == NULL) fileNo = -2;
			
			// Go through each record checking it if it has been written to disk
			for (i = 0; i < records_len; i++) {
				if (records[i].fileNumber == -1) {
					records[i].fileNumber = fileNo;
					records[i].data = NULL;
				}
			}
			
			// Close the file
			fclose(file);
			
			// Free the memory cache
			free(memory_cache);
			memory_cache = NULL;
			memory_cache_len = 0;
			memory_cache_pos = 0;
			
			// Write debugging notices
			#ifdef DEBUG
			NSLog(@"Memory converted to the disk cache.");
			#endif
		}
		
	}
	else {
	
		// Free the memory cache
		free(memory_cache);
		memory_cache = NULL;
		memory_cache_len = 0;
		memory_cache_pos = 0;
	
	}		
}

- (BOOL)loadMemoryCacheWithIndex:(int)index
{
	FILE *file;
	struct stat sb;
	int i, fileNo, spp;
	const char *fileName;
	int *int_ptr;

	// Set up variables
	fileNo = records[index].fileNumber;
	spp = [(SeaContent *)[document contents] spp];

	// If the record is already in the memory cache succeed
	if (fileNo == -1) return YES;
	
	// If the record has an undefined file attached to it fail
	if (fileNo == -2) return NO;

	// Otherwise write the current memory cache to disk
	[self writeMemoryCache];
	
	// Open the file associated with this record
	fileName = [[NSString stringWithFormat:@"/tmp/seaundo-%d", fileNo] fileSystemRepresentation];
	file = fopen(fileName, "r");
	if (file == NULL) return NO;
	
	// Read the whole file asssociated with this record into the memory cache
	fstat(fileno(file), &sb);
	memory_cache_len = sb.st_size;
	memory_cache = malloc(memory_cache_len);
	fread(memory_cache, sizeof(char), memory_cache_len, file);
	memory_cache_pos = 0;
	
	// Go through each record looking for a matching file number and signal that record is now in memory
	for (i = 0; i < records_len; i++) {
		if (records[i].fileNumber == fileNo) {
		
			// In case of such a match load the record's data
			records[i].data = (unsigned char *)memory_cache + memory_cache_pos;
			records[i].fileNumber = -1;
			int_ptr = (int *)&memory_cache[memory_cache_pos];
			if (int_ptr[2] == -1)
				memory_cache_pos += 3 * sizeof(int) + spp;
			else
				memory_cache_pos += 4 * sizeof(int) + int_ptr[2] * int_ptr[3] * spp;
			
		}
	}
	
	// Close the file
	fclose(file);
	
	// Delete the file (we have its contents in memory now)
	unlink(fileName);
	
	// Write debugging notices
	#ifdef DEBUG
	NSLog(@"Disk cache converted to memory.");
	#endif
	
	return YES;
}

- (int)takeSnapshot:(IntRect)rect automatic:(BOOL)automatic
{
	unsigned char *data, *temp_ptr;
	int i, width, rectSize, sectionSize, spp;
	int *int_ptr;
	
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
	
	// Check that the memory cache has space to handle this snapshot (otherwise write it to disk and start afresh)
	if (memory_cache_pos + sectionSize + 4 * sizeof(int) > memory_cache_len) {
		[self writeMemoryCache];
		memory_cache_len = MAX(sectionSize + 4 * sizeof(int), memoryCacheSize * 1024);
		memory_cache = malloc(memory_cache_len);
		memory_cache_pos = 0;
	}
	
	// Record the details
	temp_ptr = (unsigned char*)memory_cache + memory_cache_pos;
	int_ptr = (int *)temp_ptr;
	int_ptr[0] = rect.origin.x;
	int_ptr[1] = rect.origin.y;
	if (rect.size.width == 1 && rect.size.height == 1) {
		int_ptr[2] = -1;
		rectSize = 3 * sizeof(int);
		temp_ptr += rectSize;
	}
	else {
		int_ptr[2] = rect.size.width;
		int_ptr[3] = rect.size.height;
		rectSize = 4 * sizeof(int);
		temp_ptr += rectSize;
	}
	for (i = 0; i < rect.size.height; i++) {
		memcpy(temp_ptr, data + ((rect.origin.y + i) * width + rect.origin.x) * spp, rect.size.width * spp);
		temp_ptr += rect.size.width * spp;
	}
	records[records_len].fileNumber = -1;
	records[records_len].data = (unsigned char*)memory_cache + memory_cache_pos;
	
	// Increase the memory cache position
	memory_cache_pos += sectionSize + rectSize;
	
	// Increment records_len
	records_len++;
	
	// Check that the memory cache has space to handle this snapshot (otherwise write it to disk and start afresh)
	if (memory_cache_pos >= memory_cache_len) {
		[self writeMemoryCache];
		memory_cache_len = memoryCacheSize * 1024;
		memory_cache = malloc(memory_cache_len);
		memory_cache_pos = 0;
	}
	
	return records_len - 1;
}

- (void)restoreSnapshot:(int)index automatic:(BOOL)automatic
{
	IntRect rect;
	unsigned char *data, *temp_ptr, *o_temp_ptr = NULL, *odata = NULL;
	int i, width, recordDataSize = 0, spp, lindex;
	int *int_ptr, *o_int_ptr = NULL;
	
	// Check the index is valid
	#ifdef DEBUG
	if (index < 0) NSLog(@"Invalid index recieved by restoreSnapshot:");
	if (index >= records_len) NSLog(@"Invalid index recieved by restoreSnapshot:");
	#endif
	if (index < 0) return;
	
	// Allow the undo/redo
	if (automatic) [[[document undoManager] prepareWithInvocationTarget:self] restoreSnapshot:index automatic:YES];
	
	// Load the record we require into memory
	if (![self loadMemoryCacheWithIndex:index]) return;
	
	// Set-up variables
	data = [(SeaLayer *)layer data];
	width = [(SeaLayer *)layer width];
	spp = [(SeaContent *)[document contents] spp];
	lindex = [(SeaLayer *)layer index];
	temp_ptr = records[index].data;
	int_ptr = (int *)temp_ptr;
	
	// Set-up variables for old data
	if (automatic) {
		if (int_ptr[2] == -1)
			recordDataSize = 3 * sizeof(int) + spp;
		else
			recordDataSize = 4 * sizeof(int) + int_ptr[2] * int_ptr[3] * spp;
		odata = malloc(recordDataSize);
		o_temp_ptr = odata;
		o_int_ptr = (int *)o_temp_ptr;
	}
	
	// Load rectangle information
	rect.origin.x = int_ptr[0];
	rect.origin.y = int_ptr[1];
	if (int_ptr[2] != -1) {
		rect.size.width = int_ptr[2];
		rect.size.height = int_ptr[3];
		temp_ptr += 4 * sizeof(int);
	}
	else {
		rect.size.width = 1;
		rect.size.height = 1;
		temp_ptr += 3 * sizeof(int);
	}
	
	// Set rectangle information in old data
	if (automatic) {
		o_int_ptr[0] = rect.origin.x;
		o_int_ptr[1] = rect.origin.y;
		if (rect.size.width == 1 && rect.size.height == 1) {
			o_int_ptr[2] = -1;
			o_temp_ptr += 3 * sizeof(int);
		}
		else {
			o_int_ptr[2] = rect.size.width;
			o_int_ptr[3] = rect.size.height;
			o_temp_ptr += 4 * sizeof(int);
		}
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
		memcpy(records[index].data, odata, recordDataSize);
		free(odata);
	}
}

@end

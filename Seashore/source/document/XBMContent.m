#import "XBMContent.h"
#import "XBMLayer.h"
#import "SeaController.h"
#import "SeaDocumentController.h"
#import "SeaWarning.h"

@implementation XBMContent

inline static int parse_value(char *input, char *value)
{
	char *temp;
	int i = 0;
	
	if (strstr(input, "#define")) {
		temp = strstr(input, value);
		if (temp) {
			temp += strlen(value);
			do { 
				temp++;
				if (*temp == 0x00) return -1;
			} while (*temp < '0' || *temp > '9');
			do {
				input[i] = *temp;
				i++; temp++;
			} while (*temp >= '0' && *temp <= '9');
			input[i] = 0x00;
			return atoi(input);
		}
	}
	
	return -1;
}

+ (BOOL)typeIsEditable:(NSString *)aType
{
	return [[SeaDocumentController sharedDocumentController] type: aType isContainedInDocType:@"X11 bitmap"];
}


- (id)initWithDocument:(id)doc contentsOfFile:(NSString *)path
{
	FILE *file;
	char buffer[4096], temp;
	SharedXBMInfo info;
	id layer;
	
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return NULL;
	
	// Parse the width and height of the image
	file = fopen([path fileSystemRepresentation], "rb");
	info.width = info.height = -1;
	do {
		fgets(buffer, 4096, file);
		if (info.width == -1) info.width = parse_value(buffer, "width");
		if (info.height == -1) info.height = parse_value(buffer, "height");
	} while ((info.width == -1 || info.height == -1) && !(ferror(file) || feof(file)));
	
	// Fail if something went wrong
	if (info.width == -1 || info.height == -1) {
		fclose(file);
		[self autorelease];
		return NULL;
	}
	
	// Set the width and height and type of the image
	width = info.width;
	height = info.height;
	type = XCF_GRAY_IMAGE;

	// Goto the thingy
	do {
		temp = fgetc(file);
	} while ((temp != '{') && !(ferror(file) || feof(file)));
	
	// Fail if something went wrong
	if (ferror(file) || feof(file)) {
		fclose(file);
		[self autorelease];
		return NULL;
	}

	// Create the layer
	fseek(file, -1, SEEK_CUR);
	layer = [[XBMLayer alloc] initWithFile:file offset:ftell(file) document:doc sharedInfo:&info];
	if (layer == NULL) {
		fclose(file);
		[self autorelease];
		return NULL;
	}
	layers = [NSArray arrayWithObject:layer];
	[layers retain];

	// Close the file
	fclose(file);
	
	return self;
}

@end

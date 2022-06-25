#import "BrushExporter.h"
#import "SeaController.h"
#import "BrushUtility.h"
#import "SeaDocument.h"

enum {
	kExistingCategoryButton,
	kNewCategoryButton
};

@implementation BrushExporter

@synthesize spacing;

- (void)awakeFromNib
{
	[self selectButton:kExistingCategoryButton];
    [self setSpacing:100];
    [super awakeFromNib];
}

- (IBAction)exportAsBrush:(id)sender
{
	[NSApp beginSheet:sheet modalForWindow:[document window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)apply:(id)sender
{
	NSArray *groupNames = [[document brushUtility] groupNames];
    
    if ([existingCategoryRadio state] == NSOnState && [categoryTable selectedRow]==-1) {
        return;
    }

	// End the sheet
	[NSApp stopModal];
	[NSApp endSheet:sheet];
	[sheet orderOut:self];
    
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Seashore/brushes/"];

	// Determine the path
	if ([existingCategoryRadio state] == NSOnState) {
		path = [path stringByAppendingPathComponent:[groupNames objectAtIndex:[categoryTable selectedRow]]];
	}
	else {
		path = [path stringByAppendingPathComponent:[categoryTextbox stringValue]];
	}
    [gFileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:0 error:NULL];
	path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.gbr", [nameTextbox stringValue]]];
    
    SeaDocument *doc = document;
    
	// Write document
    [self writeToFile:path spacing:self.spacing data:[[doc whiteboard] data] spp:[[doc contents] spp] width:[[doc contents] width] height:[[doc contents] height]];
    
	// Refresh textures
	[[document brushUtility] addBrushFromPath:path];
}

- (IBAction)cancel:(id)sender
{
	[NSApp stopModal];
	[NSApp endSheet:sheet];
	[sheet orderOut:self];
}

- (IBAction)existingCategoryClick:(id)sender
{
	[self selectButton:kExistingCategoryButton];
}

- (IBAction)newCategoryClick:(id)sender
{
	[self selectButton:kNewCategoryButton];
}

- (void)selectButton:(int)button
{
	switch (button) {
		case kExistingCategoryButton:
			[existingCategoryRadio setState:NSOnState];
			[newCategoryRadio setState:NSOffState];
			[categoryTable setEnabled:YES];
			[categoryTextbox setEnabled:NO];
		break;
		case kNewCategoryButton:
			[existingCategoryRadio setState:NSOffState];
			[newCategoryRadio setState:NSOnState];
			[categoryTable setEnabled:NO];
			[categoryTextbox setEnabled:YES];
		break;
	}
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row
{
	NSArray *groupNames = [[document brushUtility] groupNames];

	return [groupNames objectAtIndex:row];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	NSArray *groupNames = [[document brushUtility] groupNames];

	return [groupNames count];
}

typedef struct {
    unsigned int   header_size;  /*  header_size = sizeof (BrushHeader) + brush name  */
    unsigned int   version;      /*  brush file version #  */
    unsigned int   width;        /*  width of brush  */
    unsigned int   height;       /*  height of brush  */
    unsigned int   bytes;        /*  depth of brush in bytes */
    unsigned int   magic_number; /*  GIMP brush magic number  */
    unsigned int   spacing;      /*  brush spacing  */
} BrushHeader;

#define GBRUSH_MAGIC    (('G' << 24) + ('I' << 16) + ('M' << 8) + ('P' << 0))
#define window [[[self windowControllers] objectAtIndex:0] window]
#define int_mult(a,b,t)  ((t) = (a) * (b) + 0x80, ((((t) >> 8) + (t)) >> 8))

- (BOOL)writeToFile:(NSString *)path spacing:(int)spacing data:(unsigned char*)data spp:(int)spp width:(int)width height:(int)height
{
    FILE *file;
    BrushHeader header;
    unsigned char* noalpha=NULL;
    
    if(spp==2){
        noalpha = malloc(width*height);
        stripAlphaToWhite(2,noalpha,data,width*height);
        // need to invert to black color space
        for(int i=0;i<width*height;i++) {
            noalpha[i] = noalpha[i] ^ 0xFF;
        }
        data = noalpha;
        spp=1;
    }
    
    NSString* name = [[path lastPathComponent] stringByDeletingPathExtension];
    
    // Open the brush file
    file = fopen([path fileSystemRepresentation], "wb");
    if (file == NULL)
    return NO;
    
    // Set-up the header
    header.header_size = strlen([name UTF8String]) + 1 + sizeof(header);
    header.version = 2;
    header.width = width;
    header.height = height;
    header.bytes = spp;
    header.magic_number = GBRUSH_MAGIC;
    header.spacing = spacing;
    
    // Convert brush header to proper endianess
    header.header_size = htonl(header.header_size);
    header.version = htonl(header.version);
    header.width = htonl(header.width);
    header.height = htonl(header.height);
    header.bytes = htonl(header.bytes);
    header.magic_number = htonl(header.magic_number);
    header.spacing = htonl(header.spacing);
    
    // Write the header
    fwrite(&header, sizeof(BrushHeader), 1, file);
    
    // Write down brush name
    fwrite([name UTF8String], sizeof(char), strlen([name UTF8String]), file);
    fputc(0x00, file);
    
    // And then write down the meat of the brush
    fwrite(data, sizeof(char), width * height * spp, file);
    
    // Close the brush file
    fclose(file);
    
    if(noalpha){
        free(noalpha);
    }
    
    return YES;
}


@end
